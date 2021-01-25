# encoding: UTF-8

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

            ms.item("Print Generation Speed Report", lambda { 
                CatalystObjectsOperator::generationSpeedReport() 
            })

            status = ms.promptAndRunSandbox()
            break if !status
        }
    end

    # UIServices::xStreamRun()
    def self.xStreamRun()

        KeyValueStore::set(nil, "46BEE72F-E9D2-48CC-99ED-C90E67B13DBC", DxThreads::dxthreads().map{|dxthread| DxThreads::toString(dxthread).size }.max)

        runDxThreadQuarkPair = lambda {|dxthread, quark|
            loop {
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
                puts "done | landing | pause | empty for exit quark"
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
                    NereidInterface::landing(quark["nereiduuid"])
                    next
                end
                if input == "pause" then
                    puts "paused".red
                    LucilleCore::pressEnterToContinue("Press enter to resume: ")
                    next
                end
                return
            }
        }

        getDisplayItemsForDxThread = lambda{|dxthread|
            Arrows::getTargetsForSource(dxthread)
                .sort{|t1, t2| Ordinals::getObjectOrdinal(t1) <=> Ordinals::getObjectOrdinal(t2) }
                .first(10)
                .map{|quark|
                    {
                        "dxthread" => dxthread, 
                        "quark"    => quark
                    }
                }            
        }

        getDisplayItems = lambda{

            items1 = getDisplayItemsForDxThread.call(DxThreads::getTopThreads()[0]).map{|item|
                {
                    "announce" => DxThreads::dxThreadAndTargetToString(item["dxthread"], item["quark"]),
                    "lambda"   => lambda{ runDxThreadQuarkPair.call(item["dxthread"], item["quark"]) }
                }                
            }

            items2 = [
                {
                    "announce" => "/ General Menu",
                    "lambda"   => lambda{ UIServices::servicesFront() }
                }
            ]

            items3 = DxThreads::getTopThreads().map{|dxthread|
                {
                    "announce" => DxThreads::toStringWithAnalytics(dxthread),
                    "lambda"   => lambda{ DxThreads::landing(dxthread, false) }
                }                
            }  

            items4 = DxThreads::getTopThreads().drop(1).map{|dxthread|
                getDisplayItemsForDxThread.call(dxthread).map{|item|
                    {
                        "announce" => DxThreads::dxThreadAndTargetToString(item["dxthread"], item["quark"]),
                        "lambda"   => lambda{ runDxThreadQuarkPair.call(item["dxthread"], item["quark"]) }
                    }                
                }
            }.flatten

            items1 + items2 + items3 + items4      
        }

        loop {

            system("clear")

            Calendar::calendarItems()
                .sort{|i1, i2| i1["date"]<=>i2["date"] }
                .each{|item|
                    Calendar::toString(item).yellow
                }

            CatalystObjectsOperator::getCatalystListingObjectsOrdered()
                .each{|object|
                    puts ""
                    puts UIServices::makeDisplayStringForCatalystListing(object)
                    object["access"].call()
                }

            puts ""

            itemsOrigin = getDisplayItems.call()
            items = itemsOrigin.clone
            time1 = Time.new
            loop {
                announce = UIServices::selectLineOrNull(items.map{|item| item["announce"] })
                item = items.select{|item| item["announce"] == announce }.first
                if item.nil? and items.size > 0 then
                    break
                end
                item["lambda"].call()
                if item["announce"].include?("[nereid]") then
                    items = items.select{|i| i["announce"] != announce } 
                end
                break if items.size <= itemsOrigin.size/2          # We restart if we have done a bunch
                break if Time.new.to_s[0, 13] != time1.to_s[0, 13] # We restart the outter loop at each hour
            }
        }

    end

    # UIServices::standardTodoListingLoop()
    def self.standardTodoListingLoop()

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

        UIServices::xStreamRun()
    end
end


