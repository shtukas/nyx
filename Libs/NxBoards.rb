
class NxBoards

    # NxBoards::items()
    def self.items()
        ObjectStore2::objects("NxBoards")
    end

    # NxBoards::getItemOfNull(uuid)
    def self.getItemOfNull(uuid)
        ObjectStore2::getOrNull("NxBoards", uuid)
    end

    # --------------------------------------------
    # Makers

    # NxBoards::interactivelyIssueNewOrNull()
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
        ObjectStore2::commit("NxBoards", item)
        item
    end

    # ----------------------------------------------------------------
    # Data

    # NxBoards::toString(item)
    def self.toString(item)
        "(board) #{item["description"]}"
    end

    # NxBoards::toStringForListing(item)
    def self.toStringForListing(item)
        rt = BankUtils::recoveredAverageHoursPerDay(item["uuid"])
        "(board) (rt: #{("%5.2f" % rt)}) #{item["description"]}"
    end

    # NxBoards::interactivelySelectOneOrNull()
    def self.interactivelySelectOneOrNull()
        items = NxBoards::items()
        LucilleCore::selectEntityFromListOfEntitiesOrNull("board", items, lambda{|item| NxBoards::toString(item) })
    end

    # NxBoards::interactivelySelectOne()
    def self.interactivelySelectOne()
        loop {
            item = NxBoards::interactivelySelectOneOrNull()
            return item if item
        }
    end

    # NxBoards::listingItems()
    def self.listingItems()
        NxBoards::items()
    end

    # NxBoards::boardItems(boarduuid)
    def self.boardItems(boarduuid)
        NxTodos::items().select{|item| item["boarduuid"] == boarduuid }
    end

    # NxBoards::rtExpectation()
    def self.rtExpectation()
        0.40
    end

    # NxBoards::differentialForListingPosition(item)
    def self.differentialForListingPosition(item)
        rt = BankUtils::recoveredAverageHoursPerDay(item["uuid"])
        return 0 if rt < NxBoards::rtExpectation()
        -(rt - NxBoards::rtExpectation())
    end

    # ---------------------------------------------------------
    # Ops

    # NxBoards::listingProgram(board)
    def self.listingProgram(board)

        loop {

            system("clear")
            store = ItemStore.new()
            vspaceleft = CommonUtils::screenHeight() - 3

            linecount = Listing::printDesktop()
            vspaceleft = vspaceleft - linecount

            linecount = Listing::printTops(store)
            vspaceleft = vspaceleft - linecount

            Listing::printProcesses(store)

            puts ""
            puts "BOARD FOCUS: #{NxBoards::toString(board)}#{NxBalls::nxballSuffixStatusIfRelevant(board).green}"
            puts ""
            vspaceleft = vspaceleft - 3

            items = NxBoards::boardItems(board["uuid"]).sort{|i1, i2| i1["boardposition"] <=> i2["boardposition"] }

            lockedItems, items = items.partition{|item| Locks::isLocked(item["uuid"]) }
            lockedItems.each{|item|
                vspaceleft = vspaceleft - CommonUtils::verticalSize(PolyFunctions::toStringForListing(item))
            }

            lockedItems
                .each{|item|
                    store.register(item, false)
                    line = Listing::itemToListingLine(store, item, nil)
                    puts line
                    vspaceleft = vspaceleft - CommonUtils::verticalSize(line)
                }

            items
                .each{|item|
                    store.register(item, !Skips::isSkipped(item["uuid"]))
                    line = Listing::itemToListingLine(store, item, nil)
                    puts line
                    vspaceleft = vspaceleft - CommonUtils::verticalSize(line)
                    break if vspaceleft <= 0
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

    # NxBoards::decideNewBoardPosition(board)
    def self.decideNewBoardPosition(board)
        NxBoards::boardItems(board["uuid"])
            .sort{|i1, i2| i1["boardposition"] <=> i2["boardposition"] }
            .first(40)
            .each{|item| puts NxTodos::toString(item) }
        LucilleCore::askQuestionAnswerAsString("position: ").to_f
    end

    # NxBoards::getBoardNextPosition(board)
    def self.getBoardNextPosition(board)
        (NxBoards::boardItems(board["uuid"]).map{|item| item["boardposition"] } + [0]).max + 1
    end
end
