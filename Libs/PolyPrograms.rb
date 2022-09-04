
class PolyPrograms

    # PolyPrograms::catalystMainListing()
    def self.catalystMainListing()
        system("clear")

        vspaceleft = CommonUtils::screenHeight()-3

        if Config::get("instanceId") == "Lucille20-pascal" then
            reference = The99Percent::getReferenceOrNull()
            current   = The99Percent::getCurrentCount()
            ratio     = current.to_f/reference["count"]
            line      = "👩‍💻 🔥 #{current} #{ratio} ( #{reference["count"]} @ #{reference["datetime"]} )"
            puts ""
            puts line
            vspaceleft = vspaceleft - 2
            if ratio < 0.99 then
                The99Percent::issueNewReferenceOrNull()
            end
        end

        store = ItemStore.new()

        if !InternetStatus::internetIsActive() then
            puts "INTERNET IS OFF".green
            vspaceleft = vspaceleft - 2
        end

        puts ""
        vspaceleft = vspaceleft - 1

        floats = TxFloats::listingItems()
        floats.each{|item|
            store.register(item, false)
            line = "#{store.prefixString()} #{PolyFunctions::toString(item)}".yellow
            if NxBallsService::isPresent(item["uuid"]) then
                line = "#{line} (#{NxBallsService::activityStringOrEmptyString("", item["uuid"], "")})".green
            end
            puts line
            vspaceleft = vspaceleft - CommonUtils::verticalSize(line)
        }
        puts ""
        vspaceleft = vspaceleft - 1

        listingItems = CatalystListing::listingItems()

        displayedOneNxBall = false
        NxBallsIO::nxballs()
            .sort{|t1, t2| t1["unixtime"] <=> t2["unixtime"] }
            .each{|nxball|
                next if XCacheValuesWithExpiry::getOrNull("recently-listed-uuid-ad5b7c29c1c6:#{nxball["uuid"]}") # A special purpose way to not display a NxBall.
                displayedOneNxBall = true
                store.register(nxball, false)
                line = "#{store.prefixString()} [running] #{nxball["description"]} (#{NxBallsService::activityStringOrEmptyString("", nxball["uuid"], "")})"
                puts line.green
                vspaceleft = vspaceleft - CommonUtils::verticalSize(line)
            }
        if displayedOneNxBall then
            puts ""
            vspaceleft = vspaceleft - 1
        end

        inbox = InboxItems::listingItems()
        inbox.each{|item|
            store.register(item, false)
            line = "#{store.prefixString()} #{PolyFunctions::toString(item)}"
            if NxBallsService::isPresent(item["uuid"]) then
                line = "#{line} (#{NxBallsService::activityStringOrEmptyString("", item["uuid"], "")})".green
            end
            puts line
            vspaceleft = vspaceleft - CommonUtils::verticalSize(line)
        }
        if !inbox.empty? then
            puts ""
            vspaceleft = vspaceleft - 1
        end

        planninguuids = MxPlanning::catalystItemsUUIDs() + inbox.map{|item| item["uuid"] }

        CatalystListing::listingItems()
            .each{|item|
                next if planninguuids.any?(item["uuid"]) # We do not display in the lower listing items that are planning managed
                break if vspaceleft <= 0
                store.register(item, true)
                line = "#{store.prefixString()} #{PolyFunctions::toString(item)}"
                if NxBallsService::isPresent(item["uuid"]) then
                    line = "#{line} (#{NxBallsService::activityStringOrEmptyString("", item["uuid"], "")})".green
                end
                puts line
                vspaceleft = vspaceleft - CommonUtils::verticalSize(line)
            }

        CommandInterpreter::commandPrompt(store)
    end

    # PolyPrograms::landing(item, entities)
    def self.landing(item, entities)
        loop {
            return nil if item.nil?
            uuid = item["uuid"]
            item = DxF1::getProtoItemOrNull(uuid)
            return nil if item.nil?
            system("clear")
            puts PolyFunctions::toString(item)
            puts "uuid: #{item["uuid"]}".yellow
            puts "unixtime: #{item["unixtime"]}".yellow
            puts "datetime: #{item["datetime"]}".yellow
            store = ItemStore.new()
            # We register the item which is also the default element in the store
            store.register(item, true)
            if entities.size > 0 then
                puts ""
                if entities.size < 200 then
                    entities
                        .sort{|e1, e2| e1["datetime"]<=>e2["datetime"] }
                        .each{|entity|
                            indx = store.register(entity, false)
                            puts "[#{indx.to_s.ljust(3)}] #{PolyFunctions::toString(entity)}"
                        }
                else
                    puts "(... many entities, use `navigation` ...)"
                end
            end

            puts ""
            input = LucilleCore::askQuestionAnswerAsString("> ")
            return if input == ""
            CommandInterpreter::run(input, store)
        }
    end
end
