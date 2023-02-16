
class NxBoards

    # NxBoards::items()
    def self.items()
        ObjectStore2::objects("NxBoards")
    end

    # NxBoards::getItemOfNull(uuid)
    def self.getItemOfNull(uuid)
        ObjectStore2::getOrNull("NxBoards", uuid)
    end

    # NxBoards::commit(item)
    def self.commit(item)
        ObjectStore2::commit("NxBoards", item)
    end

    # --------------------------------------------
    # Makers

    # NxBoards::interactivelyIssueNewOrNull()
    def self.interactivelyIssueNewOrNull()
        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return nil if description == ""
        uuid = SecureRandom.uuid
        hours = LucilleCore::askQuestionAnswerAsString("hours: ").to_f
        item = {
            "uuid"          => uuid,
            "mikuType"      => "NxBoard",
            "unixtime"      => Time.new.to_i,
            "datetime"      => Time.new.utc.iso8601,
            "description"   => description,
            "hours"         => hours,
            "lastResetTime" => 0,
            "capsule"       => SecureRandom.hex
        }
        NxBoards::commit(item)
        item
    end

    # ----------------------------------------------------------------
    # Data

    # NxBoards::toString(item)
    def self.toString(item)
        dayLoadInHours = item["hours"].to_f/5
        dayDoneInHours = BankCore::getValueAtDate(item["uuid"], CommonUtils::today()).to_f/3600
        completionRatio = NxBoards::completionRatio(item)
        str0 = "(day: #{("%5.2f" % dayDoneInHours).to_s.green} of #{"%5.2f" % dayLoadInHours}, cr: #{("%4.2f" % completionRatio).to_s.green})"

        loadDoneInHours = BankCore::getValue(item["capsule"]).to_f/3600 + item["hours"]
        loadLeftInhours = item["hours"] - loadDoneInHours
        str1 = "(done #{("%5.2f" % loadDoneInHours).to_s.green} out of #{item["hours"]})"

        timePassedInDays = (Time.new.to_i - item["lastResetTime"]).to_f/86400
        timeLeftInDays = 7 - timePassedInDays
        str2 = 
            if timeLeftInDays > 0 then
                "(#{timeLeftInDays.round(2)} days before reset)"
            else
                "(late by #{-timeLeftInDays.round(2)})"
            end

        "(board) #{item["description"].ljust(8)} #{str0} #{str1} #{str2}"
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

    # NxBoards::interactivelyDecideNewBoardPosition(board)
    def self.interactivelyDecideNewBoardPosition(board)
        NxBoards::boardItemsOrdered(board["uuid"])
            .first(20)
            .each{|item| puts NxBoardItems::toString(item) }
        LucilleCore::askQuestionAnswerAsString("position: ").to_f
    end

    # NxBoards::rtTarget(item)
    def self.rtTarget(item)
        item["hours"].to_f/5 # Hopefully 5 days
    end

    # NxBoards::completionRatio(item)
    def self.completionRatio(item)
        BankUtils::recoveredAverageHoursPerDay(item["uuid"]).to_f/NxBoards::rtTarget(item)
    end

    # NxBoards::listingItems()
    def self.listingItems()
        NxBoards::items()
            .map {|board|
                {
                    "board" => board,
                    "cr"    => NxBoards::completionRatio(board)
                }
            }
            .select{|packet| packet["cr"] < 1 }
            .sort{|p1, p2| p1["cr"] <=> p2["cr"] }
            .map {|packet| packet["board"] }
    end

    # NxBoards::bottomItems()
    def self.bottomItems()
        NxBoards::items()
            .map {|board|
                {
                    "board" => board,
                    "cr"    => NxBoards::completionRatio(board)
                }
            }
            .sort{|p1, p2| p1["cr"] <=> p2["cr"] }
            .map {|packet| packet["board"] }
    end

    # NxBoards::boardItems(boarduuid)
    def self.boardItems(boarduuid)
        NxBoardItems::items().select{|item| item["boarduuid"] == boarduuid }
    end

    # NxBoards::boardItemsOrdered(boarduuid)
    def self.boardItemsOrdered(boarduuid)
        NxBoards::boardItems(boarduuid)
            .sort{|i1, i2| i1["boardposition"] <=> i2["boardposition"] }
    end

    # NxBoards::boardsOrdered()
    def self.boardsOrdered()
        NxBoards::items().sort{|i1, i2| NxBoards::completionRatio(i1) <=> NxBoards::completionRatio(i2) }
    end

    # ---------------------------------------------------------
    # Ops

    # NxBoards::timeManagement()
    def self.timeManagement()
        NxBoards::items().each{|item|
            if BankCore::getValue(item["capsule"]) >= 0 and (Time.new.to_i - item["lastResetTime"]) >= 86400*7 then
                puts "resetting board's capsule time commitment: #{item["description"]}"
                BankCore::put(item["capsule"], -item["hours"]*3600)
                item["lastResetTime"] = Time.new.to_i
                NxBoards::commit(item)
            end
        }
    end

    # NxBoards::listingDisplay(store, spacecontrol, boarduuid) 
    def self.listingDisplay(store, spacecontrol, boarduuid)
        board = NxBoards::getItemOfNull(boarduuid)

        if board.nil? then
            puts "NxBoards::listingDisplay(boarduuid), board not found"
            exit
        end

        tops = NxTops::itemsInOrder().select{|item|
            (lambda{
                bx = Lookups::getValueOrNull("NonBoardItemToBoardMapping", item["uuid"])
                return false if bx.nil?
                return false if bx["uuid"] != boarduuid
                true
            }).call()
        }

        ondates = NxOndates::listingItems(board)

        waves = Waves::items().select{|item|
            (lambda{
                bx = Lookups::getValueOrNull("NonBoardItemToBoardMapping", item["uuid"])
                return false if bx.nil?
                return false if bx["uuid"] != boarduuid
                true
            }).call()
        }

        items = NxBoards::boardItemsOrdered(board["uuid"])

        store.register(board, (tops+waves+items).empty?)
        line = "(#{store.prefixString()}) #{NxBoards::toString(board)}#{NxBalls::nxballSuffixStatusIfRelevant(board)}"
        if NxBalls::itemIsRunning(board) or NxBalls::itemIsPaused(board) then
            line = line.green
        end
        spacecontrol.putsline line
        NxOpens::itemsForBoard(boarduuid).each{|item|
            store.register(item, false)
            spacecontrol.putsline "(#{store.prefixString()}) (open) #{item["description"]}".yellow
        }

        lockedItems, items = items.partition{|item| Locks::isLocked(item["uuid"]) }

        lockedItems
            .each{|item|
                store.register(item, false)
                spacecontrol.putsline (Listing::itemToListingLine(store, item))
            }

        tops.each{|item|
            store.register(item, true)
            spacecontrol.putsline (Listing::itemToListingLine(store, item))
        }

        ondates.each{|item|
            store.register(item, true)
            spacecontrol.putsline (Listing::itemToListingLine(store, item))
        }

        waves.each{|item|
            store.register(item, true)
            spacecontrol.putsline (Listing::itemToListingLine(store, item))
        }

        items.take(6)
            .each{|item|
                store.register(item, true)
                spacecontrol.putsline (Listing::itemToListingLine(store, item))
            }
    end

    # NxBoards::bottomDisplay(store, spacecontrol, boarduuid) 
    def self.bottomDisplay(store, spacecontrol, boarduuid)
        board = NxBoards::getItemOfNull(boarduuid)
        padding = "      "
        if board.nil? then
            puts "NxBoards::bottomDisplay(boarduuid), board not found"
            exit
        end
        store.register(board, false)
        line = "(#{store.prefixString()}) #{NxBoards::toString(board)}#{DoNotShowUntil::suffixString(board)}#{NxBalls::nxballSuffixStatusIfRelevant(board)}"
        if NxBalls::itemIsRunning(board) or NxBalls::itemIsPaused(board) then
            line = line.green
        end
        spacecontrol.putsline line

        NxOpens::itemsForBoard(boarduuid)
            .each{|item|
                store.register(item, false)
                spacecontrol.putsline "#{padding}(#{store.prefixString()}) (open) #{item["description"]} #{NonBoardItemToBoardMapping::toStringSuffix(item)}".yellow
            }

        items = NxBoards::boardItemsOrdered(board["uuid"])

        lockedItems, items = items.partition{|item| Locks::isLocked(item["uuid"]) }

        lockedItems
            .each{|item|
                store.register(item, false)
                spacecontrol.putsline (padding + Listing::itemToListingLine(store, item))
            }

        NxTops::itemsInOrder().each{|item|
            bx = Lookups::getValueOrNull("NonBoardItemToBoardMapping", item["uuid"])
            next if bx.nil?
            next if bx["uuid"] != boarduuid
            store.register(item, false)
            spacecontrol.putsline (padding + Listing::itemToListingLine(store, item))
        }

        Waves::items().each{|item|
            bx = Lookups::getValueOrNull("NonBoardItemToBoardMapping", item["uuid"])
            next if bx.nil?
            next if bx["uuid"] != boarduuid
            store.register(item, false)
            spacecontrol.putsline (padding + Listing::itemToListingLine(store, item))
        }

        items.take(6)
            .each{|item|
                store.register(item, false)
                spacecontrol.putsline (padding + Listing::itemToListingLine(store, item))
            }
    end
end
