# encoding: UTF-8

class DisplayGroups

    # DisplayGroups::tasks()
    def self.tasks()
        displayGroupUUID = "3e69fecb-0a1e-450c-8b96-a16110de5a58"
        text = IO.read("/Users/pascal/Desktop/Tasks.txt").strip
        return nil if text.start_with?("@8BFF9C08-06F6-48E0-AE8B-CD5EF6657FE4")
        if text.size > 0 then
            text = text.lines.first(5).join().strip
        end
        dg2 = {
            "uuid"             => displayGroupUUID,
            "completionRatio"  => BankExtended::recoveredDailyTimeInHours(displayGroupUUID).to_f,
            "description"      => "Tasks.txt",
            "DisplayItemsNS16" => [
                {
                    "uuid"        => "5e398b6b-fa65-4295-9893-ca5887e10d99",
                    "announce"    => text.size > 0 ? "Tasks.txt\n" + text.red.lines.map{|line| "         "+line }.join() : "",
                    "lambda"      => lambda{
                        thr = Thread.new {
                            sleep 3600
                            loop {
                                Miscellaneous::onScreenNotification("Catalyst", "Item running for more than an hour")
                                sleep 60
                            }
                        }
                        time1 = Time.new.to_f
                        LucilleCore::pressEnterToContinue("Press [enter] to stop Tasks.txt ")
                        time2 = Time.new.to_f
                        timespan = time2 - time1
                        timespan = [timespan, 3600*2].min
                        puts "putting #{timespan} seconds to display group: #{displayGroupUUID}"
                        Bank::put(displayGroupUUID, timespan)
                        thr.exit
                    }
                }
            ]
        }
    end

    # DisplayGroups::groupsInOrder()
    def self.groupsInOrder()

        # ------------------------------------------
        # Important stuff

        uuid = "7945614c-954a-4c7d-9847-4b67e9b28d56"
        displayItems = Calendar::displayItemsNS16() + Anniversaries::displayItemsNS16() + Waves::displayItemsNS16(uuid) + BackupsMonitor::displayItemsNS16()
        dg1 = {
            "uuid"             => uuid,
            "completionRatio"  => 0, # this always has priority
            "description"      => nil,
            "DisplayItemsNS16" => displayItems
        }

        # ------------------------------------------
        # Tasks.txt

        dg2 = DisplayGroups::tasks()

        # ------------------------------------------
        # Running DxThreads

        dg31s = DxThreads::dxthreads()
                .select{|dxthread| Runner::isRunning?(dxthread["uuid"])}
                .map{|dxthread|
                    {
                        "uuid"             => dxthread["uuid"],
                        "completionRatio"  => 0,
                        "description"      => nil,
                        "DisplayItemsNS16" => [
                            {
                                "uuid"        => dxthread["uuid"],
                                "announce"    => "running: #{DxThreads::toStringWithAnalytics(dxthread)}".green,
                                "lambda"      => lambda {
                                    thr = Thread.new {
                                        sleep 3600
                                        loop {
                                            Miscellaneous::onScreenNotification("Catalyst", "Item running for more than an hour")
                                            sleep 60
                                        }
                                    }
                                    if LucilleCore::askQuestionAnswerAsBoolean("We are running. Stop ? : ", true) then
                                        timespan = Runner::stop(dxthread["uuid"])
                                        timespan = [timespan, 3600*2].min
                                        puts "Adding #{timespan} seconds to #{DxThreads::toStringWithAnalytics(dxthread)}"
                                        Bank::put(dxthread["uuid"], timespan)                                
                                    end
                                    thr.exit
                                }
                            }
                        ]
                    } 
                }

        # ------------------------------------------
        # DxThreads below target

        dg32s = DxThreads::dxthreads()
                .map{|dxthread|
                    elements = DxThreadsUIUtils::dxThreadToDisplayGroupElementsOrNull(dxthread)
                    if elements then
                        completionRatio, ns16 = elements
                        {
                            "uuid"             => dxthread["uuid"],
                            "completionRatio"  => completionRatio,
                            "description"      => DxThreads::toStringWithAnalytics(dxthread).yellow,
                            "DisplayItemsNS16" => ns16
                        } 
                    else
                        nil
                    end
                }
                .compact

        # ------------------------------------------
        # VideoStream

        uuid = "e42a45ea-d3f1-4f96-9982-096d803e2b72"
        dg4 = {
            "uuid"             => uuid,
            "completionRatio"  => BankExtended::recoveredDailyTimeInHours(uuid).to_f,
            "description"      => nil,
            "DisplayItemsNS16" => VideoStream::displayItemsNS16(uuid)
        }

        ([dg1]+ [dg2] + dg31s + dg32s + [dg4])
            .flatten
            .compact
            .select{|dg| dg["DisplayItemsNS16"].size > 0 }
            .sort{|d1, d2| d1["completionRatio"] <=> d2["completionRatio"]}
    end

    # DisplayGroups::toString(dg, vspaceleft)
    def self.toString(dg, vspaceleft)
        return nil if vspaceleft <= 0
        str1 = "[#{"%6.3f" % dg["completionRatio"]}]"
        dg["DisplayItemsNS16"]
            .select{|item| DoNotShowUntil::isVisible(item["uuid"]) }
            .map{|item| "#{str1} #{item["announce"]}" }
            .join("\n")
    end
end

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

    # UIServices::todoListingOnce()
    def self.todoListingOnce()

        CatalystUtils::importFromLucilleInbox()

        Calendar::dailyBriefingIfNotDoneToday()

        Anniversaries::dailyBriefingIfNotDoneToday()

        displayGroups = DisplayGroups::groupsInOrder()

        system("clear")

        vspaceleft = CatalystUtils::screenHeight()-5

        lines = RunningItems::displayLines()
        if !lines.empty? then
            puts ""
            vspaceleft = vspaceleft - 1
            lines.each{|line|
                puts line
                vspaceleft = vspaceleft - 1
            }
        end

        puts ""

        displayGroups.each{|dg|
            output = DisplayGroups::toString(dg, vspaceleft)
            next if output.nil?
            next if (vspaceleft - CatalystUtils::verticalSize(output) < 0)
            puts output
            vspaceleft = vspaceleft - CatalystUtils::verticalSize(output)
        }

        items = displayGroups
                    .map{|dg| dg["DisplayItemsNS16"] }
                    .flatten
                    .select{|item| DoNotShowUntil::isVisible(item["uuid"]) }

        puts ""
        puts "commands: .. (access top item) (default) | select <n> | second | ++ | ++<hours> | +datecode | start | stop | [] (Tasks.txt) | / | nyx".yellow

        input = LucilleCore::pressEnterToContinue("> ")

        if input == ".." then
            items[0]["lambda"].call()
            return
        end

        if input == "[]" then
            CatalystUtils::applyNextTransformationToFile("/Users/pascal/Desktop/Tasks.txt")
            return
        end

        if input.start_with?("++") and input.size > 2 then
            shiftInHours = input[2, input.size].to_f
            return if shiftInHours == 0
            item = items[0]
            DoNotShowUntil::setUnixtime(item["uuid"], Time.new.to_i+3600*shiftInHours)
            return
        end

        if input == '++' then
            item = items[0]
            DoNotShowUntil::setUnixtime(item["uuid"], Time.new.to_i+3600)
            return
        end

        if input.start_with?('+') then
            item = items[0]
            unixtime = CatalystUtils::codeToUnixtimeOrNull(input)
            return if unixtime.nil?
            DoNotShowUntil::setUnixtime(item["uuid"], unixtime)
            return
        end

        if input.start_with?("select") then
            ordinal = input[7, 99].strip.to_i - 1
            return if ordinal < 0
            item = items[ordinal]
            return if item.nil?
            item["lambda"].call()
            return
        end

        if input == "second" then
            return if items[1].nil?
            item = items[1]
            item["lambda"].call()
            return
        end

        if input == "start" then
            dxthread = DxThreads::selectOneExistingDxThreadOrNull()
            return if dxthread.nil?
            op = LucilleCore::selectEntityFromListOfEntitiesOrNull("operation", ["Start DxThread", "Start Quark"])
            return if op.nil?
            if op == "Start DxThread" then
                RunningItems::start(DxThreads::toString(dxthread), [dxthread["uuid"]])
                return
            end
            if op == "Start Quark" then
                quarks = DxThreadQuarkMapping::dxThreadToQuarksInOrder(dxthread, DxThreads::visualisationDepth())
                quark = LucilleCore::selectEntityFromListOfEntitiesOrNull("operation", quarks, lambda{|quark| Quarks::toString(quark) })
                return if quark.nil?
                DxThreadsUIUtils::runDxThreadQuarkPair(dxthread, quark)
            end
        end

        if input == "stop" then
            item = LucilleCore::selectEntityFromListOfEntitiesOrNull("item", RunningItems::items(), lambda{|item| item["announce"] })
            return if item.nil?
            timespan = Time.new.to_f - item["start"]
            item["bankAccounts"].each{|account|
                puts "putting #{timespan} seconds to account: #{account}"
                Bank::put(account, timespan)                
            }
            RunningItems::destroy(item)
        end

        if input == "/" then
            UIServices::servicesFront()
            return
        end

        if input == "nyx" then
            UIServices::nyxMain()
            return
        end
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
        loop {
            UIServices::todoListingOnce()
        }
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


