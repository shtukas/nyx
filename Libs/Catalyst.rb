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

    # Catalyst::section1()
    def self.section1()
        NxFrames::items() + TxThreads::section1() + TopLevel::section1()
    end

    # Catalyst::section2()
    def self.section2()
        [
            JSON.parse(`#{Config::userHomeDirectory()}/Galaxy/Binaries/fitness ns16s`),
            Anniversaries::section2(),
            TxDateds::section2(),
            Waves::section2(true),
            TxThreads::section2(true),
            NxLines::section2(),
            TxThreads::section2(false),
            Waves::section2(false),
            NxTasks::section2(),
            Streaming::section2(),
        ]
            .flatten
            .select{|item| DoNotShowUntil::isVisible(item["uuid"]) }
            .select{|item| InternetStatus::itemShouldShow(item["uuid"]) }
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

        # ---------------------------------------------------
        # When an element is added to a thread, that information is written in the thread and
        # will eventually reach the thread on other instances, but the element may still show up 
        # as threadless on those other instances, because the cache wasn't set there.

        # We will also be enabling xcache communication, but in the meantime, and even if, this will do

        TxThreads::items()
            .each{|thread| 
                TxThreads::elementuuids(thread).each{|elementuuid|
                    XCache::setFlag("7fe799a9-5b7a-46a9-a70c-b5931d05f70f:#{elementuuid}", true)
                }
            }

        # ---------------------------------------------------

        loop {

            #puts "(code trace)"
            if CommonUtils::generalCodeTrace() != initialCodeTrace then
                puts "Code change detected"
                break
            end

            if File.exists?(Config::starlightCommLine()) then
                LucilleCore::locationsAtFolder(Config::starlightCommLine())
                    .each{|filepath|
                        next if File.basename(filepath)[-11, 11] != ".event.json"
                        e = JSON.parse(IO.read(filepath))
                        next if e["targetInstance"] != Config::get("instanceId")
                        puts "event from starlight: #{JSON.pretty_generate(e)}"
                        SystemEvents::processEventInternally(e)
                        FileUtils.rm(filepath)
                    }
            end

            loop {
                break if !File.exists?(Config::starlightCommLine())
                e = Mercury2::readFirstOrNull("d054a16c-3d68-43b2-b49d-412ea5f5d0af")
                break if e.nil?
                filepath = "#{Config::starlightCommLine()}/#{CommonUtils::timeStringL22()}.event.json"
                File.open(filepath, "w"){|f| f.puts(JSON.pretty_generate(e)) }
                Mercury2::dequeue("d054a16c-3d68-43b2-b49d-412ea5f5d0af")
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
                    store.register(nxball, true)
                    line = "#{store.prefixString()} [running] #{nxball["description"]} (#{NxBallsService::activityStringOrEmptyString("", nxball["uuid"], "")})"
                    puts line.green
                    vspaceleft = vspaceleft - CommonUtils::verticalSize(line)
                }
        end

        section1 = Catalyst::section1()
        if !section1.empty? then
            puts ""
            vspaceleft = vspaceleft - 1
            section1
                .each{|item|
                    store.register(item, false)
                    line = "#{store.prefixString()} #{LxFunction::function("toString", item)}".yellow
                    break if (vspaceleft - CommonUtils::verticalSize(line)) < 0
                    if NxBallsService::isActive(item["uuid"]) then
                        line = "#{line} (#{NxBallsService::activityStringOrEmptyString("", item["uuid"], "")})".green
                    end
                    puts line
                    vspaceleft = vspaceleft - CommonUtils::verticalSize(line)
                }
        end

        section = DailySlots::section()
        if section.size > 0 then
            puts ""
            vspaceleft = vspaceleft - 1
            DailySlots::section().each{|entry|
                item = entry["item"]
                store.register(item, true)
                line = "#{store.prefixString()} (cale) #{entry["hour"]} #{LxFunction::function("toString", item)}"
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
                .each{|item|
                    # Let us not display the ones that already appeared in the calendar
                    next if section.map{|entry| entry["objectuuid"] }.include?(item["uuid"])
                    store.register(item, true)
                    line = "#{store.prefixString()} #{LxFunction::function("toString", item)}"
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
