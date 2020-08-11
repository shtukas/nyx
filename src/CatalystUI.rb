# encoding: UTF-8

class CatalystUI

    # CatalystUI::applyNextTransformationToFile(filepath)
    def self.applyNextTransformationToFile(filepath)
        Miscellaneous::copyLocationToCatalystBin(filepath)
        content = IO.read(filepath).strip
        content = SectionsType0141::applyNextTransformationToContent(content)
        File.open(filepath, "w"){|f| f.puts(content) }
    end

    # CatalystUI::standardDisplay(catalystObjects)
    def self.standardDisplay(catalystObjects)

        system("clear")

        verticalSpaceLeft = Miscellaneous::screenHeight()-3
        menuitems = LCoreMenuItemsNX1.new()

        filepath = "#{Miscellaneous::catalystDataCenterFolderpath()}/Interface-Top.txt"
        text = IO.read(filepath).strip
        if text.size > 0 then
            text = text.lines.first(10).join().strip.lines.map{|line| "    #{line}" }.join()
            puts ""
            puts File.basename(filepath)
            puts text
            verticalSpaceLeft = verticalSpaceLeft - (DisplayUtils::verticalSize(text) + 2)
        end

        puts ""
        verticalSpaceLeft = verticalSpaceLeft - 1

        catalystObjects.first(5).each{|object|
            str = DisplayUtils::makeDisplayStringForCatalystListing(object)
            break if (verticalSpaceLeft - DisplayUtils::verticalSize(str) < 0)
            verticalSpaceLeft = verticalSpaceLeft - DisplayUtils::verticalSize(str)
            menuitems.item(
                str,
                lambda { object["execute"].call(nil) }
            )
        }

        dates =  Calendar::dates()
                    .select {|date| date <= Time.new.to_s[0, 10] }
        if dates.size > 0 then
            puts ""
            verticalSpaceLeft = verticalSpaceLeft - 1
            dates
                .each{|date|
                    next if date > Time.new.to_s[0, 10]
                    puts "🗓️  "+date
                    str = IO.read(Calendar::dateToFilepath(date))
                        .strip
                        .lines
                        .map{|line| "    #{line}" }
                        .join()
                    puts str
                    verticalSpaceLeft = verticalSpaceLeft - (DisplayUtils::verticalSize(str) + 1)
                }
        end

        puts ""
        verticalSpaceLeft = verticalSpaceLeft - 1

        DirectManagement::getLocations().each{|location|
            next if verticalSpaceLeft <= 0
            menuitems.item(
                DirectManagement::locationToString(location),
                lambda { DirectManagement::accessLocation(location) }
            )
            verticalSpaceLeft = verticalSpaceLeft - 1
        }

        puts ""
        verticalSpaceLeft = verticalSpaceLeft - 1

        Asteroids::asteroids()
            .select{|asteroid|
                asteroid["orbital"]["type"] == "repeating-daily-time-commitment-8123956c-05"
            }
            .sort{|a1, a2| a1["unixtime"] <=> a2["unixtime"] }
            .each{|asteroid|
                next if verticalSpaceLeft <= 0
                menuitems.item(
                    Asteroids::asteroidToString(asteroid),
                    lambda { Asteroids::landing(asteroid) }
                )
                verticalSpaceLeft = verticalSpaceLeft - 1
            }

        puts ""
        verticalSpaceLeft = verticalSpaceLeft - 1

        Asteroids::asteroids()
            .select{|asteroid|
                asteroid["orbital"]["type"] == "on-going-until-completion-5b26f145-7ebf-498"
            }
            .sort{|a1, a2| a1["unixtime"] <=> a2["unixtime"] }
            .each{|asteroid|
                next if verticalSpaceLeft <= 0
                menuitems.item(
                    Asteroids::asteroidToString(asteroid),
                    lambda { Asteroids::landing(asteroid) }
                )
                verticalSpaceLeft = verticalSpaceLeft - 1
            }

        puts ""
        verticalSpaceLeft = verticalSpaceLeft - 1

        Calendar::dates().each{|date|
            next if verticalSpaceLeft <= 0
            menuitems.item(
                "[calendar] #{date}",
                lambda { 
                    filepath = Calendar::dateToFilepath(date)
                    system("open '#{filepath}'")
                }
            )
            verticalSpaceLeft = verticalSpaceLeft - 1
        }

        puts ""
        verticalSpaceLeft = verticalSpaceLeft - 1

        Asteroids::asteroids()
            .select{|asteroid|
                asteroid["orbital"]["type"] == "open-project-in-the-background-b458aa91-6e1"
            }
            .sort{|a1, a2| a1["unixtime"] <=> a2["unixtime"] }
            .each{|asteroid|
                next if verticalSpaceLeft <= 0
                menuitems.item(
                    Asteroids::asteroidToString(asteroid),
                    lambda { Asteroids::landing(asteroid) }
                )
                verticalSpaceLeft = verticalSpaceLeft - 1
            }

        puts ""
        verticalSpaceLeft = verticalSpaceLeft - 1

        catalystObjects.drop(5).each{|object|
            str = DisplayUtils::makeDisplayStringForCatalystListing(object)
            break if (verticalSpaceLeft - DisplayUtils::verticalSize(str) < 0)
            verticalSpaceLeft = verticalSpaceLeft - DisplayUtils::verticalSize(str)
            menuitems.item(
                str,
                lambda { object["execute"].call(nil) }
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
            menuitems.executePosition(position)
            return
        end

        if command == ".." then
            object = catalystObjects.first
            return if object.nil?
            object["execute"].call("..")
            return
        end

        if command == 'expose' then
            object = catalystObjects.first
            return if object.nil?
            puts JSON.pretty_generate(object)
            LucilleCore::pressEnterToContinue()
            return
        end

        if command == "++" then
            object = catalystObjects.first
            return if object.nil?
            unixtime = Miscellaneous::codeToUnixtimeOrNull("+1 hours")
            puts "Pushing to #{Time.at(unixtime).to_s}"
            DoNotShowUntil::setUnixtime(object["uuid"], unixtime)
            return
        end

        if command.start_with?('+') and (unixtime = Miscellaneous::codeToUnixtimeOrNull(command)) then
            object = catalystObjects.first
            return if object.nil?
            puts "Pushing to #{Time.at(unixtime).to_s}"
            DoNotShowUntil::setUnixtime(object["uuid"], unixtime)
            return
        end

        if command == "::" then
            filepath = "#{Miscellaneous::catalystDataCenterFolderpath()}/Interface-Top.txt"
            system("open '#{filepath}'")
            return
        end

        if command == "[]" then
            filepath = "#{Miscellaneous::catalystDataCenterFolderpath()}/Interface-Top.txt"
            CatalystUI::applyNextTransformationToFile(filepath)
            return
        end

        if command == "l+" then
            ms = LCoreMenuItemsNX1.new()
            ms.item(
                "asteroid",
                lambda { Asteroids::issueAsteroidInteractivelyOrNull() }
            )
            ms.item(
                "wave",
                lambda { Waves::issueNewWaveInteractivelyOrNull() }
            )
            ms.prompt()
            return
        end

        if command == "/" then
            DataPortalUI::dataPortalFront()
            return
        end

        return if catalystObjects.size == 0

        catalystObjects.first["execute"].call(command)
    end

    @@haveStartedThreads = false

    # CatalystUI::startThreadsIfNotStarted()
    def self.startThreadsIfNotStarted()
        return if @@haveStartedThreads
        puts "-> starting Threads"
        Thread.new {
            loop {
                sleep 10
                CatalystObjectsOperator::getCatalystListingObjectsOrdered()
                    .select{|object| object["isRunningForLong"] }
                    .first(1)
                    .each{|object|
                        Miscellaneous::onScreenNotification("Catalyst Interface", "An object is running for long")
                    }
                sleep 120
            }
        }
        Thread.new {
            loop {
                sleep 20
                if ProgrammableBooleans::trueNoMoreOftenThanEveryNSeconds("4b5acaf4-00da-4b81-92c2-9ca6ef0c7c4a", 3600) then
                    Asteroids::asteroids()
                        .map{|asteroid| Asteroids::asteroidToCalalystObject(asteroid) }
                        .select{|object| DoNotShowUntil::isVisible(object["uuid"]) }
                        .sort{|o1, o2| o1["metric"]<=>o2["metric"] }
                        .reverse
                        .first(50)
                        .each{|object| AsteroidsOfInterest::register(object["uuid"]) }
                end
                sleep 3600
            }
        }
        Thread.new {
            loop {
                sleep 30
                if ProgrammableBooleans::trueNoMoreOftenThanEveryNSeconds("f5f52127-c140-4c59-85a2-8242b546fe1f", 3600) then
                    system("#{File.dirname(__FILE__)}/../vienna-import")
                end
                sleep 3600
            }
        }
        @@haveStartedThreads = true
    end

    # CatalystUI::standardUILoop()
    def self.standardUILoop()

        haveStartedThreads = false

        loop {

            # Some Admin
            Miscellaneous::importFromLucilleInbox()

            # Displays
            objects = CatalystObjectsOperator::getCatalystListingObjectsOrdered()
            if objects.empty? then
                puts "No catalyst object found"
                LucilleCore::pressEnterToContinue()
                return
            end
            CatalystUI::standardDisplay(objects)

            CatalystUI::startThreadsIfNotStarted()
        }
    end
end


