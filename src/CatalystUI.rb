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

class CatalystUI

    # CatalystUI::standardDisplayWithPrompt(catalystObjects,  floatingobjects)
    def self.standardDisplayWithPrompt(catalystObjects,  floatingobjects)

        locker = Locker.new()

        system("clear")

        verticalSpaceLeft = Miscellaneous::screenHeight()-4
        menuitems = LCoreMenuItemsNX1.new()

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

        floatingobjects.each{|floating|
            verticalSpaceLeft = verticalSpaceLeft - 1
            puts "[#{locker.store(floating)}] #{Floats::toString(floating).red}"
        }

        puts ""
        
        catalystObjects
            .each{|object|
                str = DisplayUtils::makeDisplayStringForCatalystListing(object)
                break if (verticalSpaceLeft - DisplayUtils::verticalSize(str) < 0)
                verticalSpaceLeft = verticalSpaceLeft - DisplayUtils::verticalSize(str)
                puts "[#{locker.store(object)}] #{str}"
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

        if command == "done" then
            object = locker.get(1)
            return if object.nil?
            if object["done"] then
                object["done"].call()
                return
            end
            puts "I do not know how to done this object"
            puts JSON.pretty_generate(object)
            LucilleCore::pressEnterToContinue()
            return
        end

        if command == "move" then
            object = locker.get(1)
            return if object.nil?
            if object["move"] then
                object["move"].call()
                return
            end
            puts "I do not know how to move this object"
            puts JSON.pretty_generate(object)
            LucilleCore::pressEnterToContinue()
            return
        end

        if command == ":new" then
            operations = [
                "float",
                "asteroid",
                "wave",

            ]
            operation = LucilleCore::selectEntityFromListOfEntitiesOrNull("operation", operations)
            return if operation.nil?
            if operation == "float" then
                ordinal = LucilleCore::askQuestionAnswerAsString("ordinal: ").to_f
                object = Floats::issueFloatTextInteractivelyOrNull(ordinal)
                puts JSON.pretty_generate(object)
                return
            end
            if operation == "asteroid" then
                Asteroids::issueAsteroidInteractivelyOrNull()
                return
            end
            if operation == "wave" then
                Waves::issueNewWaveInteractivelyOrNull()
                return
            end
        end

        if command == ":search" then
            Patricia::searchAndLanding()
            return
        end

        if command == "/" then
            DataPortalUI::dataPortalFront()
            return
        end
    end

    # CatalystUI::standardUILoop()
    def self.standardUILoop()

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
                    system("#{File.dirname(__FILE__)}/../vienna-import")
                end
            }
        }

        loop {
            Miscellaneous::importFromLucilleInbox()

            catalystobjects = CatalystObjectsOperator::getCatalystListingObjectsOrdered()
            floatingobjects = Floats::getFloatsForUIListing()

            CatalystUI::standardDisplayWithPrompt(catalystobjects, floatingobjects)
        }
    end
end


