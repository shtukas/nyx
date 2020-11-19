# encoding: UTF-8

class CatalystUI

    # CatalystUI::standardDisplayWithPrompt(catalystObjects)
    def self.standardDisplayWithPrompt(catalystObjects)

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

        puts "" if catalystObjects.size > 0
        catalystObjects
            .each{|object|
                str = DisplayUtils::makeDisplayStringForCatalystListing(object)
                break if (verticalSpaceLeft - DisplayUtils::verticalSize(str) < 0)
                verticalSpaceLeft = verticalSpaceLeft - DisplayUtils::verticalSize(str)
                menuitems.item(
                    str,
                    lambda { object["landing"].call() }
                )
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
            menuitems.executeFunctionAtPositionGetValueOrNull(position)
            return
        end

        if command.size >= 3 and command[-2, 2] == ".." and Miscellaneous::isInteger(command[0, command.size-2].strip) then
            position = command[0, command.size-2].strip.to_i
            catalystObjects[position-1]["nextNaturalStep"].call()
            return
        end

        if command == 'expose' then
            object = catalystObjects.first
            return if object.nil?
            puts JSON.pretty_generate(object)
            LucilleCore::pressEnterToContinue()
            return
        end

        if command == ".." then
            object = catalystObjects.first
            return if object.nil?
            object["nextNaturalStep"].call()
            return
        end

        if command == "++" then
            object = catalystObjects.first
            return if object.nil?
            unixtime = Miscellaneous::codeToUnixtimeOrNull("+1 hours")
            puts "Pushing to #{Time.at(unixtime).to_s}"
            DoNotShowUntil::setUnixtime(object["uuid"], unixtime)
            catalystObjects = catalystObjects.drop(1)
            CatalystUI::standardDisplayWithPrompt(catalystObjects)
            return
        end

        if command.start_with?('+') and (unixtime = Miscellaneous::codeToUnixtimeOrNull(command)) then
            object = catalystObjects.first
            return if object.nil?
            puts "Pushing to #{Time.at(unixtime).to_s}"
            DoNotShowUntil::setUnixtime(object["uuid"], unixtime)
            catalystObjects = catalystObjects.drop(1)
            CatalystUI::standardDisplayWithPrompt(catalystObjects)
            return
        end

        if command == "done" then
            object = catalystObjects.first
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
            object = catalystObjects.first
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

        if command == "waves new" then
            Waves::issueNewWaveInteractivelyOrNull()
            return
        end

        if command == "asteroids new" then
            ms = LCoreMenuItemsNX1.new()
            ms.item(
                "new asteroid (line)",
                lambda { Asteroids::issueAsteroidInteractivelyOrNull() }
            )
            ms.item(
                "new asteroid (datapoint)",
                lambda { Asteroids::issueDatapointAndAsteroidInteractivelyOrNull() }
            )
            ms.promptAndRunSandbox()
            return
        end

        if command == "ordinals new" then
            ordinal = LucilleCore::askQuestionAnswerAsString("ordinal: ").to_f
            object = OrdinalPoints::issueTextPointInteractivelyOrNull(ordinal)
            puts JSON.pretty_generate(object)
            return
        end

        if command == "ordinals update" then
            points = OrdinalPoints::ordinalPoints().sort{|p1, p2| p1["ordinal"] <=> p2["ordinal"] }
            point = LucilleCore::selectEntityFromListOfEntitiesOrNull("point", points, lambda{|point| OrdinalPoints::toString(point) })
            return if point.nil?
            ordinal = LucilleCore::askQuestionAnswerAsString("ordinal: ").to_f
            point["ordinal"] = ordinal
            uuid = point["uuid"]
            filepath = "#{OrdinalPoints::repositoryPath()}/#{uuid}.json"
            File.open(filepath, "w"){|f| f.puts(JSON.pretty_generate(point)) }
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
            # Some Admin
            Miscellaneous::importFromLucilleInbox()

            # Displays
            objects = CatalystObjectsOperator::getCatalystListingObjectsOrdered()
            if objects.empty? then
                puts "No catalyst object found..."
                sleep 2
                next
            end

            CatalystUI::standardDisplayWithPrompt(objects)
        }
    end
end


