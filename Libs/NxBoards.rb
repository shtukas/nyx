
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
        engine = NxEngine::interactivelyMakeNewEngine()
        item = {
            "uuid"        => uuid,
            "mikuType"    => "NxBoard",
            "unixtime"    => Time.new.to_i,
            "datetime"    => Time.new.utc.iso8601,
            "description" => description,
            "engine"      => engine
        }
        NxBoards::commit(item)
        item
    end

    # NxBoards::issueLine(line, boarduuid, boardposition)
    def self.issueLine(line, boarduuid, boardposition)
        description = line
        uuid  = SecureRandom.uuid
        item = {
            "uuid"        => uuid,
            "mikuType"    => "NxBoardItem",
            "unixtime"    => Time.new.to_i,
            "datetime"    => Time.new.utc.iso8601,
            "description" => description,
            "field11"     => nil,
            "boarduuid"     => boarduuid,
            "boardposition" => boardposition
        }
        NxBoardItems::commit(item)
        item
    end

    # ----------------------------------------------------------------
    # Data

    # NxBoards::toString(item)
    def self.toString(item)
        engine = item["engine"]

        if engine["type"] == "managed" then
            rt = BankUtils::recoveredAverageHoursPerDay(item["uuid"])
            return "(stream) (rt: #{("%5.2f" % rt)}) #{item["description"]}"
        end

        if engine["type"] == "time-commitment" then
            loadDoneInHours = BankCore::getValue(item["uuid"]).to_f/3600 + engine["hours"]
            loadLeftInhours = engine["hours"] - loadDoneInHours
            timePassedInDays = (Time.new.to_i - engine["lastResetTime"]).to_f/86400
            timeLeftInDays = 7 - timePassedInDays
            str1 = "(done #{("%5.2f" % loadDoneInHours).to_s.green} out of #{engine["hours"]})"
            str2 = 
                if timeLeftInDays > 0 then
                    "(#{timeLeftInDays.round(2)} days before reset)"
                else
                    "(late by #{-timeLeftInDays.round(2)})"
                end
            "(board) #{item["description"].ljust(8)} #{str1} #{str2}"
        end
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

    # NxBoards::interactivelyDecideNewBoardPosition(stream)
    def self.interactivelyDecideNewBoardPosition(stream)
        NxBoards::boardItemsOrdered(stream["uuid"])
            .first(20)
            .each{|item| puts NxBoardItems::toString(item) }
        LucilleCore::askQuestionAnswerAsString("position: ").to_f
    end

    # NxBoards::interactivelyDecideBoardPositionPair()
    def self.interactivelyDecideBoardPositionPair()
        stream = NxBoards::interactivelySelectOne()
        position = NxBoards::interactivelyDecideNewBoardPosition(stream)
        [stream, position]
    end

    # NxBoards::rtTarget(item)
    def self.rtTarget(item)
        if item["engine"]["type"] == "managed" then
            return 0.4
        end
        if item["engine"]["type"] == "time-commitment" then
            return item["engine"]["hours"].to_f/5 # Hopefully 5 days
        end
        raise "(error: afcf8b95-c68c-4395-99c5-8e7538926630)"
    end

    # NxBoards::completionRatio(item)
    def self.completionRatio(item)
        BankUtils::recoveredAverageHoursPerDay(item["uuid"]).to_f/NxBoards::rtTarget(item)
    end

    # NxBoards::listingItems()
    def self.listingItems()
        NxBoards::items()
            .sort{|s1, s2| NxBoards::completionRatio(s1) <=> NxBoards::completionRatio(s2)}
            .select{|stream| NxBoards::completionRatio(stream) < 1 }
    end

    # NxBoards::bottomItems()
    def self.bottomItems()
        NxBoards::items()
            .sort{|s1, s2| NxBoards::completionRatio(s1) <=> NxBoards::completionRatio(s2)}
            .select{|stream| NxBoards::completionRatio(stream) >= 1 }
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

    # ---------------------------------------------------------
    # Ops

    # NxBoards::listingProgram(stream)
    def self.listingProgram(stream)

        loop {

            system("clear")
            store = ItemStore.new()
            vspaceleft = CommonUtils::screenHeight() - 3

            linecount = Listing::printDesktop()
            vspaceleft = vspaceleft - linecount

            puts ""
            puts "BOARD FOCUS: #{NxBoards::toString(stream)}#{NxBalls::nxballSuffixStatusIfRelevant(stream).green}"
            puts ""
            vspaceleft = vspaceleft - 3

            items = NxBoards::boardItemsOrdered(stream["uuid"])

            lockedItems, items = items.partition{|item| Locks::isLocked(item["uuid"]) }
            lockedItems.each{|item|
                vspaceleft = vspaceleft - CommonUtils::verticalSize(PolyFunctions::toString(item))
            }

            linecount = Listing::itemsToVerticalSpace(lockedItems)
            vspaceleft = vspaceleft - linecount

            items
                .each{|item|
                    store.register(item, !Skips::isSkipped(item["uuid"]))
                    line = Listing::itemToListingLine(store, item)
                    puts line
                    vspaceleft = vspaceleft - CommonUtils::verticalSize(line)
                    break if vspaceleft <= 0
                }

            lockedItems
                .each{|item|
                    store.register(item, false)
                    line = Listing::itemToListingLine(store, item)
                    puts line
                }

            puts ""
            input = LucilleCore::askQuestionAnswerAsString("> ")
            return if input == "exit"
            next if input == ""

            Listing::listingCommandInterpreter(input, store, board)
        }
    end

    # NxBoards::timeManagement()
    def self.timeManagement()
        NxBoards::items().each{|item|
            engine = item["engine"]
            if engine["type"] == "time-commitment" then
                if BankCore::getValue(item["uuid"]) >= 0 and (Time.new.to_i - engine["lastResetTime"]) >= 86400*7 then
                    puts "resetting time commitment stream: #{item["description"]}"
                    BankCore::put(item["uuid"], -engine["hours"]*3600)
                    item["engine"]["lastResetTime"] = Time.new.to_i
                    NxBoards::commit(item)
                end
            end
        }
    end
end
