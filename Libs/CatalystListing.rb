# encoding: UTF-8

class CatalystListing

    # CatalystListing::primaryCommandProcess()
    def self.primaryCommandProcess()
        puts CommandInterpreterDefault::commands().yellow
        input = LucilleCore::askQuestionAnswerAsString("> ")
        CommandInterpreterDefault::run(input, nil)
    end

    # CatalystListing::listingItems()
    def self.listingItems()
        items = [
            JSON.parse(`#{Config::userHomeDirectory()}/Galaxy/Binaries/fitness ns16s`),
            Anniversaries::listingItems(),
            Waves::listingItems(true),
            Waves::listingItems(false),
            TxDateds::listingItems(),
            TxTimeCommitments::listingItems(),
            NxTasks::listingItems(),
        ]
            .flatten
            .select{|item| item["isAlive"].nil? or item["isAlive"] }
            .select{|item| DoNotShowUntil::isVisible(item["uuid"]) or NxBallsService::isPresent(item["uuid"]) }
            .select{|item| InternetStatus::itemShouldShow(item["uuid"]) or NxBallsService::isPresent(item["uuid"]) }
            .select{|item| !OwnerItemsMapping::isOwned(item["uuid"]) or NxBallsService::isPresent(item["uuid"]) }

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

            PolyPrograms::catalystMainListing()
        }
    end
end