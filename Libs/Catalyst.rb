# encoding: UTF-8

class Catalyst

    # Catalyst::items()
    def self.items()
        items = 
                [
                    JSON.parse(`/Users/pascal/Galaxy/LucilleOS/Binaries/fitness ns16s`),
                    Anniversaries::itemsForListing(),
                    NxFrames::listingItems(),
                    Waves::itemsForListing(true),
                    TxDateds::itemsForListing(),
                    TxProjects::items(),
                    TxQueues::itemsForMainListing(),
                    Waves::itemsForListing(false),
                    Streaming::listingItemForAnHour(),
                    NxOrdinals::itemsForListing()
                ]
                    .flatten
                    .select{|item| DoNotShowUntil::isVisible(item["uuid"]) }
                    .select{|item| InternetStatus::itemShouldShow(item["uuid"]) }

        if items.size == 0 then
            items = Streaming::listingItemInfinity()
        end

        items
    end

    # Catalyst::printListing(itemsDoneToday, runnings, top, priority, stratification)
    def self.printListing(itemsDoneToday, runnings, top, priority, stratification)
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

        running = NxBallsIO::getItems().select{|nxball| !runnings.map{|item| item["uuid"] }.include?(nxball["uuid"]) }
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

        if runnings.size > 0 then
            puts ""
            puts "runnings:"
            vspaceleft = vspaceleft - 2
            runnings
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
        #puts "(listing) 1"
        listing = Catalyst::items()

        #puts "(listing) 4"
        runnings, listing = listing.partition{|item| NxBallsService::isActive(item["uuid"]) }

        itemsDoneToday, listing = listing.partition{|item| DoneToday::isDoneToday(item["uuid"]) }

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

        # --------------------------------------------------------------------------------------------
        # stratification

        #{
        #    "ordinal"   : Float
        #    "mikuType"  : "NxStratificationItem"
        #    "item"      : Item
        #    "keepAlive" : Boolean # reset to false at start of replacement process and then to true indicating that the item has been replaced.
        #}

        # stratification : Array[NxStratificationItem]

        insert = lambda {|stratification, item, ordinal|
            ordinal = ([0] + stratification.map{|nx| nx["ordinal"]}).max + 1
            nxStratificationItem = {
                "ordinal"   => ordinal,
                "mikuType"  => "NxStratificationItem",
                "item"      => item,
                "keepAlive" => true
            }
            stratification + [nxStratificationItem]
        }

        replaceIfPresentWithKeepAliveUpdate = lambda {|stratification, item|
            stratification.map{|i|
                if i["item"]["uuid"] == item["uuid"] then
                    i["item"] = item
                    i["keepAlive"] = true
                end
                i
            }
        }

        # --------------------------------------

        stratification = JSON.parse(IO.read("/Users/pascal/Galaxy/DataBank/Stargate/catalyst-stratification.json"))

        # reset all keepAlive
        stratification = stratification.map{|item|
            item["keepAlive"] = false
            item
        }

        stratification = listing.reduce(stratification) {|strat, item|
            replaceIfPresentWithKeepAliveUpdate.call(strat, item)
        }

        stratification = stratification.select{|item| item["keepAlive"]}

        stratification = stratification.sort{|i1, i2| i1["ordinal"] <=> i2["ordinal"] }

        File.open("/Users/pascal/Galaxy/DataBank/Stargate/catalyst-stratification.json", "w") {|f| f.puts(JSON.pretty_generate(stratification)) }

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
                LxAction::action("done", item)
                return
            end

            if command.start_with?("+") and (unixtime = CommonUtils::codeToUnixtimeOrNull(command.gsub(" ", ""))) then
                NxBallsService::close(item["uuid"], true)
                DoNotShowUntil::setUnixtime(item["uuid"], unixtime)
            end

            if command == "next" then
                ordinal = ([0] + stratification.map{|nx| nx["ordinal"]}).max + 1
            end

            if ordinal.nil? then
                ordinal = command.to_f
            end

            nxStratificationItem = {
                "ordinal"   => ordinal,
                "mikuType"  => "NxStratificationItem",
                "item"      => item,
                "keepAlive" => true
            }
            stratification << nxStratificationItem

            File.open("/Users/pascal/Galaxy/DataBank/Stargate/catalyst-stratification.json", "w") {|f| f.puts(JSON.pretty_generate(stratification)) }

            return

        end

        # --------------------------------------------------------------------------------------------

        #puts "(Catalyst::printListing)"
        Catalyst::printListing(itemsDoneToday, runnings, top, priority, stratification)
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
