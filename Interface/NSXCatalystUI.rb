# encoding: UTF-8

# This variable contains the objects of the current display.
# We use it to speed up display after some operations

require 'digest/sha1'
# Digest::SHA1.hexdigest 'foo'
# Digest::SHA1.file(myFile).hexdigest

require "/Users/pascal/Galaxy/LucilleOS/Software-Common/Ruby-Libraries/KeyValueStore.rb"
=begin
    KeyValueStore::setFlagTrue(repositorylocation or nil, key)
    KeyValueStore::setFlagFalse(repositorylocation or nil, key)
    KeyValueStore::flagIsTrue(repositorylocation or nil, key)

    KeyValueStore::set(repositorylocation or nil, key, value)
    KeyValueStore::getOrNull(repositorylocation or nil, key)
    KeyValueStore::getOrDefaultValue(repositorylocation or nil, key, defaultValue)
    KeyValueStore::destroy(repositorylocation or nil, key)
=end

# ------------------------------------------------------------------------

class NSXCatalystUI

    # NSXCatalystUI::printDisplayObjects(sectionname, displayObjectsForListing, lowerboundmetric, position, verticalSpaceLeft)
    def self.printDisplayObjects(sectionname, displayObjectsForListing, lowerboundmetric, position, verticalSpaceLeft)

        return [displayObjectsForListing, position, verticalSpaceLeft] if displayObjectsForListing.empty?
        return [displayObjectsForListing, position, verticalSpaceLeft] if verticalSpaceLeft<=5
        return [displayObjectsForListing, position, verticalSpaceLeft] if displayObjectsForListing[0]["metric"] < lowerboundmetric

        puts ""
        puts sectionname
        verticalSpaceLeft = verticalSpaceLeft - 2

        while displayObjectsForListing.size>0 and displayObjectsForListing[0]["metric"] >= lowerboundmetric do

            # Position and Focus Management
            position = position + 1
            object = displayObjectsForListing.shift

            # Space and Priorities Management
            displayStr = NSXDisplayUtils::objectDisplayStringForCatalystListing(object, position == 1, position)
            verticalSize = NSXDisplayUtils::verticalSize(displayStr)
            break if (position > 1) and (verticalSpaceLeft < verticalSize) and (displayObjectsForListing + [object]).none?{|object| object["isRunning"] }

            # Display
            puts displayStr
            verticalSpaceLeft = verticalSpaceLeft - verticalSize

            break if verticalSpaceLeft<=0 and displayObjectsForListing.none?{|object| object["isRunning"] }
        end

        [displayObjectsForListing, position, verticalSpaceLeft]
    end

    # NSXCatalystUI::performInterfaceDisplay(displayObjects)
    def self.performInterfaceDisplay(displayObjects)

        system("clear")

        verticalSpaceLeft = NSXMiscUtils::screenHeight()-3

        # displayObjectsForListing is being consumed while displayObjects should remain static
        displayObjectsForListing = displayObjects.map{|object| object.clone }
        focusobject = displayObjectsForListing.first

        position = 0

        displayObjectsForListing, position, verticalSpaceLeft = NSXCatalystUI::printDisplayObjects("🏃‍♀️", displayObjectsForListing, 1, position, verticalSpaceLeft)

        displayObjectsForListing, position, verticalSpaceLeft = NSXCatalystUI::printDisplayObjects("🗓️", displayObjectsForListing, 0.91, position, verticalSpaceLeft)
        displayObjectsForListing, position, verticalSpaceLeft = NSXCatalystUI::printDisplayObjects("💫", displayObjectsForListing, 0.78, position, verticalSpaceLeft)

        displayObjectsForListing, position, verticalSpaceLeft = NSXCatalystUI::printDisplayObjects("In FLight Control System 🛰️", displayObjectsForListing, 0.76, position, verticalSpaceLeft)

        filepath = "/Users/pascal/Desktop/Lucille.txt"
        content = IO.read(filepath).split('@separation-e3cdf0ec-4119-43d8-8701-a363a74c398b')[0]
                    .strip
                    .lines
                    .select{|line| line.strip.size > 0 }
                    .first([10, verticalSpaceLeft].min)
                    .map{|line| "    " + line }
                    .join()
                    .rstrip
        if content.size > 0 then
            puts ""
            puts "Lucille.txt 👩‍💻"
            puts content.green
            verticalSpaceLeft = verticalSpaceLeft - ( content.lines.to_a.size + 2 )
        end

        calendarreport = `/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/Calendar/calendar-report`.strip
        if calendarreport.size > 0 and (calendarreport.lines.to_a.size + 2) < verticalSpaceLeft then
            puts ""
            puts "🗓️"
            puts calendarreport
            verticalSpaceLeft = verticalSpaceLeft - ( calendarreport.lines.to_a.size + 2 )
        end

        displayObjectsForListing, position, verticalSpaceLeft = NSXCatalystUI::printDisplayObjects("Lucille.txt [bottom] (quickly done, or postponed, or reclassified possibly as ifcs)".yellow, displayObjectsForListing, 0.73, position, verticalSpaceLeft)
        displayObjectsForListing, position, verticalSpaceLeft = NSXCatalystUI::printDisplayObjects("📬 (quickly done, or postponed, or reclassified possibly as ifcs)".yellow, displayObjectsForListing, 0.71, position, verticalSpaceLeft)

        if verticalSpaceLeft >= 2 then
            lucilleClusterReport = `/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/Lucille/lucille-cluster-report`.strip
            puts ""
            puts lucilleClusterReport
            verticalSpaceLeft = verticalSpaceLeft - 2
        end

        displayObjectsForListing, position, verticalSpaceLeft = NSXCatalystUI::printDisplayObjects("🛩️  (quickly done, or postponed, or reclassified possibly as ifcs)".yellow, displayObjectsForListing, 0.2, position, verticalSpaceLeft)

        if displayObjects.size==0 then
            puts ""
            puts "No objects found"
            print "--> "
            command = STDIN.gets().strip
            NSXGeneralCommandHandler::processCatalystCommandManager(nil, command)
            return
        end

        # -----------------------------------------------------------------------------------

        puts ""
        print "--> "
        command = STDIN.gets().strip
        if command=='' then
            return
        end

        # -----------------------------------------------------------------------------------

        if command.start_with?("'") then
            position = command[1,9].strip.to_i
            return if position==0
            return if position > displayObjects.size
            object = displayObjects[position-1]
            NSXDisplayUtils::doPresentObjectInviteAndExecuteCommand(object)
            return
        end

        if focusobject and (command == "open" or (command == '..' and focusobject["defaultCommand"] == "open")) then
            NSXGeneralCommandHandler::processCatalystCommandManager(focusobject, "open")
            NSXDisplayUtils::doPresentObjectInviteAndExecuteCommand(focusobject)
            return
        end

        NSXGeneralCommandHandler::processCatalystCommandManager(focusobject, command)
    end

    # NSXCatalystUI::standardUILoop()
    def self.standardUILoop()
        loop {
            if STARTING_CODE_HASH != NSXEstateServices::locationHashRecursively(CATALYST_CODE_FOLDERPATH) then
                puts "Code change detected. Exiting."
                return
            end
            objects = NSXCatalystObjectsOperator::getCatalystListingObjectsOrdered()
            NSXCatalystUI::performInterfaceDisplay(objects)
        }
    end
end


