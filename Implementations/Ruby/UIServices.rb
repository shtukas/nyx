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

            ms.item("Waves", lambda { Waves::main() })

            ms.item("DxThreads", lambda { DxThreads::main() })

            ms.item(
                "Calendar",
                lambda { 
                    system("open '#{Calendar::pathToCalendarItems()}'") 
                }
            )

            puts ""

            ms.item("new DxThread element", lambda {
                Patricia::issueDxThreadElement()
            })

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
        
        catalystObjects.take(5)
            .each{|object|
                str = DisplayUtils::makeDisplayStringForCatalystListing(object)
                break if (verticalSpaceLeft - DisplayUtils::verticalSize(str) < 0)
                verticalSpaceLeft = verticalSpaceLeft - DisplayUtils::verticalSize(str)
                puts "[#{locker.store(object).to_s.rjust(2)}] #{str}"
            }

        puts ""
        verticalSpaceLeft = verticalSpaceLeft - 1

        DxThreads::dxthreads()
        .sort{|dx1, dx2| DxThreads::completionRatio(dx1) <=> DxThreads::completionRatio(dx2) }
        .map {|dxthread|
            dxthread["landing"] = lambda { DxThreads::landing(dxthread) }
            dxthread["nextNaturalStep"] = lambda { DxThreads::landing(dxthread) }
            dxthread
        }
        .each{|dxthread|
            puts "[#{locker.store(dxthread).to_s.rjust(2)}] #{DxThreads::toStringWithAnalytics(dxthread)}".yellow
            verticalSpaceLeft = verticalSpaceLeft - 1
        }

        puts ""
        verticalSpaceLeft = verticalSpaceLeft - 1

        Floats::floats()
        .sort{|f1, f2| f1["unixtime"] <=> f2["unixtime"] }
        .map {|float|
            float["landing"] = lambda { Floats::landing(float) }
            float["nextNaturalStep"] = lambda { Floats::nextNaturalStep(float) }
            float
        }
        .each{|float|
            puts "[#{locker.store(float).to_s.rjust(2)}] #{Floats::toString(float)}".yellow
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

            if object["x-isFloat"] and object["::ordinal"].nil? then
                object["x-float-add-weight"].call()
            end
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
                "DxThread"
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
            if operation == "DxThread" then
                Patricia::issueDxThreadElement()
                return
            end
        end

        # :o set <ordinal> <object-position> 
        # :o set <ordinal> line <line> 
        if command.start_with?(":o") then
            command = command[2, command.size].strip
            if command.start_with?("set") then
                command = command[3, command.size].strip
                ordinal = command.to_f
                rest = command[command.index(' '), command.size].strip
                if rest.start_with?("line") then
                    line = rest[4, rest.size].strip
                    float = Floats::issueFloatText(line)
                    Ordinals::setOrdinal(float["uuid"], ordinal)
                end
                if !rest.start_with?("line") then
                    object = locker.get(rest.to_i)
                    Ordinals::setOrdinal(object["uuid"], ordinal)
                end
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
                puts "Adding orphan quark to Inbox: #{Patricia::toString(quark)}"
                dxthread = NSCoreObjects::getOrNull("f6d3e655c4b5c7ab77bb5642cd89a23b")
                Arrows::issueOrException(dxthread, quark)
                exit
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
            UIServices::standardDisplayWithPrompt()
        }
    end
end


