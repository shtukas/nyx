# encoding: UTF-8

class Catalyst

    # Catalyst::primaryCommandProcess()
    def self.primaryCommandProcess()
        puts Commands::commands().yellow

        input = LucilleCore::askQuestionAnswerAsString("> ")

        command, objectOpt = Commands::run(input, nil)
        #puts "parser: command:#{command}, objectOpt: #{objectOpt}"
        LxAction::action(command, objectOpt)
    end

    # Catalyst::items()
    def self.items()
        [
            JSON.parse(`/Users/pascal/Galaxy/LucilleOS/Binaries/fitness ns16s`),
            Anniversaries::itemsForListing(),
            NxFrames::items(),
            Waves::itemsForListing(true),
            TxDateds::itemsForListing(),
            TxProjects::items(),
            TxQueues::itemsForMainListing(),
            Waves::itemsForListing(false),
            Streaming::listingItemToTarget(),
            NxLines::items()
        ]
            .flatten
            .select{|item| DoNotShowUntil::isVisible(item["uuid"]) }
            .select{|item| InternetStatus::itemShouldShow(item["uuid"]) }
    end

    # Catalyst::printListing(itemsDoneToday, top, priority, stratification)
    def self.printListing(itemsDoneToday, top, priority, stratification)
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

        if itemsDoneToday.size > 0 then
            puts ""
            vspaceleft = vspaceleft - 1
            itemsDoneToday
                .each{|item|
                    store.register(item, false)
                    line = "#{store.prefixString()} #{LxFunction::function("toString", item)}".yellow
                    if NxBallsService::isActive(item["uuid"]) then
                        line = "#{line} (#{NxBallsService::activityStringOrEmptyString("", item["uuid"], "")})".green
                    end
                    puts line
                    vspaceleft = vspaceleft - CommonUtils::verticalSize(line)
                }
        end

        uuids = (itemsDoneToday + priority + stratification.map{|nx| nx["item"] }).map{|item| item["uuid"] }
        running = NxBallsIO::getItems().select{|nxball| !uuids.include?(nxball["uuid"]) }
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

        if top then
            puts ""
            puts "top:"
            puts top.green
            vspaceleft = vspaceleft - (CommonUtils::verticalSize(top) + 2)
        end

        if priority.size > 0 then
            puts ""
            puts "priority:"
            vspaceleft = vspaceleft - 2
            priority
                .each{|item|
                    store.register(item, false)
                    line = LxFunction::function("toString", item)
                    line = "#{store.prefixString()} #{line}"
                    break if (vspaceleft - CommonUtils::verticalSize(line)) < 0
                    if NxBallsService::isActive(item["uuid"]) then
                        line = "#{line} (#{NxBallsService::activityStringOrEmptyString("", item["uuid"], "")})".green
                    end
                    puts line
                    vspaceleft = vspaceleft - CommonUtils::verticalSize(line)
                }
        end

        if stratification.size > 0 then
            puts ""
            puts "stratification:"
            vspaceleft = vspaceleft - 2
            stratification
                .each{|nxStratificationItem|
                    item = nxStratificationItem["item"]
                    store.register(item, true)
                    line = "(ord: #{"%5.2f" % nxStratificationItem["ordinal"]}) #{LxFunction::function("toString", item)}"
                    line = "#{store.prefixString()} #{line}"
                    break if (vspaceleft - CommonUtils::verticalSize(line)) < 0
                    if NxBallsService::isActive(item["uuid"]) then
                        line = "#{line} (#{NxBallsService::activityStringOrEmptyString("", item["uuid"], "")})".green
                    end
                    puts line
                    vspaceleft = vspaceleft - CommonUtils::verticalSize(line)
                }
        end

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

    # Catalyst::program3()
    def self.program3()

        listing = Catalyst::items()

        itemsDoneToday, listing = listing.partition{|item| DoneToday::isDoneToday(item["uuid"]) }

        itemsDoneToday = itemsDoneToday.sort{|i1, i2| i1["unixtime"] <=> i2["unixtime"] }

        priorityMikuTypes = ["fitness1"]

        priority, listing = listing.partition{|item| priorityMikuTypes.include?(item["mikuType"]) }

        top = nil
        content = IO.read("/Users/pascal/Desktop/top.txt").strip
        if content.size > 0 then
            text = content.lines.first(10).select{|line| line.strip.size > 0 }.join.strip
            if text.size > 0 then
                top = text
            end
        end

        # --------------------------------------

        stratification = Stratification::getStratificationFromDisk()
        stratification = Stratification::reduce(listing, stratification)
        stratification = Stratification::orderByOrdinal(stratification)
        Stratification::commitStratificationToDisk(stratification)

        incoming = listing.select{|item| !stratification.map{|i| i["item"]["uuid"] }.include?(item["uuid"])}

        if incoming.size > 0 then
            system("clear")
            puts "stratification:"
            stratification
                .each{|nxStratificationItem|
                    item = nxStratificationItem["item"]
                    puts "(ord: #{"%5.2f" % nxStratificationItem["ordinal"]}) #{LxFunction::function("toString", item)}"
                }

            item = incoming.first

            if item["mikuType"] == "NxFrame" then
                # Automatically done for the day
                DoneToday::setDoneToday(item["uuid"])
                return
            end

            puts ""
            puts "incoming:"
            command = LucilleCore::askQuestionAnswerAsString("#{LxFunction::function("toString", item).green} ; run, done, next (ordinal) #default, <ordinal>, +datecode : ")

            ordinal = nil

            if command == "" then
                ordinal = ([0] + stratification.map{|nx| nx["ordinal"]}).max + 1
            end
            if command == "run" then
                LxAction::action("..", item)
                return
            end
            if command == "done" then
                LxAction::action("done-no-confirmation-prompt", item)
                return
            end

            if command.start_with?("+") and (unixtime = CommonUtils::codeToUnixtimeOrNull(command.gsub(" ", ""))) then
                NxBallsService::close(item["uuid"], true)
                puts "DoNotShowUntil: #{Time.at(unixtime).to_s}"
                DoNotShowUntil::setUnixtime(item["uuid"], unixtime)
            end

            if command == "next" then
                ordinal = ([0] + stratification.map{|nx| nx["ordinal"]}).max + 1
            end

            if ordinal.nil? then
                ordinal = command.to_f
            end

            nxStratificationItem = {
                "mikuType"  => "NxStratificationItem",
                "item"      => item,
                "ordinal"   => ordinal,
                "keepAlive" => true
            }
            stratification << nxStratificationItem

            Stratification::commitStratificationToDisk(stratification)

            return
        end

        # --------------------------------------------------------------------------------------------

        #puts "(Catalyst::printListing)"
        stratification = stratification.select{|item|
            item["DoNotDisplayUntilUnixtime"].nil? or (Time.new.to_f > item["DoNotDisplayUntilUnixtime"])
        }
        Catalyst::printListing(itemsDoneToday, top, priority, stratification)
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

            Catalyst::program3()
        }
    end
end
