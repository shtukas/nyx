
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
        engine = NxEngine::interactivelyMakeNewEngine()
        isListeable = LucilleCore::askQuestionAnswerAsBoolean("Is listeable ? ")
        item = {
            "uuid"        => uuid,
            "mikuType"    => "NxStream",
            "unixtime"    => Time.new.to_i,
            "datetime"    => Time.new.utc.iso8601,
            "description" => description,
            "engine"      => engine,
            "isListeable" => isListeable
        }
        NxStreams::commit(item)
        item
    end

    # NxStreams::issueLine(line, streamuuid, streamposition)
    def self.issueLine(line, streamuuid, streamposition)
        description = line
        uuid  = SecureRandom.uuid
        item = {
            "uuid"        => uuid,
            "mikuType"    => "NxBoardItem",
            "unixtime"    => Time.new.to_i,
            "datetime"    => Time.new.utc.iso8601,
            "description" => description,
            "field11"     => nil,
            "boarduuid"     => streamuuid,
            "boardposition" => streamposition
        }
        NxBoardItems::commit(item)
        item
    end

    # ----------------------------------------------------------------
    # Data

    # NxStreams::toString(item)
    def self.toString(item)
        "(stream) #{item["description"]}"
    end

    # NxStreams::toStringForListing(item)
    def self.toStringForListing(item)

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
            str1 = "(done #{loadDoneInHours.round(2).to_s.green} out of #{engine["hours"]})"
            str2 = 
                if timeLeftInDays > 0 then
                    average = loadLeftInhours.to_f/timeLeftInDays
                    "(#{timeLeftInDays.round(2)} days before reset) (#{average.round(2)} hours/day)"
                else
                    "(late by #{-timeLeftInDays.round(2)})"
                end
            "(stream) #{item["description"]} #{str1} #{str2}"
        end
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

    # NxStreams::interactivelyDecideNewStreamPosition(stream)
    def self.interactivelyDecideNewStreamPosition(stream)
        NxStreams::streamItemsOrdered(stream["uuid"])
            .first(20)
            .each{|item| puts NxBoardItems::toString(item) }
        LucilleCore::askQuestionAnswerAsString("position: ").to_f
    end

    # NxStreams::interactivelyDecideStreamPositionPair()
    def self.interactivelyDecideStreamPositionPair()
        stream = NxStreams::interactivelySelectOne()
        position = NxStreams::interactivelyDecideNewStreamPosition(stream)
        [stream, position]
    end

    # NxStreams::rtTarget(item)
    def self.rtTarget(item)
        if item["engine"]["type"] == "managed" then
            return 0.4
        end
        if item["engine"]["type"] == "time-commitment" then
            return item["engine"]["hours"].to_f/5 # Hopefully 5 days
        end
        raise "(error: afcf8b95-c68c-4395-99c5-8e7538926630)"
    end

    # NxStreams::completionRatio(item)
    def self.completionRatio(item)
        BankUtils::recoveredAverageHoursPerDay(item["uuid"]).to_f/NxStreams::rtTarget(item)
    end

    # NxStreams::listingItems()
    def self.listingItems()
        NxStreams::items()
            .map{|stream|
                {
                    "stream" => stream,
                    "ratio"  => NxStreams::completionRatio(stream)
                }
            }
            .sort{|p1, p2|
                p1["ratio"] <=> p2["ratio"]
            }
            .select{|packet|
                packet["ratio"] < 1
            }
            .map{|packet|
                stream = packet["stream"]
                todo = NxStreams::streamItemsOrdered(stream["uuid"]).first
                if todo then
                    {
                        "uuid"        => "#{stream["uuid"]}-#{todo["uuid"]}",
                        "mikuType"    => "NxBoardFirstItem",
                        "description" => "(first item) #{stream["description"].yellow} | #{todo["description"]}",
                        "stream"      => stream,
                        "todo"        => todo
                    }
                else
                    if stream["isListeable"] then
                        stream
                    else
                        nil
                    end
                end
            }
            .compact
    end

    # NxStreams::boardItems(streamuuid)
    def self.boardItems(streamuuid)
        NxBoardItems::items().select{|item| item["boarduuid"] == streamuuid }
    end

    # NxStreams::streamItemsOrdered(streamuuid)
    def self.streamItemsOrdered(streamuuid)
        NxStreams::boardItems(streamuuid)
            .sort{|i1, i2| i1["boardposition"] <=> i2["boardposition"] }
    end

    # ---------------------------------------------------------
    # Ops

    # NxStreams::listingProgram(stream)
    def self.listingProgram(stream)

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
            puts "BOARD FOCUS: #{NxStreams::toString(stream)}#{NxBalls::nxballSuffixStatusIfRelevant(stream).green}"
            puts ""
            vspaceleft = vspaceleft - 3

            items = NxStreams::streamItemsOrdered(stream["uuid"])

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
            # We have a special line command that fast inject a line on the stream

            if input.start_with?("line:") then
                line = input[6, input.length].strip
                line = line.reverse
                position = line.index("@")
                ordinal = line[0, position].strip.reverse.to_f
                description = line[position+1, line.size].strip.reverse
                puts "line:"
                puts "    description: #{description}"
                puts "    ordinal    : #{ordinal}"
                NxStreams::issueLine(description, stream["uuid"], ordinal)
                next
            end

            Listing::listingCommandInterpreter(input, store, stream)
        }
    end

    # NxStreams::timeManagement()
    def self.timeManagement()
        NxStreams::items().each{|item|
            engine = item["engine"]
            if engine["type"] == "time-commitment" then
                if BankCore::getValue(item["uuid"]) >= 0 and (Time.new.to_i - engine["lastResetTime"]) >= 86400*7 then
                    puts "resetting time commitment stream: #{item["description"]}"
                    BankCore::put(item["uuid"], -engine["hours"]*3600)
                    item["engine"]["lastResetTime"] = Time.new.to_i
                    NxStreams::commit(item)
                end
            end
        }
    end
end
