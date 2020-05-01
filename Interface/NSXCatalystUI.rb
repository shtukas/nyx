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

require_relative "../Catalyst-Common/InFlightControlSystem/InFlightControlSystem.rb"

# ------------------------------------------------------------------------

class NSXCatalystUI

    # NSXCatalystUI::stringOrFirstString(content_type)
    def self.stringOrFirstString(content_type)
        if content_type.class.to_s == "String" then
            content_type
        else
            content_type.first
        end
    end

    # NSXCatalystUI::printDisplayObjectsForListing(displayObjectsForListing, position, focusobject, verticalSpaceLeft)
    def self.printDisplayObjectsForListing(displayObjectsForListing, position, focusobject, verticalSpaceLeft)

        lucilleHasBeenDisplayed = false

        while displayObjectsForListing.size>0 do

            # Position and Focus Management
            position = position + 1
            object = displayObjectsForListing.shift
            if position == 1 then
                focusobject = object
            end

            # Space and Priorities Management
            displayStr = NSXDisplayUtils::objectDisplayStringForCatalystListing(object, position == 1, position)
            verticalSize = NSXDisplayUtils::verticalSize(displayStr)
            break if (position > 1) and (verticalSpaceLeft < verticalSize) and (displayObjectsForListing + [object]).none?{|object| object["isRunning"] }

            # Display
            puts displayStr
            verticalSpaceLeft = verticalSpaceLeft - verticalSize

            break if verticalSpaceLeft<=0 and displayObjectsForListing.none?{|object| object["isRunning"] }
        end

        [position, verticalSpaceLeft, focusobject]
    end

    # NSXCatalystUI::performPrimaryDisplayWithCatalystObjects(displayObjects)
    def self.performPrimaryDisplayWithCatalystObjects(displayObjects)

        system("clear")

        verticalSpaceLeft = NSXMiscUtils::screenHeight()-4

        filepath = "/Users/pascal/Desktop/Lucille.txt"
        content = IO.read(filepath).split('@separation-e3cdf0ec-4119-43d8-8701-a363a74c398b')[0]
                    .strip
                    .lines
                    .first(10)
                    .map{|line| "    " + line }
                    .join()
        if content.size > 0 then
            puts "Lucille.txt 👩‍💻"
            puts content
            puts ""
            verticalSpaceLeft = verticalSpaceLeft - ( content.lines.to_a.size + 2 )
        end

        if displayObjects.size==0 then
            puts "No objects found"
            print "--> "
            command = STDIN.gets().strip
            NSXGeneralCommandHandler::processCatalystCommandManager(nil, command)
            return
        end

        focusobject = nil

        displayObjectsForListing = displayObjects.map{|object| object.clone }
        # displayObjectsForListing is being consumed while displayObjects should remain static

        puts "Catalyst 💫"
        position = 0
        position, verticalSpaceLeft, focusobject = NSXCatalystUI::printDisplayObjectsForListing(displayObjectsForListing, position, focusobject, verticalSpaceLeft)

        if focusobject.nil? then
            puts "Nothing to do for the moment (^_^)"
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

            getObjectForFocusDisplay = lambda{|selected, tail|
                return selected if tail.empty?
                if selected.empty? or tail.any?{|object| object["isRunning"] } then
                    object = tail.shift
                    selected << object
                    return getObjectForFocusDisplay.call(selected, tail)
                end
                selected
            }


            if KeyValueStore::flagIsTrue(nil, "0300c0fa-eb2c-40c7-800d-26020354d987") then
                objects = getObjectForFocusDisplay.call([], objects)
            end
            NSXCatalystUI::performPrimaryDisplayWithCatalystObjects(objects)
        }
    end
end


