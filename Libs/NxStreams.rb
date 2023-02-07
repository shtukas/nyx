
class NxStreams

    # NxStreams::items()
    def self.items()
        ObjectStore2::objects("NxStreams")
    end

    # NxStreams::getItemOfNull(uuid)
    def self.getItemOfNull(uuid)
        ObjectStore2::getOrNull("NxStreams", uuid)
    end

    # NxStreams::commit(item)
    def self.commit(item)
        ObjectStore2::commit("NxStreams", item)
    end

    # --------------------------------------------
    # Makers

    # NxStreams::interactivelyIssueNewOrNull()
    def self.interactivelyIssueNewOrNull()
        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return nil if description == ""
        uuid = SecureRandom.uuid
        item = {
            "uuid"        => uuid,
            "mikuType"    => "NxBoard",
            "unixtime"    => Time.new.to_i,
            "datetime"    => Time.new.utc.iso8601,
            "description" => description,
        }
        FileSystemCheck::fsck_MikuTypedItem(item, true)
        NxStreams::commit(item)
        item
    end

    # ----------------------------------------------------------------
    # Data

    # NxStreams::toString(item)
    def self.toString(item)
        "(board) #{item["description"]}"
    end

    # NxStreams::toStringForListing(item)
    def self.toStringForListing(item)
        rt = BankUtils::recoveredAverageHoursPerDay(item["uuid"])
        "(board) (rt: #{("%5.2f" % rt)}) #{item["description"]}"
    end

    # NxStreams::interactivelySelectOneOrNull()
    def self.interactivelySelectOneOrNull()
        items = NxStreams::items()
        LucilleCore::selectEntityFromListOfEntitiesOrNull("board", items, lambda{|item| NxStreams::toString(item) })
    end

    # NxStreams::interactivelySelectOne()
    def self.interactivelySelectOne()
        loop {
            item = NxStreams::interactivelySelectOneOrNull()
            return item if item
        }
    end

    # NxStreams::decideNewBoardPosition(board)
    def self.decideNewBoardPosition(board)
        NxStreams::boardItemsOrdered(board["uuid"])
            .first(20)
            .each{|item| puts NxTodos::toString(item) }
        input = LucilleCore::askQuestionAnswerAsString("position (empty for next): ")
        return NxStreams::getBoardNextPosition(board) if input == ""
        input.to_f
    end

    # NxStreams::getBoardNextPosition(board)
    def self.getBoardNextPosition(board)
        (NxStreams::boardItems(board["uuid"]).map{|item| item["boardposition"] } + [0]).max + 1
    end

    # NxStreams::interactivelyDecideBoardPositionPair()
    def self.interactivelyDecideBoardPositionPair()
        board = NxStreams::interactivelySelectOne()
        position = NxStreams::decideNewBoardPosition(board)
        [board, position]
    end

    # NxStreams::listingItems()
    def self.listingItems()
        NxStreams::items()
            .map{|board|
                todo = NxStreams::boardItemsOrderedX3(board["uuid"]).first
                if todo then
                    {
                        "uuid"        => "#{board["uuid"]}-#{todo["uuid"]}",
                        "mikuType"    => "NxBoardFirstItem",
                        "description" => "(first item) #{board["description"].yellow} | #{NxTodos::toStringForFirstItem(todo)}",
                        "board"       => board,
                        "todo"        => todo
                    }
                else
                    nil
                end
            }
            .compact
    end

    # NxStreams::boardItems(boarduuid)
    def self.boardItems(boarduuid)
        NxTodos::items().select{|item| item["boarduuid"] == boarduuid }
    end

    # NxStreams::boardItemsOrdered(boarduuid)
    def self.boardItemsOrdered(boarduuid)
        NxStreams::boardItems(boarduuid)
            .sort{|i1, i2| i1["boardposition"] <=> i2["boardposition"] }
    end

    # NxStreams::boardItemsOrderedX3(boarduuid)
    def self.boardItemsOrderedX3(boarduuid)
        items = NxStreams::boardItemsOrdered(boarduuid)
        is1 = items.take(3)
        is2 = items.drop(3)
        is1 = is1.sort{|i1, i2| BankCore::getValue(i1["uuid"]) <=> BankCore::getValue(i2["uuid"]) }
        is1 + is2
    end

    # NxStreams::rtExpectation()
    def self.rtExpectation()
        0.40
    end

    # NxStreams::differentialForListingPosition(item)
    def self.differentialForListingPosition(item)
        rt = BankUtils::recoveredAverageHoursPerDay(item["uuid"])
        return 0 if rt < NxStreams::rtExpectation()
        -(rt - NxStreams::rtExpectation())
    end

    # ---------------------------------------------------------
    # Ops

    # NxStreams::listingProgram(board)
    def self.listingProgram(board)

        loop {

            system("clear")
            store = ItemStore.new()
            vspaceleft = CommonUtils::screenHeight() - 3

            puts ""
            vspaceleft = vspaceleft - 1

            linecount = Listing::printDesktop()
            vspaceleft = vspaceleft - linecount

            linecount = Listing::printTops(store)
            vspaceleft = vspaceleft - linecount

            puts ""
            puts "BOARD FOCUS: #{NxStreams::toString(board)}#{NxBalls::nxballSuffixStatusIfRelevant(board).green}"
            puts ""
            vspaceleft = vspaceleft - 3

            items = NxStreams::boardItemsOrdered(board["uuid"])
                        .map{|item|
                            # We do this because some items are stored with their 
                            # computed listing positions and come back with them. 
                            # This should not be a problem, except for board displays 
                            # where e do not use them.
                            item["listing:position"] = nil
                            item
                        }

            lockedItems, items = items.partition{|item| Locks::isLocked(item["uuid"]) }
            lockedItems.each{|item|
                vspaceleft = vspaceleft - CommonUtils::verticalSize(PolyFunctions::toStringForListing(item))
            }

            linecount = Listing::itemsToVerticalSpace(lockedItems)
            vspaceleft = vspaceleft - linecount

            items
                .each{|item|
                    store.register(item, !Skips::isSkipped(item["uuid"]))
                    line = Listing::itemToListingLine(store, item, "(done: #{"%5.2f" % (BankCore::getValue(item["uuid"]).to_f/3600)} hours)")
                    puts line
                    vspaceleft = vspaceleft - CommonUtils::verticalSize(line)
                    break if vspaceleft <= 0
                }

            lockedItems
                .each{|item|
                    store.register(item, false)
                    line = Listing::itemToListingLine(store, item, "(done: #{"%5.2f" % (BankCore::getValue(item["uuid"]).to_f/3600)} hours)")
                    puts line
                }

            puts ""
            input = LucilleCore::askQuestionAnswerAsString("> ")
            return if input == "exit"
            next if input == ""

            # line
            # We have a special line command that fast inject a line on the board

            if input.start_with?("line:") then
                line = input[6, input.length].strip
                line = line.reverse
                position = line.index("@")
                ordinal = line[0, position].strip.reverse.to_f
                description = line[position+1, line.size].strip.reverse
                puts "line:"
                puts "    description: #{description}"
                puts "    ordinal    : #{ordinal}"
                NxTodos::issueBoardLine(description, board["uuid"], ordinal)
                next
            end

            Listing::listingCommandInterpreter(input, store, board)
        }
    end

    # NxStreams::dataMaintenance()
    def self.dataMaintenance()
        NxStreams::items()
            .each{|board|
                if board["hasTimeCommitmentCompanion"].nil? then
                    answer = LucilleCore::askQuestionAnswerAsBoolean("board '#{board["description"]}' has time commitment companion ? ")
                    board["hasTimeCommitmentCompanion"] = (answer ? "true" : "false")
                    NxStreams::commit(board)
                end
            }
    end
end
