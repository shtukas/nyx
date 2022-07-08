# encoding: UTF-8

class Catalyst

    # Catalyst::itemsForSection1()
    def self.itemsForSection1()
        [
            NxFrames::itemsForSection1(),
            TxProjects::itemsForSection1(),
        ]   
            .flatten
    end

    # Catalyst::itemsForSection2()
    def self.itemsForSection2()
        items = 
            if Time.new.hour < 6 or Time.new.hour > 17 then
                [
                    # Together in the morning
                    Waves::itemsForListing(true),
                    Waves::itemsForListing(false),

                    Streaming::listingItemForAnHour(), # Only out of hours

                    Anniversaries::itemsForListing(),
                    NxFrames::itemsForSection2(),
                    TxDateds::itemsForListing(),
                    TxProjects::itemsForSection2(),
                    TxQueues::itemsForMainListing(),
                    NxTasks::itemsForMainListing(),
                ]
                    .flatten
            else
                [
                    JSON.parse(`/Users/pascal/Galaxy/LucilleOS/Binaries/fitness ns16s`), # day only
                    Anniversaries::itemsForListing(),
                    NxFrames::itemsForSection2(),
                    Waves::itemsForListing(true),
                    TxDateds::itemsForListing(),
                    TxProjects::itemsForSection2(),
                    TxQueues::itemsForMainListing(),
                    NxTasks::itemsForMainListing(),
                    Waves::itemsForListing(false),
                ]
                    .flatten
            end

        items = items
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
            reference = The99Percent::getReference()
            current   = The99Percent::getCurrentCount()
            ratio     = current.to_f/reference["count"]
            line      = "👩‍💻 🔥 #{current} #{ratio} ( #{reference["count"]} @ #{reference["datetime"]} )"
            puts ""
            puts line
            vspaceleft = vspaceleft - 2
            if ratio < 0.99 then
                The99Percent::issueNewReference()
                return
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
                    store.register(nxball, false)
                    line = "#{store.prefixString()} [running] #{nxball["description"]} (#{NxBallsService::activityStringOrEmptyString("", nxball["uuid"], "")})"
                    puts line.green
                    vspaceleft = vspaceleft - CommonUtils::verticalSize(line)
                }
        end

        content = IO.read("/Users/pascal/Desktop/top.txt").strip
        if content.size > 0 then
            top = content.lines.first(10).select{|line| line.strip.size > 0 }.join.strip
            if top.size > 0 then
                puts ""
                puts "top:"
                puts top.green
                vspaceleft = vspaceleft - (CommonUtils::verticalSize(top) + 2)
            end
        end

        ordinals = NxOrdinals::itemsForListing()
        if ordinals.size > 0 then
            puts ""
            puts "ordinals:"
            vspaceleft = vspaceleft - 2
            ordinals.each{|ordinal|
                store.register(ordinal, false)
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

            #puts "(floatingItems)"
            floatingItems = Catalyst::itemsForSection1()

            #puts "(mainListingItems) 1"
            mainListingItems = Catalyst::itemsForSection2()

            #puts "(mainListingItems) 4"
            runningItems, mainListingItems = mainListingItems.partition{|item| NxBallsService::isActive(item["uuid"]) }

            #puts "(Catalyst::printListing)"
            Catalyst::printListing(floatingItems, runningItems, mainListingItems)
        }
    end
end
