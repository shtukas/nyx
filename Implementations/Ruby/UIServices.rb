# encoding: UTF-8

$XStreamRunCounter = 0

class UIServices

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

            ms.item(
                "NSGarbageCollection::run()",
                lambda { NSGarbageCollection::run() }
            )

            ms.item(
                "Print Generation Speed Report", 
                lambda { CatalystObjectsOperator::generationSpeedReport() }
            )

            status = ms.promptAndRunSandbox()
            break if !status
        }
    end

    # UIServices::xStreamRun()
    def self.xStreamRun()

        time1 = Time.new

        shouldExitXStreamRun = lambda {|time1| Time.new.to_s[0, 13] != time1.to_s[0, 13] }

        Calendar::calendarItems()
            .sort{|i1, i2| i1["date"]<=>i2["date"] }
            .each{|item|
                Calendar::toString(item).yellow
            }

        DxThreads::dxthreads()
            .select{|dx| DxThreads::completionRatio(dx) < 1 }
            .sort{|dx1, dx2| DxThreads::completionRatio(dx1) <=> DxThreads::completionRatio(dx2) }
            .each{|dxthread|
                puts DxThreads::toStringWithAnalytics(dxthread).yellow
            }

        CatalystObjectsOperator::getCatalystListingObjectsOrdered()
            .each{|object|
                puts ""
                puts UIServices::makeDisplayStringForCatalystListing(object)
                object["access"].call()
                return if shouldExitXStreamRun.call(time1)
            }

        puts ""


        # processQuark: Float # returns the time spent in seconds
        processQuark = lambda {|dxthread, quark|
            element = NereidInterface::getElementOrNull(quark["nereiduuid"])
            return if element.nil?
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
            puts "done | pause | landing | / | empty for next"
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
            if input == "pause" then
                puts "paused".red
                LucilleCore::pressEnterToContinue("Press enter to resume: ")
                processQuark.call(dxthread, quark)
                return
            end
            if input == "landing" then
                NereidInterface::landing(quark["nereiduuid"])
                processQuark.call(dxthread, quark)
                return
            end
            if input == "/" then
                UIServices::servicesFront()
                processQuark.call(dxthread, quark)
                return
            end
            return
        }

        runDxThread = lambda{|dxthread, depth|
            Arrows::getTargetsForSource(dxthread)
                .sort{|t1, t2| Ordinals::getObjectOrdinal(t1) <=> Ordinals::getObjectOrdinal(t2) }
                .first(depth)
                .each{|quark|
                    $XStreamRunCounter = $XStreamRunCounter + 1
                    processQuark.call(dxthread, quark)
                    return if shouldExitXStreamRun.call(time1)
                }
        }

        DxThreads::getTopThreads()
            .each{|dxthread| runDxThread.call(dxthread, 10) }

        runDxThread.call(DxThreads::getStream(), 100)

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

        loop { UIServices::xStreamRun() }
    end
end


