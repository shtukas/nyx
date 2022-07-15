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

    # Catalyst::section1()
    def self.section1()
        [
            TxProjects::itemsForSection1(),
            NxFrames::items(),
            Streaming::section1()
        ]
            .flatten
    end

    # Catalyst::section2Ops()
    def self.section2Ops()
        JSON.parse(`/Users/pascal/Galaxy/LucilleOS/Binaries/fitness ns16s`).each{|item|
            Listing::insertOrReInsert("section2", item)
        }

        [
            lambda { Anniversaries::section2() },
            lambda { Waves::section2() },
            lambda { TxDateds::section2() },
            lambda { NxLines::section2() },
        ].each{|l|
            l.call().each{|item|
                Listing::insertOrReInsert("section2", item)
            }
        }

        [
            lambda { TxProjects::section2Xp() },
            lambda { Streaming::section2Xp() },
        ].each{|l|
            items1, itemuuids2 = l.call()
            items1.each{|item|
                Listing::insertOrReInsert("section2", item)
            }
            itemuuids2.each{|itemuuid|
                Listing::remove(itemuuid)
            }
        }
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

        ExternalEvents::sync(true)

        Thread.new {
            loop {
                sleep 60
                ExternalEvents::sync(false)
            }
        }

        Thread.new {
            loop {
                sleep 300
                Catalyst::section1().each{|item|
                    Listing::insertOrReInsert("section1", item)
                }
                Catalyst::section2Ops()
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
            LucilleCore::locationsAtFolder("/Users/pascal/Desktop/NxTasks-Inbox").each{|location|
                item = NxTasks::issueFromInboxLocation(location)
                puts JSON.pretty_generate(item)
                LucilleCore::removeFileSystemLocation(location)
            }

            top = Catalyst::getTopOrNull()

            section1 = Listing::entries()
                        .select{|entry| entry["_zone_"] == "section1" }
                        .map{|entry| JSON.parse(entry["_object_"]) }
                        .sort{|i1, i2| i1["unixtime"] <=> i2["unixtime"] }

            running = Listing::entries()
                        .map{|entry| JSON.parse(entry["_object_"]) }
                        .select{|item| NxBallsService::isRunning(item["uuid"])}

            section2 = Listing::entries()
                        .select{|entry| entry["_zone_"] == "section2" }
                        .map{|entry|  
                            {
                                "ordinal" => entry["_ordinal_"],
                                "item"    => JSON.parse(entry["_object_"])
                            }
                        }
                        .select{|st| DoNotShowUntil::isVisible(st["item"]["uuid"])}

            Catalyst::printListing(top, section1, running, section2)
        }
    end

    # Catalyst::printListing(top, section1, running, section2)
    def self.printListing(top, section1, running, section2)
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

        uuids = (section1 + section2.map{|nx| nx["item"] }).map{|item| item["uuid"] }
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
            running
                .each{|item|
                    store.register(item, true)
                    line = LxFunction::function("toString", item)
                    line = "#{store.prefixString()} #{line} (#{NxBallsService::activityStringOrEmptyString("", item["uuid"], "")})".green
                    puts line
                    vspaceleft = vspaceleft - CommonUtils::verticalSize(line)
                }
        end

        if section2.size > 0 then
            puts ""
            puts "section 2:"
            vspaceleft = vspaceleft - 2
            section2
                .each{|packet|
                    item = packet["item"]
                    store.register(item, true)
                    line = "(ord: #{"%5.2f" % packet["ordinal"]}) #{LxFunction::function("toString", item)}"
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
