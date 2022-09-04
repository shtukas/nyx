# encoding: UTF-8

class CatalystListing

    # CatalystListing::primaryCommandProcess()
    def self.primaryCommandProcess()
        puts CommandInterpreter::commands().yellow
        input = LucilleCore::askQuestionAnswerAsString("> ")
        CommandInterpreter::run(input, nil)
    end

    # CatalystListing::listingItems()
    def self.listingItems()
        items = [
            JSON.parse(`#{Config::userHomeDirectory()}/Galaxy/Binaries/fitness ns16s`),
            Anniversaries::listingItems(),
            MxPlanning::listingItems(),
            TxDateds::listingItems(),
            Waves::listingItems(true),
            TxTimeCommitmentProjects::listingItems(),
            Waves::listingItems(false),
            NxTasks::listingItems(),
            Streaming::listingItems(),
        ]
            .flatten
            .select{|item| item["isAlive"].nil? or item["isAlive"] }
            .select{|item| DoNotShowUntil::isVisible(item["uuid"]) or NxBallsService::isPresent(item["uuid"]) }
            .select{|item| InternetStatus::itemShouldShow(item["uuid"]) or NxBallsService::isPresent(item["uuid"]) }
            .select{|item| !OwnerMapping::isOwned(item["uuid"]) or NxBallsService::isPresent(item["uuid"]) }

        its1, its2 = items.partition{|item| NxBallsService::isPresent(item["uuid"]) }
        its1 + its2
    end

    # CatalystListing::program()
    def self.program()

        initialCodeTrace = CommonUtils::generalCodeTrace()

        SystemEvents::processCommsLine(true)

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
                SystemEvents::processCommsLine(true)
                SystemEvents::flushChannel1()
            }

            LucilleCore::locationsAtFolder("#{ENV['HOME']}/Desktop/Inbox")
                .each{|location|
                    next if File.basename(location).start_with?(".")
                    item = InboxItems::issueUsingLocation(location)
                    puts "Picked up from Inbox: #{JSON.pretty_generate(item)}"
                    LucilleCore::removeFileSystemLocation(location)
                }

            LucilleCore::locationsAtFolder("#{ENV['HOME']}/Desktop/NxTasks")
                .each{|location|
                    next if File.basename(location).start_with?(".")
                    item = NxTasks::issueUsingLocation(location)
                    puts "Picked up from NxTasks: #{JSON.pretty_generate(item)}"
                    LucilleCore::removeFileSystemLocation(location)
                }

            key = "8101be28-da9d-4e3d-83e6-3cee5470c59e:#{CommonUtils::today()}"
            if !XCache::getFlag(key) then
                system("clear")
                puts "frames:"
                TxFloats::items().each{|frame|
                    puts "    - #{TxFloats::toString(frame)}"
                }
                LucilleCore::pressEnterToContinue()
                XCache::setFlag(key, true)
                SystemEvents::broadcast({
                    "mikuType" => "XCacheFlag",
                    "key"      => key,
                    "flag"     => true
                })
                next
            end

            PolyPrograms::catalystMainListing()
        }
    end

    # CatalystListing::printListingLoop(announce, items)
    def self.printListingLoop(announce, items)
        loop {
            items = items
                    .map{|item| TheIndex::getItemOrNull(item["uuid"]) }
                    .compact
                    .select{|item| DoNotShowUntil::isVisible(item["uuid"]) }
                    .select{|item| InternetStatus::itemShouldShow(item["uuid"]) }
            its1, its2 = items.partition{|item| NxBallsService::isPresent(item["uuid"]) }
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
                    line = "#{store.prefixString()} #{PolyFunctions::toString(item)}"
                    if NxBallsService::isPresent(item["uuid"]) then
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

            CommandInterpreter::run(input, store)
        }
    end
end