# encoding: UTF-8


$OrdinalForListingItems = {}

class Catalyst

    # Catalyst::itemsForSection1()
    def self.itemsForSection1()
        [
            NxFrames::items(),
            TxQueues::items(),
            TxProjects::items(),
        ]   
            .flatten
            .sort{|t1, t2| t1["unixtime"] <=> t2["unixtime"] }
    end

    # Catalyst::itemsForSection2()
    def self.itemsForSection2()
        items = [
            Streaming::listingItemForAnHour(),
            JSON.parse(`/Users/pascal/Galaxy/LucilleOS/Binaries/fitness ns16s`),
            Anniversaries::itemsForListing(),
            Waves::itemsForListing(),
            TxDateds::itemsForListing(),
            TxProjects::itemsForMainListing(),
            TxQueues::itemsForMainListing(),
            NxTasks::itemsForMainListing()
        ]
            .flatten
            .select{|item| DoNotShowUntil::isVisible(item["uuid"]) }
            .select{|item| InternetStatus::itemShouldShow(item["uuid"]) }

        if items.size == 0 then
            items = Streaming::listingItemInfinity()
        end

        items
    end

    # Catalyst::printListing(floatingItems, runningItems, mainListingItems)
    def self.printListing(floatingItems, runningItems, mainListingItems)
        system("clear")

        vspaceleft = CommonUtils::screenHeight()-3

        if Machines::isLucille20() then
            packet = XCache::getOrNull("numbers-cfa0a4bfba8e") # {"line": String, "ratio": Float}
            if packet then
                packet = JSON.parse(packet)
                puts ""
                puts packet["line"]
                vspaceleft = vspaceleft - 2
                if packet["ratio"] < 0.99 then
                    The99Percent::issueNewReference()
                    return
                end
            end
        end

        store = ItemStore.new()

        if !InternetStatus::internetIsActive() then
            puts "INTERNET IS OFF".green
            vspaceleft = vspaceleft - 2
        end

        puts ""
        vspaceleft = vspaceleft - 1
        floatingItems
            .each{|item|
                store.register(item, false)
                line = "#{store.prefixString()} #{LxFunction::function("toString", item)}".yellow
                if NxBallsService::isActive(item["uuid"]) then
                    line = "#{line} (#{NxBallsService::activityStringOrEmptyString("", item["uuid"], "")})".green
                end
                puts line
                vspaceleft = vspaceleft - CommonUtils::verticalSize(line)
            }

        running = NxBallsIO::getItems().select{|nxball| !runningItems.map{|item| item["uuid"] }.include?(nxball["uuid"]) }
        if running.size > 0 then
            puts ""
            vspaceleft = vspaceleft - 1
            running
                .sort{|t1, t2| t1["unixtime"] <=> t2["unixtime"] }
                .each{|nxball|
                    store.register(nxball, true)
                    line = "#{store.prefixString()} [running] #{nxball["description"]} (#{NxBallsService::activityStringOrEmptyString("", nxball["uuid"], "")})"
                    puts line.green
                    vspaceleft = vspaceleft - CommonUtils::verticalSize(line)
                }
        end

        top = IO.read("/Users/pascal/Desktop/top.txt").strip.lines.select{|line| line.strip.size > 0 }.join.strip
        if top.size > 0 then
            puts ""
            puts "top:"
            puts top.green
            vspaceleft = vspaceleft - (CommonUtils::verticalSize(top) + 2)
        end

        ordinals = NxOrdinals::itemsForListing()
        if ordinals.size > 0 then
            puts ""
            puts "ordinals:"
            vspaceleft = vspaceleft - 2
            ordinals.each{|ordinal|
                store.register(ordinal, true)
                line = "#{store.prefixString()} #{NxOrdinals::toString(ordinal)}"
                puts line.green
                vspaceleft = vspaceleft - CommonUtils::verticalSize(line)
            }
        end

        printSection = lambda {|section, store|
            section
                .each{|item|
                    store.register(item, true)
                    line = LxFunction::function("toString", item)
                    line = "#{store.prefixString()} #{line}"
                    break if (vspaceleft - CommonUtils::verticalSize(line)) < 0
                    if NxBallsService::isActive(item["uuid"]) then
                        line = "#{line} (#{NxBallsService::activityStringOrEmptyString("", item["uuid"], "")})".green
                    end
                    puts line
                    vspaceleft = vspaceleft - CommonUtils::verticalSize(line)
                }
        }

        puts ""
        vspaceleft = vspaceleft - 1
        printSection.call(runningItems, store)
        printSection.call(mainListingItems, store)

        puts ""
        input = LucilleCore::askQuestionAnswerAsString("> ")

        return if input == ""

        if input.start_with?("+") and (unixtime = CommonUtils::codeToUnixtimeOrNull(input.gsub(" ", ""))) then
            if (item = store.getDefault()) then
                NxBallsService::close(item["uuid"], true)
                DoNotShowUntil::setUnixtime(item["uuid"], unixtime)
                return
            end
        end

        Commands::run(input, store)
    end

    # Catalyst::program2()
    def self.program2()

        initialCodeTrace = CommonUtils::generalCodeTrace()
 
        if Machines::isLucille20() then
            Thread.new {
                loop {
                    sleep 120
                    reference = The99Percent::getReference()
                    current   = The99Percent::getCurrentCount()
                    ratio     = current.to_f/reference["count"]
                    line      = "👩‍💻 🔥 #{current} #{ratio} ( #{reference["count"]} @ #{reference["datetime"]} )"
                    packet    = {"line" => line, "ratio" => ratio}
                    XCache::set("numbers-cfa0a4bfba8e", JSON.generate(packet))
                }
            }
 
            Thread.new {
                loop {
                    sleep 3600
                    system("#{File.dirname(__FILE__)}/operations/vienna-import")
                }
            }
        end

        EventsToAWSQueue::sync(true)

        Thread.new {
            loop {
                sleep 60
                EventsToAWSQueue::sync(false)
            }
        }

        loop {

            #puts "(code trace)"
            if CommonUtils::generalCodeTrace() != initialCodeTrace then
                puts "Code change detected"
                break
            end

            #puts "(NxTasks-Inbox)"
            LucilleCore::locationsAtFolder("/Users/pascal/Desktop/NxTasks-Inbox").each{|location|
                item = NxTasks::issueFromInboxLocation(location)
                puts JSON.pretty_generate(item)
                LucilleCore::removeFileSystemLocation(location)
            }

            getOrdinalForListingItem = lambda {|item|
                if $OrdinalForListingItems[item["uuid"]] then
                    return $OrdinalForListingItems[item["uuid"]]
                end

                ordinal = XCache::getOrNull("9CF9:67703767-B635-486E-683397DEA056:#{item["uuid"]}")
                if ordinal then
                    ordinal = ordinal.to_f
                    $OrdinalForListingItems[item["uuid"]] = ordinal
                    return ordinal
                end

                # By here we do not have an ordinal for this item, so we need one
                ordinal = XCache::getOrNull("9CF9:TOP-ORDINAL-486E-683397DEA056")
                if ordinal.nil? then
                    ordinal = 0
                else
                    ordinal = ordinal.to_f
                end
                ordinal = ordinal + 1

                XCache::set("9CF9:TOP-ORDINAL-486E-683397DEA056", ordinal)
                XCache::set("9CF9:67703767-B635-486E-683397DEA056:#{item["uuid"]}", ordinal)
                $OrdinalForListingItems[item["uuid"]] = ordinal

                ordinal
            }

            #puts "(floatingItems)"
            floatingItems = Catalyst::itemsForSection1()

            #puts "(mainListingItems) 1"
            mainListingItems = Catalyst::itemsForSection2()

            #puts "(mainListingItems) 2"
            mainListingItems.each{|item| getOrdinalForListingItem.call(item) }

            #puts "(mainListingItems) 3"
            mainListingItems = mainListingItems.sort{|i1, i2| getOrdinalForListingItem.call(i1) <=> getOrdinalForListingItem.call(i2) }

            #puts "(mainListingItems) 4"
            runningItems, mainListingItems = mainListingItems.partition{|item| NxBallsService::isActive(item["uuid"]) }

            #puts "(Catalyst::printListing)"
            Catalyst::printListing(floatingItems, runningItems, mainListingItems)
        }
    end
end
