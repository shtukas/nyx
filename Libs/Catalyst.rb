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

    # Catalyst::topFilepath()
    def self.topFilepath()
        "/Volumes/Keybase (#{ENV['USER']})/private/0x1021/top.txt"
    end

    # Catalyst::getTopOrNull()
    def self.getTopOrNull()
        content = IO.read(Catalyst::topFilepath()).strip
        return nil if content == ""
        text = content.lines.first(10).select{|line| line.strip.size > 0 }.join.strip
        return nil if text == ""
        text
    end

    # Catalyst::section2ToListing()
    def self.section2ToListing()
        JSON.parse(`#{Config::userHomeDirectory()}/Galaxy/Binaries/fitness ns16s`).each{|item|
            Listing::insertOrReInsert("section2", item, nil)
        }

        [
            lambda { Anniversaries::section2() },
            lambda { Waves::section2() },
            lambda { TxDateds::section2() },
            lambda { NxLines::section2() },
            lambda { TxProjects::section2() },
            lambda { Streaming::section2() },
        ].each{|l|
            l.call().each{|item|
                Listing::insertOrReInsert("section2", item, nil)
            }
        }
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

        Thread.new {
            loop {
                sleep 300

                TxProjects::items().each{|item|
                    Listing::insertOrReInsert("section1", item, Ax39::completionRatio(item))
                }

                NxFrames::items().each{|item|
                    Listing::insertOrReInsert("section1", item, nil)
                }

                Catalyst::section2ToListing()
                Listing::ordinalsdrop()
                Listing::publishAverageAgeInDays()
            }
        }

        loop {

            #puts "(code trace)"
            if CommonUtils::generalCodeTrace() != initialCodeTrace then
                puts "Code change detected"
                break
            end

            #puts "(NxTasks-Inbox)"
            LucilleCore::locationsAtFolder("#{Config::userHomeDirectory()}/Desktop/NxTasks-Inbox").each{|location|
                item = NxTasks::issueFromInboxLocation(location)
                puts JSON.pretty_generate(item)
                LucilleCore::removeFileSystemLocation(location)
            }

            SystemEvents::pickupDrops()

            Catalyst::printListing()
        }
    end

    # Catalyst::printListing()
    def self.printListing()
        system("clear")

        vspaceleft = CommonUtils::screenHeight()-3

        if Machines::isLucille20() then
            reference = The99Percent::getReference()
            current   = The99Percent::getCurrentCount()
            ratio     = current.to_f/reference["count"]
            line      = "👩‍💻 🔥 #{current} #{ratio} ( #{reference["count"]} @ #{reference["datetime"]} ) [section2: #{(XCache::getOrDefaultValue("6ee981a4-315f-4f82-880f-5806424c904f", "0").to_f).round(2)} days]"
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

        puts ""
        vspaceleft = vspaceleft - 1

        if Listing::entries2("section1").size > 0 then
            Listing::entries2("section1")
                .map{|entry| JSON.parse(entry["_object_"]) }
                .sort{|i1, i2| i1["unixtime"] <=> i2["unixtime"] }
                .each{|item|
                    store.register(item, false)
                    line = "#{store.prefixString()} #{LxFunction::function("toString", item)}".yellow
                    if line.include?("(project)") and !line.include?("DoNotShowUntil") then
                        if Ax39::completionRatio(item) < 1 then
                            line = line.white
                        end
                    end
                    puts line
                    vspaceleft = vspaceleft - CommonUtils::verticalSize(line)
                }
        end

        if NxBallsIO::nxballs().size > 0 then
            puts ""
            vspaceleft = vspaceleft - 1
            NxBallsIO::nxballs()
                .each{|item|
                    store.register(item, false)
                    line = LxFunction::function("toString", item)
                    line = "#{store.prefixString()} #{line} (#{NxBallsService::activityStringOrEmptyString("", item["uuid"], "")})".green
                    puts line
                    vspaceleft = vspaceleft - CommonUtils::verticalSize(line)
                }
        end

        if Listing::entries3().size > 0 then
            puts ""
            vspaceleft = vspaceleft - 1
            Listing::entries3()
                .each{|packet|
                    item = JSON.parse(packet["_object_"])
                    store.register(item, true)
                    line = "(ord: #{"%5.2f" % packet["_ordinal_"]}) #{LxFunction::function("toString", item)}"
                    line = "#{store.prefixString()} #{line}"
                    break if (vspaceleft - CommonUtils::verticalSize(line)) < 0
                    if NxBallsService::isActive(item["uuid"]) then
                        line = "#{line} (#{NxBallsService::activityStringOrEmptyString("", item["uuid"], "")})".green
                    end
                    puts line
                    vspaceleft = vspaceleft - CommonUtils::verticalSize(line)
                }
        end

        if Listing::entries4().size > 0 then
            puts ""
            vspaceleft = vspaceleft - 1
            Listing::entries4()
                .each{|packet|
                    item = JSON.parse(packet["_object_"])
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
        end

        puts ""
        input = LucilleCore::askQuestionAnswerAsString("> ")

        return if input == ""

        if input.start_with?("+") and (unixtime = CommonUtils::codeToUnixtimeOrNull(input.gsub(" ", ""))) then
            if (item = store.getDefault()) then
                NxBallsService::close(item["uuid"], true)
                DoNotShowUntil::setUnixtime(item["uuid"], unixtime)
                Listing::removeIfInSection2(item["uuid"])
                return
            end
        end

        Commands::run(input, store)
    end
end
