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

    # Catalyst::listingItems()
    def self.listingItems()
        items = [
            JSON.parse(`#{Config::userHomeDirectory()}/Galaxy/Binaries/fitness ns16s`),
            Anniversaries::listingItems(),
            TxDateds::listingItems(),
            Waves::listingItems(true),
            TxIncomings::listingItems(),
            NxLines::listingItems(),
            TxTimeCommitmentProjects::listingItems(),
            Waves::listingItems(false),
            NxTasks::listingItems(),
            Streaming::listingItems(),
        ]
            .flatten
            .select{|item| DoNotShowUntil::isVisible(item["uuid"]) or NxBallsService::isActive(item["uuid"]) }
            .select{|item| InternetStatus::itemShouldShow(item["uuid"]) or NxBallsService::isActive(item["uuid"]) }
            .select{|item| !OwnerMapping::isOwned(item["uuid"]) or NxBallsService::isActive(item["uuid"]) }

        its1, its2 = items.partition{|item| NxBallsService::isActive(item["uuid"]) }
        its1 + its2
    end

    # Catalyst::program()
    def self.program()

        initialCodeTrace = CommonUtils::generalCodeTrace()

        SystemEvents::processCommLine(true)

        if Config::get("instanceId") == "Lucille20-pascal" then 
            Thread.new {
                loop {
                    sleep 600
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

            $commline_semaphore.synchronize {
                SystemEvents::processCommLine(true)
            }

            LucilleCore::locationsAtFolder("#{ENV['HOME']}/Desktop/NxTasks-Top")
                .each{|location|
                    next if File.basename(location).start_with?(".")
                    item = NxTasks::issueUsingLocation(location)
                    puts "Picked up from NxTasks-Top: #{JSON.pretty_generate(item)}"
                    # Now we need to adjust the unixtime to put it on top
                    topunixtime = NxTasks::topUnixtime()
                    puts "Setting top unixtime: #{topunixtime}"
                    Fx18Attributes::setJsonEncoded(item["uuid"], "unixtime", topunixtime)
                    LucilleCore::removeFileSystemLocation(location)
                    XCache::destroy("Top-Tasks-For-Section2-7be0c69eaed3")
                }

            LucilleCore::locationsAtFolder("#{ENV['HOME']}/Desktop/NxTasks-Bottom")
                .each{|location|
                    next if File.basename(location).start_with?(".")
                    item = NxTasks::issueUsingLocation(location)
                    puts "Picked up from NxTasks-Bottom: #{JSON.pretty_generate(item)}"
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

            Catalyst::printListing()
        }
    end

    # Catalyst::printListingLoop(announce, items)
    def self.printListingLoop(announce, items)
        loop {
            items = items
                    .map{|item| Fx256::getAliveProtoItemOrNull(item["uuid"]).compact }
                    .select{|item| DoNotShowUntil::isVisible(item["uuid"]) }
                    .select{|item| InternetStatus::itemShouldShow(item["uuid"]) }
            its1, its2 = items.partition{|item| NxBallsService::isActive(item["uuid"]) }
            items = its1 + its2

            system("clear")
            
            vspaceleft = CommonUtils::screenHeight()-3

            puts ""
            puts announce
            puts ""
            vspaceleft = vspaceleft - 3

            store = ItemStore.new()

            NxBallsIO::nxballs()
                .sort{|t1, t2| t1["unixtime"] <=> t2["unixtime"] }
                .each{|nxball|
                    store.register(nxball, false)
                    line = "#{store.prefixString()} [running] #{nxball["description"]} (#{NxBallsService::activityStringOrEmptyString("", nxball["uuid"], "")})"
                    puts line.green
                    vspaceleft = vspaceleft - CommonUtils::verticalSize(line)
                }

            items
                .each{|item|
                    break if vspaceleft <= 0
                    store.register(item, true)
                    toString1 = LxFunction::function("toString", item)
                    toString2 = XCache::getOrNull("a95b9b32-cfc4-4896-b52b-e3c58b72f3ae:#{item["uuid"]}")
                    toString = toString2 ? toString2 : toString1
                    line = "#{store.prefixString()} #{toString}"
                    if NxBallsService::isActive(item["uuid"]) then
                        line = "#{line} (#{NxBallsService::activityStringOrEmptyString("", item["uuid"], "")})".green
                    end
                    puts line
                    vspaceleft = vspaceleft - CommonUtils::verticalSize(line)
                }
            puts ""
            input = LucilleCore::askQuestionAnswerAsString("> (`exit` to exit) ")

            return if input == "exit"

            if input.start_with?("+") and (unixtime = CommonUtils::codeToUnixtimeOrNull(input.gsub(" ", ""))) then
                if (item = store.getDefault()) then
                    NxBallsService::close(item["uuid"], true)
                    DoNotShowUntil::setUnixtime(item["uuid"], unixtime)
                    return
                end
            end

            Commands::run(input, store)
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

        puts ""
        vspaceleft = vspaceleft - 1

        NxBallsIO::nxballs()
            .sort{|t1, t2| t1["unixtime"] <=> t2["unixtime"] }
            .each{|nxball|
                store.register(nxball, false)
                line = "#{store.prefixString()} [running] #{nxball["description"]} (#{NxBallsService::activityStringOrEmptyString("", nxball["uuid"], "")})"
                puts line.green
                vspaceleft = vspaceleft - CommonUtils::verticalSize(line)
            }

        Catalyst::listingItems()
            .each{|item|
                break if vspaceleft <= 0
                store.register(item, true)
                toString1 = LxFunction::function("toString", item)
                toString2 = XCache::getOrNull("a95b9b32-cfc4-4896-b52b-e3c58b72f3ae:#{item["uuid"]}")
                toString = toString2 ? toString2 : toString1
                line = "#{store.prefixString()} #{toString}"
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
