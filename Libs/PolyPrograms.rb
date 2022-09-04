
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

        puts ""
        input = LucilleCore::askQuestionAnswerAsString("> ")

        return if input == ""

        if input.start_with?("+") and (unixtime = CommonUtils::codeToUnixtimeOrNull(input.gsub(" ", ""))) then
            if (item = store.getDefault()) then
                PolyActions::stop(item)
                DoNotShowUntil::setUnixtime(item["uuid"], unixtime)
                return
            end
        end

        Commands::run(input, store)
    end
end
