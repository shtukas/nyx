# encoding: UTF-8

class UIServices

    # UIServices::servicesFront()
    def self.servicesFront()
        loop {
            system("clear")

            ms = LCoreMenuItemsNX1.new()

            ms.item("Calendar", lambda { Calendar::main() })

            ms.item("Anniversaries", lambda { Anniversaries::main() })

            ms.item("Waves", lambda { Waves::main() })

            ms.item("DxThreads", lambda { DxThreads::main() })

            puts ""

            ms.item("new wave", lambda { Waves::issueNewWaveInteractivelyOrNull() })            

            ms.item("new quark", lambda { Patricia::getQuarkPossiblyArchitectedOrNull(nil, nil) })    

            puts ""

            ms.item("dangerously edit a NSCoreObject by uuid", lambda { 
                uuid = LucilleCore::askQuestionAnswerAsString("uuid: ")
                return if uuid == ""
                object = M54::getOrNull(uuid)
                return if object.nil?
                object = CatalystUtils::editTextSynchronously(JSON.pretty_generate(object))
                object = JSON.parse(object)
                M54::put(object)
            })

            ms.item("dangerously delete a NSCoreObject by uuid", lambda { 
                uuid = LucilleCore::askQuestionAnswerAsString("uuid: ")
                object = M54::getOrNull(uuid)
                return if object.nil?
                puts JSON.pretty_generate(object)
                return if !LucilleCore::askQuestionAnswerAsBoolean("delete ? : ")
                M54::destroy(object)
            })

            puts ""

            status = ms.promptAndRunSandbox()
            break if !status
        }
    end

    # UIServices::tasksDisplayGroup(displayGroupBankUUID)
    def self.tasksDisplayGroup(displayGroupBankUUID)
        text = IO.read("/Users/pascal/Desktop/Tasks.txt").strip
        if text.size > 0 then
            text = text.lines.first(5).join().strip
        end
        dg2 = {
            "uuid"             => displayGroupBankUUID,
            "completionRatio"  => BankExtended::recoveredDailyTimeInHours(displayGroupBankUUID).to_f,
            "description"      => "Tasks.txt",
            "block"            => text.size > 0 ? text.green : nil,
            "DisplayItemsNS16" => [
                {
                    "uuid"        => "5e398b6b-fa65-4295-9893-ca5887e10d99",
                    "announce"    => "",
                    "commands"    => nil,
                    "lambda"      => lambda{
                        time1 = Time.new.to_f
                        LucilleCore::pressEnterToContinue("Press [enter] to stop Tasks.txt ")
                        time2 = Time.new.to_f
                        timespan = time2 - time1
                        puts "putting #{timespan} seconds to display group: #{displayGroupBankUUID}"
                        Bank::put(displayGroupBankUUID, timespan) 
                    }
                }
            ]
        }
    end

    # UIServices::getDisplayGroupsInOrder()
    def self.getDisplayGroupsInOrder()
        uuid = "7945614c-954a-4c7d-9847-4b67e9b28d56"
        displayItems = Calendar::displayItemsNS16() + Anniversaries::displayItemsNS16() + Waves::displayItemsNS16(uuid) + BackupsMonitor::displayItemsNS16()
        dg1 = {
            "uuid"             => uuid,
            "completionRatio"  => 0, # this always has priority
            "description"      => nil,
            "block"            => nil,
            "DisplayItemsNS16" => displayItems
        }

        dg2 = UIServices::tasksDisplayGroup("3e69fecb-0a1e-450c-8b96-a16110de5a58")

        dg3s = DxThreads::getThreadsAvailableTodayInCompletionRatioOrder()
            .map{|dxthread|
                {
                    "uuid"             => dxthread["uuid"],
                    "completionRatio"  => DxThreads::completionRatio(dxthread),
                    "description"      => DxThreads::toStringWithAnalytics(dxthread).yellow,
                    "block"            => nil,
                    "DisplayItemsNS16" => DxThreadsUIUtils::dxThreadToDisplayItemsNS16(dxthread)
                } 
            }

        uuid = "e42a45ea-d3f1-4f96-9982-096d803e2b72"
        dg4 = {
            "uuid"             => uuid,
            "completionRatio"  => BankExtended::recoveredDailyTimeInHours(uuid).to_f,
            "description"      => nil,
            "block"            => nil,
            "DisplayItemsNS16" => VideoStream::displayItemsNS16(uuid)
        }

        ([dg1]+ [dg2] + dg3s + [dg4] + [DxThreadsUIUtils::streamLateChargesDisplayItemsNS16OrNull()])
            .flatten
            .compact
            .select{|dg| dg["block"] or dg["DisplayItemsNS16"].size>0 }
            .sort{|d1, d2| d1["completionRatio"] <=> d2["completionRatio"]}
    end

    # UIServices::DG2Block(dg, vspaceleft)
    def self.DG2Block(dg, vspaceleft)
        return nil if vspaceleft <= 0
        output = ""
        if dg["description"] then
            output = output + dg["description"] + "\n"
            vspaceleft = vspaceleft - CatalystUtils::verticalSize(dg["description"])
        end
        if dg["block"] then
            output = output + dg["block"] + "\n"
            vspaceleft = vspaceleft - CatalystUtils::verticalSize(dg["block"])
        end
        dg["DisplayItemsNS16"]
            .select{|item| DoNotShowUntil::isVisible(item["uuid"]) }
            .each{|item|
                next if vspaceleft <= 0
                output = output + item["announce"] + "\n"
                vspaceleft = vspaceleft - CatalystUtils::verticalSize(item["announce"])
            }
        output.strip.lines.map.with_index{|line, indx|
            if indx == 0 then
                "[#{"%6.3f" % dg["completionRatio"]}] " + line
            else
                "         " + line
            end
            
        }
        .join
    end

    # UIServices::todoListingLoop()
    def self.todoListingLoop()

        loop {

            CatalystUtils::importFromLucilleInbox()

            Calendar::dailyBriefingIfNotDoneToday()

            Anniversaries::dailyBriefingIfNotDoneToday()

            displayGroups = UIServices::getDisplayGroupsInOrder()

            system("clear")

            vspaceleft = CatalystUtils::screenHeight()-5

            displayGroups.each{|dg|
                output = UIServices::DG2Block(dg, vspaceleft)
                next if output.nil?
                next if (vspaceleft - CatalystUtils::verticalSize(output) < 0)
                puts ""
                vspaceleft = vspaceleft - 1
                puts output
                vspaceleft = vspaceleft - CatalystUtils::verticalSize(output)
            }

            items = displayGroups
                        .map{|dg| dg["DisplayItemsNS16"] }
                        .flatten
                        .select{|item| DoNotShowUntil::isVisible(item["uuid"]) }

            puts ""
            puts "commands: [] (Tasks.txt) | .. (access top item) #default | ++ | +datecode | select | start dx | / | nyx".yellow
            if items[0] and items[0]["commands"] then
                puts "commands: #{items[0]["commands"]}".yellow
            end

            input = LucilleCore::pressEnterToContinue("> ")

            if input == ".." then
                items[0]["lambda"].call()
                next
            end

            if input == "[]" then
                CatalystUtils::applyNextTransformationToFile("/Users/pascal/Desktop/Tasks.txt")
                next
            end

            if input.start_with?("++") and input.size > 2 then
                shiftInHours = input[2, input.size].to_f
                next if shiftInHours == 0
                item = items[0]
                DoNotShowUntil::setUnixtime(item["uuid"], Time.new.to_i+3600*shiftInHours)
                next
            end

            if input == '++' then
                item = items[0]
                DoNotShowUntil::setUnixtime(item["uuid"], Time.new.to_i+3600)
                next
            end

            if input.start_with?('+') then
                item = items[0]
                unixtime = CatalystUtils::codeToUnixtimeOrNull(input)
                next if unixtime.nil?
                DoNotShowUntil::setUnixtime(item["uuid"], unixtime)
                next
            end

            if input == "select" then
                item = LucilleCore::selectEntityFromListOfEntitiesOrNull("item", items.first(CatalystUtils::screenHeight()-5), lambda{|item| item["announce"] })
                next if item.nil?
                item["lambda"].call()
                items = items.reject{|i| i["announce"] == item["announce"] }
                next
            end

            if input == "start dx" then
                dxthread = DxThreads::selectOneExistingDxThreadOrNull()
                next if dxthread.nil?
                puts "running: #{DxThreads::toString(dxthread).green}"
                time1 = Time.new.to_f
                LucilleCore::pressEnterToContinue("Press enter to exit running thread: ")
                time2 = Time.new.to_f
                timespan = time2-time1
                puts "putting #{timespan} seconds"
                Bank::put(dxthread["uuid"], timespan)
                next
            end

            if input == "/" then
                UIServices::servicesFront()
                next
            end

            if input == "nyx" then
                UIServices::nyxMain()
                next
            end
        }
    end

    # UIServices::todoListingMain()
    def self.todoListingMain()
        Thread.new {
            loop {
                sleep 120
                if ProgrammableBooleans::trueNoMoreOftenThanEveryNSeconds("f5f52127-c140-4c59-85a2-8242b546fe1f", 3600) then
                    system("#{File.dirname(__FILE__)}/../../vienna-import")
                end
            }
        }
        UIServices::todoListingLoop()
    end

    # UIServices::issueNewNyxElement()
    def self.issueNewNyxElement()
        ops = ["Nereid Element", "TimelineItem", "Curated Listing"]
        operation = LucilleCore::selectEntityFromListOfEntitiesOrNull("type", ops)
        return if operation.nil?
        if operation == "Nereid Element" then
            element = NereidInterface::interactivelyIssueNewElementOrNull()
            return if element.nil?
            NereidInterface::landing(element)
        end
        if operation == "TimelineItem" then
            event = TimelineItems::interactivelyIssueNewTimelineItemOrNull()
            return if event.nil?
            TimelineItems::landing(event)
        end
        if operation == "Curated Listing" then
            listing = CuratedListings::interactivelyIssueNewCuratedListingOrNull()
            return if listing.nil?
            TimelineItems::landing(listing)
        end
    end

    # UIServices::nyxMain()
    def self.nyxMain()
        loop {
            system("clear")
            puts "Nyx 🗺"
            ops = ["Search", "Issue New"]
            operation = LucilleCore::selectEntityFromListOfEntitiesOrNull("operation", ops)
            break if operation.nil?
            if operation == "Search" then
                Patricia::generalSearchLoop()
            end
            if operation == "Issue New" then
                UIServices::issueNewNyxElement()
            end
        }
    end
end


