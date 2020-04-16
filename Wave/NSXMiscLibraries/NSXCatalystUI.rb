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

class NSXCatalystUI

    # NSXCatalystUI::stringOrFirstString(content_type)
    def self.stringOrFirstString(content_type)
        if content_type.class.to_s == "String" then
            content_type
        else
            content_type.first
        end
    end

    # NSXCatalystUI::printDisplayObjectsForListing(displayObjectsForListingPart, position, focusobject, verticalSpaceLeft)
    def self.printDisplayObjectsForListing(displayObjectsForListingPart, position, focusobject, verticalSpaceLeft)

        while displayObjectsForListingPart.size>0 do

            # Position management
            position = position + 1
            object = displayObjectsForListingPart.shift
            if position == 1 then
                focusobject = object
            end
            displayStr = NSXDisplayUtils::objectDisplayStringForCatalystListing(object, position == 1, position)
            verticalSize = NSXDisplayUtils::verticalSize(displayStr)
            break if (position > 1) and (verticalSpaceLeft < verticalSize) and (displayObjectsForListingPart + [object]).none?{|object| object["isRunning"] }

            # Display
            puts "    #{displayStr}"
            verticalSpaceLeft = verticalSpaceLeft - verticalSize
            break if verticalSpaceLeft<=0 and displayObjectsForListingPart.none?{|object| object["isRunning"] }
        end

        [position, verticalSpaceLeft, focusobject]
    end

    # NSXCatalystUI::performPrimaryDisplayWithCatalystObjects(displayObjects)
    def self.performPrimaryDisplayWithCatalystObjects(displayObjects)

        system("clear")

        verticalSpaceLeft = NSXMiscUtils::screenHeight()-3

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

        puts "Wave 🌊"
        position = 0
        position, verticalSpaceLeft, focusobject = NSXCatalystUI::printDisplayObjectsForListing(displayObjectsForListing, position, focusobject, verticalSpaceLeft)

        if focusobject.nil? then
            puts "Nothing to do for the moment (^_^)"
        end

        # -----------------------------------------------------------------------------------

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

        if command == "[]" then
            system("/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/Lucille/lucille-apply-next-transformation-to-top-item-if-text")
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
            NSXCatalystUI::performPrimaryDisplayWithCatalystObjects(objects)
        }
    end
end


