# encoding: UTF-8

class Locker
    def initialize()
        @items = [nil]
    end
    def store(object)
        position = @items.size
        @items << object
        position
    end
    def get(position)
        @items[position]
    end
end

class UIServices

    # UIServices::servicesFront()
    def self.servicesFront()
        loop {
            system("clear")

            ms = LCoreMenuItemsNX1.new()

            ms.item("Calendar", lambda { Calendar::main() })

            ms.item("Waves", lambda { Waves::main() })

            ms.item("DxThreads", lambda { DxThreads::main() })

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
                "NSFsck::main(runhash)",
                lambda {
                    runhash = LucilleCore::askQuestionAnswerAsString("run hash (empty to generate a random one): ")
                    if runhash == "" then
                        runhash = SecureRandom.hex
                    end
                    status = NSFsck::main(runhash)
                    if status then
                        puts "All good".green
                    else
                        puts "Failed!".red
                    end
                    LucilleCore::pressEnterToContinue()
                }
            )

            ms.item(
                "Print Generation Speed Report", 
                lambda { CatalystObjectsOperator::generationSpeedReport() }
            )

            status = ms.promptAndRunSandbox()
            break if !status
        }
    end

    # UIServices::standardDisplayWithPrompt(catalystObjects, dates, calendarItems, dxthreads)
    def self.standardDisplayWithPrompt(catalystObjects, dates, calendarItems, dxthreads)

        locker = Locker.new()

        system("clear")

        puts ""

        verticalSpaceLeft = Miscellaneous::screenHeight()-4
        menuitems = LCoreMenuItemsNX1.new()

        dates
            .each{|date|
                puts "🗓️  "+date
                verticalSpaceLeft = verticalSpaceLeft - 1
                str = IO.read(Calendar::dateToFilepath(date))
                        .strip
                        .lines
                        .map{|line| "    #{line}" }
                        .join()
                puts str
                verticalSpaceLeft = verticalSpaceLeft - DisplayUtils::verticalSize(str)
            }
        
        catalystObjects.take(5)
            .each{|object|
                str = DisplayUtils::makeDisplayStringForCatalystListing(object)
                break if (verticalSpaceLeft - DisplayUtils::verticalSize(str) < 0)
                verticalSpaceLeft = verticalSpaceLeft - DisplayUtils::verticalSize(str)
                puts "[#{locker.store(object).to_s.rjust(2)}] #{str}"
            }

        calendarItems.each{|item|
            puts "[#{locker.store(item).to_s.rjust(2)}] #{Calendar::toString(item)}".yellow
            verticalSpaceLeft = verticalSpaceLeft - 1
        }

        dxthreads
            .each{|dxthread|
                puts "[#{locker.store(dxthread).to_s.rjust(2)}] #{DxThreads::toStringWithAnalytics(dxthread)}".yellow
                verticalSpaceLeft = verticalSpaceLeft - 1
            }

        catalystObjects.drop(5)
            .each{|object|
                str = DisplayUtils::makeDisplayStringForCatalystListing(object)
                break if (verticalSpaceLeft - DisplayUtils::verticalSize(str) < 0)
                verticalSpaceLeft = verticalSpaceLeft - DisplayUtils::verticalSize(str)
                puts "[#{locker.store(object).to_s.rjust(2)}] #{str}"
            }

        # --------------------------------------------------------------------------
        # Prompt

        puts ""
        print "--> "
        command = STDIN.gets().strip

        if command == "" then
            return
        end

        if Miscellaneous::isInteger(command) then
            position = command.to_i
            object = locker.get(position)
            return if object.nil?
            object["landing"].call()
            return
        end

        if command == 'expose' then
            object = locker.get(1)
            return if object.nil?
            puts JSON.pretty_generate(object)
            LucilleCore::pressEnterToContinue()
            return
        end

        if command == ".." then
            object = locker.get(1)
            return if object.nil?
            object["nextNaturalStep"].call()
            return
        end

        if command.size > 2 and command[-2, 2] == ".." then
            fragment = command[0, command.size-2].strip
            if Miscellaneous::isInteger(fragment) then
                position = fragment.to_i
                object = locker.get(position)
                object["nextNaturalStep"].call()
            end
            return
        end

        if command == "++" then
            object = locker.get(1)
            return if object.nil?
            unixtime = Miscellaneous::codeToUnixtimeOrNull("+1 hours")
            puts "Pushing to #{Time.at(unixtime).to_s}"
            DoNotShowUntil::setUnixtime(object["uuid"], unixtime)
            return
        end

        if command.start_with?('+') and (unixtime = Miscellaneous::codeToUnixtimeOrNull(command)) then
            object = locker.get(1)
            return if object.nil?
            puts "Pushing to #{Time.at(unixtime).to_s}"
            DoNotShowUntil::setUnixtime(object["uuid"], unixtime)
            return
        end
        
        if command == ":new" then
            operations = [
                "Calendar item",
                "wave",
                "DxThread"
            ]
            operation = LucilleCore::selectEntityFromListOfEntitiesOrNull("operation", operations)
            return if operation.nil?
            if operation == "Calendar item" then
                object = Calendar::interactivelyIssueNewCalendarItemOrNull()
                return if object.nil?
                Calendar::landing(object)
                return
            end
            if operation == "wave" then
                object = Waves::issueNewWaveInteractivelyOrNull()
                return if object.nil?
                Patricia::landing(object)
                return
            end
            if operation == "DxThread" then
                Patricia::selectDxThreadIssueNewQuark()
                return
            end
        end

        if command == "/" then
            UIServices::servicesFront()
            return
        end
    end

    # UIServices::standardTodoListingLoop()
    def self.standardTodoListingLoop()

        Quarks::quarks().each{|quark|
            if !Arrows::getSourcesForTarget(quark).any?{|parent| Patricia::isDxThread(parent) } then
                puts "Adding orphan quark to DxThread: #{Patricia::toString(quark)}"
                LucilleCore::pressEnterToContinue()
                Patricia::moveTargetToNewDxThread(quark, null)
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
                sleep 120
                CatalystObjectsOperator::getCatalystListingObjectsOrdered()
                    .select{|object| object["isRunningForLong"] }
                    .first(1)
                    .each{|object|
                        Miscellaneous::onScreenNotification("Catalyst Interface", "An object is running for long")
                    }
            }
        }

        Thread.new {
            loop {
                sleep 1800
                if ProgrammableBooleans::trueNoMoreOftenThanEveryNSeconds("f5f52127-c140-4c59-85a2-8242b546fe1f", 3600) then
                    system("#{File.dirname(__FILE__)}/../../vienna-import")
                end
            }
        }

        loop {
            Miscellaneous::importFromLucilleInbox()

            catalystObjects = CatalystObjectsOperator::getCatalystListingObjectsOrdered()
                                .select{|object| object['metric'] >= 0.21 } # to make it stop

            dates =  Calendar::dates()
                        .select {|date| date <= Time.new.to_s[0, 10] }

            calendarItems = Calendar::calendarItems()
                                .map {|item|
                                    item["landing"] = lambda { Calendar::landing(item) }
                                    item["nextNaturalStep"] = lambda { Calendar::landing(item) }
                                    item
                                }

            dxthreads = DxThreads::dxthreads()
                            .select{|dx| DxThreads::completionRatio(dx) < 1 }
                            .sort{|dx1, dx2| DxThreads::completionRatio(dx1) <=> DxThreads::completionRatio(dx2) }
                            .map {|dxthread|
                                dxthread["landing"] = lambda { DxThreads::landing(dxthread) }
                                dxthread["nextNaturalStep"] = lambda { DxThreads::landing(dxthread) }
                                dxthread
                            }

            UIServices::standardDisplayWithPrompt(catalystObjects, dates, calendarItems, dxthreads)
        }
    end
end


