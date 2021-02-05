# encoding: UTF-8

class DxThreadsUIUtils

    # DxThreadsUIUtils::getDxThreadStreamCardinal()
    def self.getDxThreadStreamCardinal()
        DxThreadQuarkMapping::getQuarkUUIDsForDxThreadInOrder(DxThreads::getStream()).size
    end

    # DxThreadsUIUtils::getIdealDxThreadStreamCardinal()
    def self.getIdealDxThreadStreamCardinal()
        t1 = 1612052387 # 2021-01-26 22:43:56 +0000
        y1 = 3728

        t2 = 1624747436 # 2021-06-26 22:43:56
        y2 = 100

        slope = (y2-y1).to_f/(t2-t1)

        return (Time.new.to_f - t1) * slope + y1
    end

    # DxThreadsUIUtils::getStreamDoneRatio()
    def self.getStreamDoneRatio()
        done = 3728 - DxThreadsUIUtils::getDxThreadStreamCardinal()
        done.to_f/(3728-100)
    end

    # DxThreadsUIUtils::runDxThreadQuarkPair(dxthread, quark)
    def self.runDxThreadQuarkPair(dxthread, quark)
        loop {
            element = NereidInterface::getElementOrNull(quark["nereiduuid"])
            if element.nil? then
                puts DxThreads::dxThreadAndTargetToString(dxthread, quark).green
                if LucilleCore::askQuestionAnswerAsBoolean("Should I delete this quark ? ") then
                    Quarks::destroyQuarkAndNereidContent(quark)
                end
                return
            end
            thr = Thread.new {
                sleep 3600
                loop {
                    Miscellaneous::onScreenNotification("Catalyst", "Item running for more than an hour")
                    sleep 60
                }
            }
            t1 = Time.new.to_f
            puts "running: #{DxThreads::dxThreadAndTargetToString(dxthread, quark).green}"
            NereidInterface::accessCatalystEdition(quark["nereiduuid"])
            puts "done (destroy quark and nereid element) | >nyx | >dxthread | landing | pause | / | (empty) for exit quark".yellow
            input = LucilleCore::askQuestionAnswerAsString("> ")
            thr.exit
            timespan = Time.new.to_f - t1
            timespan = [timespan, 3600*2].min
            puts "putting #{timespan} seconds"
            Bank::put(quark["uuid"], timespan)
            Bank::put(dxthread["uuid"], timespan)
            if input == "done" then
                Quarks::destroyQuarkAndNereidContent(quark)
                return
            end
            if input == ">nyx" then
                item = NyxPatricia::getDX7ByUUIDOrNull(quark["nereiduuid"]) 
                return if item.nil?
                NyxPatricia::dx7landing(item)
                Quarks::destroyQuark(quark)
                return
            end
            if input == ">dxthread" then
                TodoPatricia::moveTargetToNewDxThread(quark, dxthread)
                return
            end
            if input == "landing" then
                Quarks::landing(quark)
                next
            end
            if input == "pause" then
                puts "paused...".green
                LucilleCore::pressEnterToContinue("Press enter to resume: ")
                next
            end
            if input == "/" then
                TodoUIServices::servicesFront()
                next
            end
            return
        }
    end

    # DxThreadsUIUtils::getDxThreadsUsingSelector(selector)
    def self.getDxThreadsUsingSelector(selector)
        DxThreads::getTopThreads()
            .select{|dxthread| dxthread["noDisplayOnThisDay"] != Miscellaneous::today() }   
            .select{|dxthread| selector.call(dxthread) }     
    end

    # DxThreadsUIUtils::dxThreadsToDisplayItemsNS16(dxthreads)
    def self.dxThreadsToDisplayItemsNS16(dxthreads)
        dxthreads
            .map{|dxthread|
                DxThreadQuarkMapping::dxThreadToQuarksInOrder(dxthread, 20).map{|quark|
                    {
                        "uuid"                => "#{dxthread["uuid"]}:#{quark["uuid"]}",
                        "announce"            => DxThreads::dxThreadAndTargetToString(dxthread, quark),
                        "lambda"              => lambda{ runDxThreadQuarkPair(dxthread, quark) },
                        "isDxThreadQuarkPair" => true,
                        "dxthread"            => dxthread,
                        "quark"               => quark
                    }
                }
            }
            .flatten
    end

    # DxThreadsUIUtils::getLateStreamDisplayItemsNS16()
    def self.getLateStreamDisplayItemsNS16()
        if DxThreadsUIUtils::getIdealDxThreadStreamCardinal() < DxThreadsUIUtils::getDxThreadStreamCardinal() then
            DxThreadsUIUtils::dxThreadsToDisplayItemsNS16(DxThreadsUIUtils::getDxThreadsUsingSelector( lambda { |dxthread| dxthread["uuid"] == "791884c9cf34fcec8c2755e6cc30dac4" } )) # Only Stream
        else
            []
        end  
    end
end

class TodoUIServices

    # TodoUIServices::servicesFront()
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

            ms.item("new quark", lambda { TodoPatricia::getQuarkPossiblyArchitectedOrNull(nil, nil) })    

            puts ""

            ms.item("dangerously edit a NSCoreObject by uuid", lambda { 
                uuid = LucilleCore::askQuestionAnswerAsString("uuid: ")
                return if uuid == ""
                object = TodoCoreData::getOrNull(uuid)
                return if object.nil?
                object = Miscellaneous::editTextSynchronously(JSON.pretty_generate(object))
                object = JSON.parse(object)
                TodoCoreData::put(object)
            })

            ms.item("dangerously delete a NSCoreObject by uuid", lambda { 
                uuid = LucilleCore::askQuestionAnswerAsString("uuid: ")
                object = TodoCoreData::getOrNull(uuid)
                return if object.nil?
                puts JSON.pretty_generate(object)
                return if !LucilleCore::askQuestionAnswerAsBoolean("delete ? : ")
                TodoCoreData::destroy(object)
            })

            puts ""

            status = ms.promptAndRunSandbox()
            break if !status
        }
    end

    # DxThreadsUIUtils::getDisplayItemsNS16()
    def self.getDisplayItemsNS16()

        [
            Calendar::displayItemsNS16().map{|item|
                item["beforeTasks"] = true
                item
            },

            Anniversaries::displayItemsNS16().map{|item|
                item["beforeTasks"] = true
                item
            },

            Waves::displayItemsNS16().map{|item|
                item["beforeTasks"] = true
                item
            },

            DxThreadsUIUtils::dxThreadsToDisplayItemsNS16(DxThreadsUIUtils::getDxThreadsUsingSelector( lambda { |dxthread| DxThreads::completionRatio(dxthread) < 1 } )).map{|item|
                item["beforeTasks"] = true
                item
            }, # Streams Below Targets

            BackupsMonitor::displayItemsNS16(),

            DxThreadsUIUtils::getLateStreamDisplayItemsNS16(),

            #VideoStream::displayItemsNS16(),

            #DxThreadsUIUtils::dxThreadsToDisplayItemsNS16(DxThreadsUIUtils::getDxThreadsUsingSelector( lambda { |dxthread| (dxthread["uuid"] == "791884c9cf34fcec8c2755e6cc30dac4") and (DxThreads::completionRatio(dxthread) < 2)})), # Stream, ratio less than 2

            #DxThreadsUIUtils::dxThreadsToDisplayItemsNS16(DxThreadsUIUtils::getDxThreadsUsingSelector( lambda { |dxthread| (dxthread["uuid"] == "9db94deaddb8576ebda1f1fa7e6b800a") and (DxThreads::completionRatio(dxthread) < 2)})) # Jedi, ratio less than 2
        ]
        .flatten
    end

    # TodoUIServices::standardListingLoop()
    def self.standardListingLoop()

        loop {

            Miscellaneous::importFromLucilleInbox()

            Calendar::dailyBriefingIfNotDoneToday()

            Anniversaries::dailyBriefingIfNotDoneToday()

            items = getDisplayItemsNS16()
                        .select{|item| DoNotShowUntil::isVisible(item["uuid"]) }
            originSize = items.size
            time1 = Time.new

            loop {

                system("clear")

                tasksFilepath = "/Users/pascal/Desktop/Tasks.txt"
                tasksFileContents = IO.read(tasksFilepath)


                if items.size == 0 and tasksFileContents.strip == "" then
                    puts "Nothing to do. Come back later (^.^)"
                    LucilleCore::pressEnterToContinue()
                    break
                end

                vspaceleft = Miscellaneous::screenHeight()-4

                puts ""
                vspaceleft = vspaceleft - 1

                puts "☀️  Stream done: #{(DxThreadsUIUtils::getStreamDoneRatio()*100).round(2)}%".yellow
                vspaceleft = vspaceleft - 1

                DxThreads::getTopThreads()
                    .each{|dxthread|
                        puts "⛵️ #{DxThreads::toStringWithAnalytics(dxthread).yellow}"
                        vspaceleft = vspaceleft - 1
                    }

                items.take_while{|item| item["beforeTasks"]}.take(5).each{|item|
                    next if vspaceleft <= 0
                    puts item["announce"]
                    vspaceleft = vspaceleft - Miscellaneous::verticalSize(item["announce"])
                }

                tasks = tasksFileContents.strip
                if tasks.size > 0 then
                    text = tasks.lines.first(10).join.strip
                    puts text.green
                    vspaceleft = vspaceleft - Miscellaneous::verticalSize(text)
                end

                items.take_while{|item| item["beforeTasks"]}.drop(5).each{|item|
                    next if vspaceleft <= 0
                    puts item["announce"]
                    vspaceleft = vspaceleft - Miscellaneous::verticalSize(item["announce"])
                }

                items.drop_while{|item| item["beforeTasks"]}.each{|item|
                    next if vspaceleft <= 0
                    puts item["announce"]
                    vspaceleft = vspaceleft - Miscellaneous::verticalSize(item["announce"])
                }

                puts ""
                puts "commands: [] (Tasks.txt) | .. (access top item) #default | >> (skip top item) | ++ | +datecode | select | / | nyx".yellow
                if items[0] and items[0]["isDxThreadQuarkPair"] then
                    puts "commands: done (destroy quark and nereid element) | >nyx | >dxthread | landing".yellow
                end

                input = LucilleCore::pressEnterToContinue("> ")

                if input == "[]" then
                    next if tasksFileContents != IO.read(tasksFilepath)
                    Miscellaneous::applyNextTransformationToFile(tasksFilepath)
                    next
                end

                if input == ".." then
                    item = items.shift
                    item["lambda"].call()
                    next
                end

                if input == ">>" then
                    items.shift
                    next
                end

                if input == '++' then
                    item = items.shift
                    DoNotShowUntil::setUnixtime(item["uuid"], Time.new.to_i+3600)
                    next
                end

                if input.start_with?('+') then
                    item = items.shift
                    unixtime = Miscellaneous::codeToUnixtimeOrNull(input)
                    next if unixtime.nil?
                    DoNotShowUntil::setUnixtime(item["uuid"], unixtime)
                    next
                end

                if input == "select" then
                    item = LucilleCore::selectEntityFromListOfEntitiesOrNull("item", items.first(Miscellaneous::screenHeight()-5), lambda{|item| item["announce"] })
                    next if item.nil?
                    item["lambda"].call()
                    items = items.reject{|i| i["announce"] == item["announce"] }
                    next
                end

                if input == "/" then
                    TodoUIServices::servicesFront()
                    break
                end

                if input == "nyx" then
                    system("nyx")
                    break
                end

                if input == "done" then
                    item = items.shift
                    Quarks::destroyQuarkAndNereidContent(item["quark"])
                    next
                end
                if input == ">nyx" then
                    item = items.shift
                    quark = item["quark"]
                    element = NereidInterface::getElementOrNull(quark["nereiduuid"])
                    next if element.nil?
                    NyxPatricia::dx7landing(element)
                    Quarks::destroyQuark(quark)
                    next
                end
                if input == ">dxthread" then
                    item = items.shift
                    TodoPatricia::moveTargetToNewDxThread(item["quark"], item["dxthread"])
                    next
                end
                if input == "landing" then
                    item = items.shift
                    Quarks::landing(item["quark"])
                    items.shift
                    next
                end

                break if items.size <= originSize/2          # We restart if we have done a bunch
                break if Time.new.to_s[0, 13] != time1.to_s[0, 13] # We restart the outter loop at each hour
            }
        }
    end

    # TodoUIServices::main()
    def self.main()

        Thread.new {
            loop {
                sleep 120
                if ProgrammableBooleans::trueNoMoreOftenThanEveryNSeconds("f5f52127-c140-4c59-85a2-8242b546fe1f", 3600) then
                    system("#{File.dirname(__FILE__)}/../../vienna-import")
                end
            }
        }

        TodoUIServices::standardListingLoop()
    end
end


