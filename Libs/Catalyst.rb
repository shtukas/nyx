# encoding: UTF-8

class Catalyst

    # Catalyst::idToSmallShift(id)
    def self.idToSmallShift(id)
        shift = XCache::getOrNull("0f8a5f9b-d3de-4910-bafd-13c3718007dc:#{id}")
        return shift.to_f if shift
        shift = rand.to_f/100
        XCache::set("0f8a5f9b-d3de-4910-bafd-13c3718007dc:#{id}", shift)
        shift
    end

    # Catalyst::primaryCommandProcess()
    def self.primaryCommandProcess()
        puts Commands::commands().yellow
        input = LucilleCore::askQuestionAnswerAsString("> ")
        command, objectOpt = Commands::run(input, nil)
        #puts "parser: command:#{command}, objectOpt: #{objectOpt}"
        LxAction::action(command, objectOpt)
    end

    # Catalyst::topFilepath()
    def self.topFilepath()
        "/Users/#{ENV['USER']}/Desktop/top.txt"
    end

    # Catalyst::getTopOrNull()
    def self.getTopOrNull()
        content = IO.read(Catalyst::topFilepath()).strip
        return nil if content == ""
        text = content.lines.first(10).select{|line| line.strip.size > 0 }.join.strip
        return nil if text == ""
        text
    end

    # Catalyst::section2()
    def self.section2()
        x1 = [
            JSON.parse(`#{Config::userHomeDirectory()}/Galaxy/Binaries/fitness ns16s`),
        ]
            .flatten
            .select{|item| DoNotShowUntil::isVisible(item["uuid"]) }
            .select{|item| InternetStatus::itemShouldShow(item["uuid"]) }
            .map{|item|
                {
                    "item" => item,
                    "toString" => LxFunction.function("toString", item),
                    "metric"   => 0.9 + Catalyst::idToSmallShift("fitness")
                }
            }

        x2 = [
            Anniversaries::section2(),
            Waves::section2(true),
            TxDateds::section2(),
            NxLines::section2(),
            TxProjects::section2(),
            Waves::section2(false),
            NxTasks::section2(),
            Streaming::section2(),
        ]
            .flatten
            .select{|x| DoNotShowUntil::isVisible(x["item"]["uuid"]) }
            .select{|x| InternetStatus::itemShouldShow(x["item"]["uuid"]) }

        (x1 + x2)
            .sort{|i1, i2| i1["metric"] <=> i2["metric"] }
            .reverse
    end

    # Catalyst::program()
    def self.program()

        initialCodeTrace = CommonUtils::generalCodeTrace()
 
        if Machines::isLucille20() then 
            Thread.new {
                loop {
                    sleep 3600
                    system("#{File.dirname(__FILE__)}/operations/vienna-import")
                }
            }
        end

        loop {

            #puts "(code trace)"
            if CommonUtils::generalCodeTrace() != initialCodeTrace then
                puts "Code change detected"
                break
            end

            system("/Users/#{ENV["USER"]}/Galaxy/DataBank/Stargate/bitbucket/sync")

            SystemEvents::pickupDrops()

            #puts "(NxTasks-Inbox)"
            LucilleCore::locationsAtFolder("#{Config::userHomeDirectory()}/Desktop/NxTasks-Inbox").each{|location|
                item = NxTasks::issueFromInboxLocation(location)
                puts JSON.pretty_generate(item)
                LucilleCore::removeFileSystemLocation(location)
            }

            if !XCache::getFlag("8101be28-da9d-4e3d-83e6-3cee5470c59e:#{CommonUtils::today()}") then
                system("clear")
                puts "frames:"
                NxFrames::items().each{|frame|
                    puts "    - #{NxFrames::toString(frame)}"
                }
                LucilleCore::pressEnterToContinue()
                XCache::setFlag("8101be28-da9d-4e3d-83e6-3cee5470c59e:#{CommonUtils::today()}", true)
                next
            end

            SystemEvents::pickupDrops()

            Catalyst::printListing()
        }
    end

    # Catalyst::printListing()
    def self.printListing()
        system("clear")

        vspaceleft = CommonUtils::screenHeight()-3

        if Machines::isLucille20() then
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

        running = NxBallsIO::nxballs()
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

        if top = Catalyst::getTopOrNull() then
            puts ""
            puts top.green
            vspaceleft = vspaceleft - (CommonUtils::verticalSize(top) + 1)
        end

        frames = NxFrames::items()
        if !frames.empty? then
            puts ""
            vspaceleft = vspaceleft - 1
            frames
                .each{|item|
                    store.register(item, false)
                    line = "#{store.prefixString()} #{NxFrames::toString(item)}".yellow
                    break if (vspaceleft - CommonUtils::verticalSize(line)) < 0
                    if NxBallsService::isActive(item["uuid"]) then
                        line = "#{line} (#{NxBallsService::activityStringOrEmptyString("", item["uuid"], "")})".green
                    end
                    puts line
                    vspaceleft = vspaceleft - CommonUtils::verticalSize(line)
                }
        end

        section2 = Catalyst::section2()
        if !section2.empty? then
            puts ""
            vspaceleft = vspaceleft - 1
            section2
                .each{|p|
                    item = p["item"]
                    toString = p["toString"]
                    store.register(item, true)
                    line = "#{store.prefixString()} #{"%.3f" % p["metric"]} #{toString}"
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
