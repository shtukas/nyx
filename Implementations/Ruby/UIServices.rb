# encoding: UTF-8

class DxThreadsUIUtils

    # DxThreadsUIUtils::getDxThreadStreamCardinal()
    def self.getDxThreadStreamCardinal()
        Arrows::getTargetsForSource(DxThreads::getStream()).size
    end

    # DxThreadsUIUtils::getIdealDxThreadStreamCardinal()
    def self.getIdealDxThreadStreamCardinal()
        t1 = 1611701036 # 2021-01-26 22:43:56 +0000
        y1 = 3710

        t2 = 1624747436 # 2021-06-26 22:43:56
        y2 = 100

        slope = (y2-y1).to_f/(t2-t1)

        return (Time.new.to_f - t1) * slope + y1
    end

    # DxThreadsUIUtils::runDxThreadQuarkPair(dxthread, quark)
    def self.runDxThreadQuarkPair(dxthread, quark)
        loop {
            system("clear")
            element = NereidInterface::getElementOrNull(quark["nereiduuid"])
            if element.nil? then
                system("clear")
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
            NereidInterface::access(quark["nereiduuid"])
            puts "done | landing | pause | / | (empty) for exit quark"
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
            if input == "landing" then
                Quarks::landing(quark)
                next
            end
            if input == "pause" then
                puts "paused".red
                LucilleCore::pressEnterToContinue("Press enter to resume: ")
                next
            end
            if input == "/" then
                UIServices::servicesFront()
                next
            end
            return
        }
    end

    # DxThreadsUIUtils::getDxThreadQuarkPairs(dxthread)
    def self.getDxThreadQuarkPairs(dxthread)
        Arrows::getTargetsForSource(dxthread)
            .sort{|t1, t2| Ordinals::getObjectOrdinal(t1) <=> Ordinals::getObjectOrdinal(t2) }
            .first(100)
            .map{|quark|
                {
                    "dxthread" => dxthread, 
                    "quark"    => quark
                }
            }  
    end

    # DxThreadsUIUtils::getDxThreadsUsingSelector(selector)
    def self.getDxThreadsUsingSelector(selector)
        DxThreads::getTopThreads()
            .select{|dxthread| dxthread["noDisplayOnThisDay"] != Miscellaneous::today() }   
            .select{|dxthread| selector.call(dxthread) }     
    end

    # DxThreadsUIUtils::dxThreadsToDisplayItems(dxthreads)
    def self.dxThreadsToDisplayItems(dxthreads)
        dxthreads
            .map{|dxthread|
                getDxThreadQuarkPairs(dxthread).map{|item|
                    {
                        "announce" => DxThreads::dxThreadAndTargetToString(item["dxthread"], item["quark"]),
                        "lambda"   => lambda{ runDxThreadQuarkPair(item["dxthread"], item["quark"]) }
                    }
                }
            }
            .flatten
    end
end

class UIServices

    # UIServices::selectLineOrNull(lines) : String
    def self.selectLineOrNull(lines)

        selectLines = lambda{|lines|
            linesX = lines.map{|line|
                {
                    "line"     => line,
                    "announce" => line.gsub("(", "").gsub(")", "").gsub("'", "").gsub('"', "") 
                }
            }
            announces = linesX.map{|i| i["announce"] } 
            selected = `echo '#{([""]+announces).join("\n")}' | /usr/local/bin/peco`.split("\n")
            selected.map{|announce| 
                linesX.select{|i| i["announce"] == announce }.map{|i| i["line"] }.first 
            }
            .compact
        }

        lines = selectLines.call(lines)
        if lines.size == 0 then
            return nil
        end
        if lines.size == 1 then
            return lines[0]
        end
        LucilleCore::selectEntityFromListOfEntitiesOrNull("select", lines)
    end

    # UIServices::makeDisplayStringForCatalystListing(object)
    def self.makeDisplayStringForCatalystListing(object)
        body = object["body"]
        lines = body.lines.to_a
        if lines.size == 1 then
            "#{lines.first}"
        else
            "#{lines.shift}" + lines.map{|line|  "             #{line}"}.join()
        end
    end

    # UIServices::servicesFront()
    def self.servicesFront()
        loop {
            system("clear")

            ms = LCoreMenuItemsNX1.new()

            ms.item("Calendar", lambda { Calendar::main() })

            ms.item("Waves", lambda { Waves::main() })

            ms.item("DxThreads", lambda { DxThreads::main() })

            puts ""

            ms.item("new wave", lambda { Waves::issueNewWaveInteractivelyOrNull() })            

            ms.item("new quark", lambda { Patricia::possiblyNewQuarkToPossiblyUnspecifiedDxThread(nil, nil) })    

            puts ""

            ms.item("dangerously edit a NSCoreObject by uuid", lambda { 
                uuid = LucilleCore::askQuestionAnswerAsString("uuid: ")
                return if uuid == ""
                object = NSCoreObjects::getOrNull(uuid)
                return if object.nil?
                object = Miscellaneous::editTextSynchronously(JSON.pretty_generate(object))
                object = JSON.parse(object)
                NSCoreObjects::put(object)
            })

            ms.item("dangerously delete a NSCoreObject by uuid", lambda { 
                uuid = LucilleCore::askQuestionAnswerAsString("uuid: ")
                object = NSCoreObjects::getOrNull(uuid)
                return if object.nil?
                puts JSON.pretty_generate(object)
                return if !LucilleCore::askQuestionAnswerAsBoolean("delete ? : ")
                NSCoreObjects::destroy(object)
            })

            puts ""

            ms.item("NSGarbageCollection::run()",lambda { 
                NSGarbageCollection::run() 
            })

            status = ms.promptAndRunSandbox()
            break if !status
        }
    end

    # DxThreadsUIUtils::getDisplayItemsNS16()
    def self.getDisplayItemsNS16()

        [
            Calendar::displayItemsNS16(),

            Waves::displayItemsNS16(),

            DxThreadsUIUtils::dxThreadsToDisplayItems(DxThreadsUIUtils::getDxThreadsUsingSelector( lambda { |dxthread| DxThreads::completionRatio(dxthread) < 1 } )), # Streams Below Targets

            BackupsMonitor::displayItemsNS16(),

            (lambda{
                if DxThreadsUIUtils::getIdealDxThreadStreamCardinal() < DxThreadsUIUtils::getDxThreadStreamCardinal() then
                    DxThreadsUIUtils::dxThreadsToDisplayItems(DxThreadsUIUtils::getDxThreadsUsingSelector( lambda { |dxthread| dxthread["uuid"] == "791884c9cf34fcec8c2755e6cc30dac4" } )) # Only Stream
                else
                    []
                end                
            }).call(),

            VideoStream::displayItemsNS16(),

            DxThreadsUIUtils::dxThreadsToDisplayItems(DxThreadsUIUtils::getDxThreadsUsingSelector( lambda { |dxthread| dxthread["uuid"] != "d0c8857574a1e570a27f6f6b879acc83" } )) # Reject Pascal Guardian Work
        ]
        .flatten
    end

    # UIServices::standardListingLoop()
    def self.standardListingLoop()

        KeyValueStore::set(nil, "46BEE72F-E9D2-48CC-99ED-C90E67B13DBC", DxThreads::dxthreads().map{|dxthread| DxThreads::toString(dxthread).size }.max)

        loop {

            Miscellaneous::importFromLucilleInbox()

            items = getDisplayItemsNS16()
                        .select{|item| DoNotShowUntil::isVisible(item["announce"]) }
            originSize = items.size
            time1 = Time.new

            loop {

                system("clear")

                vspaceleft = Miscellaneous::screenHeight()-5                
                hspace = Miscellaneous::screenWidth()

                puts ""

                items.take(5).each{|item|
                    next if vspaceleft <= 0
                    puts item["announce"]
                    vspaceleft = vspaceleft-((item["announce"].size/hspace)+1)
                }

                tasksFilepath = "/Users/pascal/Desktop/Tasks.txt"
                tasks = IO.read(tasksFilepath).strip
                if tasks.size > 0 then
                    text = tasks.lines.first(10).join.strip
                    puts ""
                    puts text.yellow
                    puts ""
                    vspaceleft = vspaceleft-(text.lines.to_a.size+2)
                end

                items.drop(5).each{|item|
                    next if vspaceleft <= 0
                    puts item["announce"]
                    vspaceleft = vspaceleft-((item["announce"].size/hspace)+1)
                }

                puts ""
                puts "commands: done-task | .. (access quark) | next | +datecode | ++ | select | /".red 

                input = LucilleCore::pressEnterToContinue("> ")

                if input == "done-task" then
                    Miscellaneous::applyNextTransformationToFile(tasksFilepath)
                    next
                end

                if input == ".." then
                    item = items.shift
                    puts item["announce"]
                    item["lambda"].call()
                    next
                end

                if input == "next" then
                    items.shift
                    next
                end

                if input == '++' then
                    DoNotShowUntil::setUnixtime(items[0]["announce"], Time.new.to_i+3600)
                    items.shift
                    next
                end

                if input.start_with?('+') then
                    unixtime = Miscellaneous::codeToUnixtimeOrNull(input)
                    next if unixtime.nil?
                    DoNotShowUntil::setUnixtime(items[0]["announce"], unixtime)
                    items.shift
                    next
                end

                if input == "select" then
                    system("clear")
                    item = LucilleCore::selectEntityFromListOfEntitiesOrNull("item", getDisplayItemsNS16(), lambda{|item| item["announce"] })
                    next if item.nil?
                    puts item["announce"]
                    item["lambda"].call()
                    next
                end

                if input == "/" then
                    UIServices::servicesFront()
                    next
                end

                break if items.size <= originSize/2          # We restart if we have done a bunch
                break if Time.new.to_s[0, 13] != time1.to_s[0, 13] # We restart the outter loop at each hour
            }
        }
    end

    # UIServices::main()
    def self.main()

        Quarks::quarks().each{|quark|
            if !Arrows::getSourcesForTarget(quark).any?{|parent| Patricia::isDxThread(parent) } then
                puts "Adding orphan quark to DxThread: #{Patricia::toString(quark)}"
                LucilleCore::pressEnterToContinue()
                Patricia::moveTargetToNewDxThread(quark, nil)
                exit
            end
        }

        Ordinals::getOrdinalItems().each{|item|
            if NSCoreObjects::getOrNull(item["uuid"]).nil? then
                puts "ordinals database garbage collection, unknown uuid: #{item["uuid"]}"
                LucilleCore::pressEnterToContinue()
                Ordinals::deleteRecord(item["uuid"])
            end
        }

        Thread.new {
            loop {
                sleep 1800
                if ProgrammableBooleans::trueNoMoreOftenThanEveryNSeconds("f5f52127-c140-4c59-85a2-8242b546fe1f", 3600) then
                    system("#{File.dirname(__FILE__)}/../../vienna-import")
                end
            }
        }

        UIServices::standardListingLoop()
    end
end


