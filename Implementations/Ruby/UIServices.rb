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
    # UIServices::dataPortalFront()
    def self.dataPortalFront()
        loop {
            system("clear")

            ms = LCoreMenuItemsNX1.new()

            ms.item(
                "General Search and Landing()", 
                lambda { Patricia::searchAndLanding() }
            )

            puts ""

            ms.item("Navigation Nodes",lambda { NavigationNodes::main() })

            puts ""

            ms.item("Waves", lambda { Waves::main() })

            ms.item("DxThreads", lambda { DxThreads::main() })

            ms.item(
                "Calendar",
                lambda { 
                    system("open '#{Calendar::pathToCalendarItems()}'") 
                }
            )

            puts ""

            ms.item("new datapoint", lambda {
                datapoint = Patricia::issueNewDatapointOrNull()
                return if datapoint.nil?
                Patricia::landing(datapoint)
            })

            puts ""

            ms.item("dangerously edit a nyx object by uuid", lambda { 
                uuid = LucilleCore::askQuestionAnswerAsString("uuid: ")
                return if uuid == ""
                object = NyxObjects2::getOrNull(uuid)
                return if object.nil?
                object = Miscellaneous::editTextSynchronously(JSON.pretty_generate(object))
                object = JSON.parse(object)
                NyxObjects2::put(object)
            })

            ms.item("dangerously delete a nyx object by uuid", lambda { 
                uuid = LucilleCore::askQuestionAnswerAsString("uuid: ")
                object = NyxObjects2::getOrNull(uuid)
                return if object.nil?
                puts JSON.pretty_generate(object)
                return if !LucilleCore::askQuestionAnswerAsBoolean("delete ? : ")
                NyxObjects2::destroy(object)
            })

            status = ms.promptAndRunSandbox()
            break if !status
        }
    end

    # UIServices::systemFront()
    def self.systemFront()
        loop {
            system("clear")

            ms = LCoreMenuItemsNX1.new()

            ms.item(
                "rebuild search lookup", 
                lambda { SelectionLookupDataset::rebuildDataset(true) }
            )

            ms.item(
                "NyxGarbageCollection::run()",
                lambda { NyxGarbageCollection::run() }
            )

            ms.item(
                "NyxFsck::main(runhash)",
                lambda {
                    runhash = LucilleCore::askQuestionAnswerAsString("run hash (empty to generate a random one): ")
                    if runhash == "" then
                        runhash = SecureRandom.hex
                    end
                    status = NyxFsck::main(runhash)
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

            ms.item(
                "Curation::session()", 
                lambda { Curation::session() }
            )

            status = ms.promptAndRunSandbox()
            break if !status
        }
    end

    # UIServices::standardDisplayWithPrompt()
    def self.standardDisplayWithPrompt()

        catalystObjects = CatalystObjectsOperator::getCatalystListingObjectsOrdered()

        locker = Locker.new()

        system("clear")

        verticalSpaceLeft = Miscellaneous::screenHeight()-6
        menuitems = LCoreMenuItemsNX1.new()

        puts ""

        entries = []

        # -----------------------------------------------------------
        db = SQLite3::Database.new(Bank::databaseFilepath())
        db.busy_timeout = 117  
        db.busy_handler { |count| true }
        db.results_as_hash = true
        sum = 0
        db.execute( "select sum(_weight_) as _sum_ from _operations2_ where _unixtime_ > ?" , [Time.new.to_i-86400] ) do |row|
            sum = (row["_sum_"] || 0)
        end
        db.close
        entries << "24 hours presence ratio: #{(100*sum.to_f/86400).round(2)} %".yellow
        # -----------------------------------------------------------

        puts entries.join(", ")
        verticalSpaceLeft = verticalSpaceLeft - 1

        dates =  Calendar::dates()
                    .select {|date| date <= Time.new.to_s[0, 10] }
        if dates.size > 0 then
            puts ""
            verticalSpaceLeft = verticalSpaceLeft - 1
            dates
                .each{|date|
                    next if date > Time.new.to_s[0, 10]
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
        end

        puts ""
        verticalSpaceLeft = verticalSpaceLeft - 1

        Floats::getFloatsForUIListing()
            .select{|float| float["ordinal"] }
            .sort{|f1, f2| f1["ordinal"] <=> f2["ordinal"] }
            .each{|floating|
                verticalSpaceLeft = verticalSpaceLeft - 1
                puts "[#{locker.store(floating).to_s.rjust(2)}] #{Floats::toString(floating).yellow}"
            }

        puts ""
        verticalSpaceLeft = verticalSpaceLeft - 1
        
        catalystObjects.take(5)
            .each{|object|
                str = DisplayUtils::makeDisplayStringForCatalystListing(object)
                break if (verticalSpaceLeft - DisplayUtils::verticalSize(str) < 0)
                verticalSpaceLeft = verticalSpaceLeft - DisplayUtils::verticalSize(str)
                puts "[#{locker.store(object).to_s.rjust(2)}] #{str}"
            }

        puts ""
        verticalSpaceLeft = verticalSpaceLeft - 1

        Floats::getFloatsForUIListing()
            .select{|float| float["ordinal"].nil? }
            .sort{|f1, f2| f1["unixtime"] <=> f2["unixtime"] }
            .each{|floating|
                verticalSpaceLeft = verticalSpaceLeft - 1
                puts "[#{locker.store(floating).to_s.rjust(2)}] #{Floats::toString(floating).yellow}"
            }

        puts ""
        verticalSpaceLeft = verticalSpaceLeft - 1

        DxThreads::objects()
        .sort{|dx1, dx2| DxThreads::completionRatio(dx1) <=> DxThreads::completionRatio(dx2) }
        .map {|dxthread|
            dxthread["landing"] = lambda { DxThreads::landing(dxthread) }
            dxthread["nextNaturalStep"] = lambda { DxThreads::landing(dxthread) }
            dxthread
        }
        .each{|dxthread|
            puts "[#{locker.store(dxthread).to_s.rjust(2)}] #{DxThreads::toStringWithAnalytics(dxthread)}"
            verticalSpaceLeft = verticalSpaceLeft - 1
        }

        puts ""
        verticalSpaceLeft = verticalSpaceLeft - 1

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
                "float",
                "wave",
                "datatpoint",
                "navigation point",
            ]
            operation = LucilleCore::selectEntityFromListOfEntitiesOrNull("operation", operations)
            return if operation.nil?
            if operation == "float" then
                object = Floats::issueFloatTextInteractivelyOrNull()
                puts JSON.pretty_generate(object)
                return
            end
            if operation == "wave" then
                object = Waves::issueNewWaveInteractivelyOrNull()
                Patricia::landing(object)
                return
            end
            if operation == "datatpoint" then
                object = Patricia::issueNewDatapointOrNull()
                Patricia::landing(object)
                return
            end
            if operation == "navigation point" then
                object = NavigationNodes::issueNodeInteractivelyOrNull()
                Patricia::landing(object)
                return
            end
        end
    end

    # UIServices::standardTodoListingLoop()
    def self.standardTodoListingLoop()

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
            UIServices::standardDisplayWithPrompt()
        }
    end
end


