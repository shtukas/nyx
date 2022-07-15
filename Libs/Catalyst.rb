# encoding: UTF-8

$CatalystItems = nil

class Catalyst

    # Catalyst::primaryCommandProcess()
    def self.primaryCommandProcess()
        puts Commands::commands().yellow

        input = LucilleCore::askQuestionAnswerAsString("> ")

        command, objectOpt = Commands::run(input, nil)
        #puts "parser: command:#{command}, objectOpt: #{objectOpt}"
        LxAction::action(command, objectOpt)
    end

    # Catalyst::section1()
    def self.section1()
        [
            TxProjects::itemsForSection1(),
            NxFrames::items(),
            Streaming::section1()
        ]
            .flatten
    end

    # Catalyst::items()
    def self.items()
        [
            JSON.parse(`/Users/pascal/Galaxy/LucilleOS/Binaries/fitness ns16s`),
            Anniversaries::itemsForListing(),
            Waves::itemsForListing(true),
            TxDateds::itemsForListing(),
            TxProjects::itemsForMainListing(),
            Waves::itemsForListing(false),
            Streaming::section2(),
            NxLines::section2()
        ]
            .flatten
            .select{|item| DoNotShowUntil::isVisible(item["uuid"]) }
            .select{|item| InternetStatus::itemShouldShow(item["uuid"]) }
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

        Thread.new {
            loop {
                sleep 300
                $CatalystItems = Catalyst::items()
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

    # Catalyst::synchronouslyUpdateStratificationWithListing(listing)
    def self.synchronouslyUpdateStratificationWithListing(listing)
        return if listing.nil?

        Stratification::ordinalsdrop()

        stratification = Stratification::getStratificationFromDisk()
        stratification = Stratification::reduce(listing, stratification)
        Stratification::commitStratificationToDisk(stratification)

        incoming = listing.select{|item| !stratification.map{|i| i["item"]["uuid"] }.include?(item["uuid"])}

        incoming.each{|item|
            system("clear")
            puts "stratification:"
            stratification
                .each{|nxStratificationItem|
                    item = nxStratificationItem["item"]
                    puts "(ord: #{"%5.2f" % nxStratificationItem["ordinal"]}) #{LxFunction::function("toString", item)}"
                }

            puts ""
            puts "incoming:"
            command = LucilleCore::askQuestionAnswerAsString("#{LxFunction::function("toString", item).green} ; run, done, next (ordinal) #default, <ordinal>, +datecode : ")

            if command == "" or command == "next" then
                ordinal = ([0] + stratification.map{|nx| nx["ordinal"]}).max + 1
                Stratification::injectItemAtOrdinal(item, ordinal)
                stratification = Stratification::getStratificationFromDisk()
                next
            end
            if command == "run" then
                LxAction::action("..", item)
                next
            end
            if command == "done" then
                LxAction::action("done-no-confirmation-prompt", item)
                next
            end

            if command.start_with?("+") and (unixtime = CommonUtils::codeToUnixtimeOrNull(command.gsub(" ", ""))) then
                NxBallsService::close(item["uuid"], true)
                puts "DoNotShowUntil: #{Time.at(unixtime).to_s}"
                DoNotShowUntil::setUnixtime(item["uuid"], unixtime)
                next
            end

            ordinal = command.to_f

            Stratification::injectItemAtOrdinal(item, ordinal)
        }

    end

    # Catalyst::getTopOrNull()
    def self.getTopOrNull()
        top = nil
        content = IO.read("/Users/pascal/Desktop/top.txt").strip
        if content.size > 0 then
            text = content.lines.first(10).select{|line| line.strip.size > 0 }.join.strip
            if text.size > 0 then
                top = text
            end
        end
        top
    end

    # Catalyst::program3()
    def self.program3()

        section1 = Catalyst::section1().sort{|i1, i2| i1["unixtime"] <=> i2["unixtime"] }

        top = Catalyst::getTopOrNull()

        Catalyst::synchronouslyUpdateStratificationWithListing($CatalystItems)

        Stratification::publishAverageAgeInDays()

        stratification = Stratification::getStratificationFromDisk()
        stratification = Stratification::orderByOrdinal(stratification)
        stratification = stratification.select{|item| item["DoNotDisplayUntilUnixtime"].nil? or (Time.new.to_f > item["DoNotDisplayUntilUnixtime"]) }

        Catalyst::printListing(top, section1, [], stratification)
    end

    # Catalyst::printListing(top, section1, running, stratification)
    def self.printListing(top, section1, running, stratification)
        system("clear")

        vspaceleft = CommonUtils::screenHeight()-3

        if Machines::isLucille20() then
            reference = The99Percent::getReference()
            current   = The99Percent::getCurrentCount()
            ratio     = current.to_f/reference["count"]
            line      = "👩‍💻 🔥 #{current} #{ratio} ( #{reference["count"]} @ #{reference["datetime"]} ) [stratification: #{(XCache::getOrDefaultValue("6ee981a4-315f-4f82-880f-5806424c904f", "0").to_f).round(2)} days]"
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

        uuids = (section1 + stratification.map{|nx| nx["item"] }).map{|item| item["uuid"] }
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

        if section1.size > 0 then
            puts ""
            puts "section 1:"
            vspaceleft = vspaceleft - 1
            section1
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

        if running.size > 0 then
            puts ""
            puts "running:"
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

        if stratification.size > 0 then
            puts ""
            puts "section 2:"
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
end
