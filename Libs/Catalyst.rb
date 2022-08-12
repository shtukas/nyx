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
        items = NxFrames::items()  + TopLevel::section1()
        items.sort{|i1, i2| i1["unixtime"] <=> i2["unixtime"] }
    end

    # Catalyst::section2()
    def self.section2()
        [
            JSON.parse(`#{Config::userHomeDirectory()}/Galaxy/Binaries/fitness ns16s`),
            Anniversaries::section2(),
            TxDateds::section2(),
            Waves::section2(true),
            NxLines::section2(),
            NxGroups::section2(),
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
 
        if Config::get("instanceId") == "Lucille20-pascal" then 
            Thread.new {
                loop {
                    sleep 3600
                    system("#{File.dirname(__FILE__)}/operations/vienna-import")
                }
            }
        end

        #SystemEvents::broadcast({
        #  "mikuType"  => "ItemToGroupMapping-eventuuids",
        #  "eventuuids" => ItemToGroupMapping::eventuuids()
        #})

        # ---------------------------------------------------------------
        # Data correction
        db = SQLite3::Database.new(Bank::pathToBank())
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.execute "delete from _bank_ where _eventuuid_ is null", []
        db.close
        # ---------------------------------------------------------------

        loop {

            #puts "(code trace)"
            if CommonUtils::generalCodeTrace() != initialCodeTrace then
                puts "Code change detected"
                break
            end

            if File.exists?(Config::starlightCommLine()) then
                LucilleCore::locationsAtFolder(Config::starlightCommLine())
                    .each{|filepath|
                        next if !File.exists?(filepath)
                        next if File.basename(filepath)[-11, 11] != ".event.json"
                        e = JSON.parse(IO.read(filepath))
                        next if e["targetInstance"] != Config::get("instanceId")
                        puts "event from starlight: #{JSON.pretty_generate(e)}"
                        SystemEvents::processEventInternally(e)
                        FileUtils.rm(filepath)
                    }
            end

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

        puts ""
        vspaceleft = vspaceleft - 1
        TopLevel::items()
            .sort{|i1, i2|  i1["unixtime"] <=> i2["unixtime"]}
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

        puts ""
        vspaceleft = vspaceleft - 1
        NxGroups::section1()
            .each{|item|
                store.register(item, false)
                line = "#{store.prefixString()} #{NxGroups::toStringAdjusted(item)}".yellow
                break if (vspaceleft - CommonUtils::verticalSize(line)) < 0
                if NxBallsService::isActive(item["uuid"]) then
                    line = "#{line} (#{NxBallsService::activityStringOrEmptyString("", item["uuid"], "")})".green
                end
                puts line
                vspaceleft = vspaceleft - CommonUtils::verticalSize(line)
            }

        puts ""
        vspaceleft = vspaceleft - 1
        NxFrames::items()
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

        puts ""
        vspaceleft = vspaceleft - 1
        Catalyst::section2()
            .each{|item|
                store.register(item, true)
                toString1 = LxFunction::function("toString", item)
                toString2 = XCache::getOrNull("a95b9b32-cfc4-4896-b52b-e3c58b72f3ae:#{item["uuid"]}")
                toString = toString2 ? toString2 : toString1
                line = "#{store.prefixString()} #{toString}"
                break if (vspaceleft - CommonUtils::verticalSize(line)) < 0
                if NxBallsService::isActive(item["uuid"]) then
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
                NxBallsService::close(item["uuid"], true)
                DoNotShowUntil::setUnixtime(item["uuid"], unixtime)
                return
            end
        end

        Commands::run(input, store)
    end
end
