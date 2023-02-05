
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

    # NxBoards::toStringForListing(item)
    def self.toStringForListing(item)
        hours = BankCore::getValue(item["uuid"]).to_f/3600
        "#{item["description"]} (hours: #{("%5.2f" % hours)})"
    end

    # NxBoards::listingItems()
    def self.listingItems()
        NxBoards::items()
    end

    # NxBoards::boardItems(boarduuid)
    def self.boardItems(boarduuid)
        NxTodos::items().select{|item| item["boarduuid"] == boarduuid }
    end

    # ---------------------------------------------------------
    # Ops

    # NxBoards::listingProgram(board)
    def self.listingProgram(board)

        loop {

            itemToLine = lambda {|store, item|
                line = "(#{store.prefixString()}) #{PolyFunctions::toStringForListing(item)}#{ItemToTimeCommitmentMapping::toStringSuffix(item)}#{NxBalls::nxballSuffixStatusIfRelevant(item)}"
                if Locks::isLocked(item["uuid"]) then
                    line = "#{line} [lock: #{Locks::locknameOrNull(item["uuid"])}]".yellow
                end
                if NxBalls::itemIsRunning(item) or NxBalls::itemIsPaused(item) then
                    line = line.green
                end
                line
            }

            system("clear")
            store = ItemStore.new()
            vspaceleft = CommonUtils::screenHeight() - 4

            puts ""
            puts "----------------------------------------------------"
            puts "BOARD FOCUS: #{NxBoards::toString(board)}#{NxBalls::nxballSuffixStatusIfRelevant(board).green}"
            puts "----------------------------------------------------"
            puts ""
            vspaceleft = vspaceleft - 5

            dskt = Desktop::contentsOrNull()
            if dskt and dskt.size > 0 then
                puts "Desktop:".green
                vspaceleft = vspaceleft - 2
                puts dskt
                vspaceleft = vspaceleft - CommonUtils::verticalSize(dskt)
            end

            tops = NxTops::items()
            if tops.size > 0 then
                tops.each{|item|
                    store.register(item, true)
                    line = "(#{store.prefixString()})         #{NxTops::toString(item)}#{NxBalls::nxballSuffixStatusIfRelevant(item)}"
                    if line. include?("running") then
                        line = line.green
                    end
                    puts line
                    vspaceleft = vspaceleft - 1
                }
            end
            timecommitments = NxTimeCommitments::items()
            vspaceleft = vspaceleft - timecommitments.size

            items = NxBoards::boardItems(board["uuid"])

            lockedItems, items = items.partition{|item| Locks::isLocked(item["uuid"]) }
            lockedItems.each{|item|
                vspaceleft = vspaceleft - CommonUtils::verticalSize(PolyFunctions::toStringForListing(item))
            }

            items
                .each{|item|
                    store.register(item, !Skips::isSkipped(item["uuid"]))
                    line = itemToLine.call(store, item)
                    puts line
                    vspaceleft = vspaceleft - CommonUtils::verticalSize(line)
                    break if vspaceleft <= 0
                }

            lockedItems
                .each{|item|
                    store.register(item, false)
                    line = itemToLine.call(store, item)
                    puts line
                    vspaceleft = vspaceleft - CommonUtils::verticalSize(line)
                    break if vspaceleft <= 0
                }

            puts ""
            input = LucilleCore::askQuestionAnswerAsString("> ")
            return if input == "exit"
            next if input == ""

            Listing::listingCommandInterpreter(input, store)
        }
    end
end
