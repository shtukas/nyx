# encoding: UTF-8

# This variable contains the objects of the current display.
# We use it to speed up display after some operations

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

    # NSXCatalystUI::printLucilleInstanceFileAsNext()
    def self.printLucilleInstanceFileAsNext(verticalSpaceLeft)
        return 0 if verticalSpaceLeft < 6
        # this is the only moment we access NSXLucilleCalendarFileUtils
        # First we start by making sure there is only one file
        pair = NSXLucilleCalendarFileUtils::getUniqueStruct3FilepathPair()
        struct3 = pair["struct3"]
        $LUCILLE_CALENDAR_FILEPATH_44AF92E9 = pair["filepath"]
        nextContents = struct3["todo"]
                        .map{|section| section.strip }
                        .join("\n")
                        .lines
                        .to_a
                        .first([verticalSpaceLeft-3, 12].min)
                        .join()

        if nextContents.size > 0 then
            puts "-- [] " + "-" * (NSXMiscUtils::screenWidth()-7)
            puts nextContents.strip.green
            puts "-" * (NSXMiscUtils::screenWidth()-1)
            nextContents.lines.to_a.size + 2
        else
            0
        end
    end

    # NSXCatalystUI::printDisplayObjectsForListingInTwoParts(displayObjectsForListingPart, position, focusobject, verticalSpaceLeft)
    def self.printDisplayObjectsForListingInTwoParts(displayObjectsForListingPart, position, focusobject, verticalSpaceLeft)

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
            puts displayStr
            verticalSpaceLeft = verticalSpaceLeft - verticalSize
            break if verticalSpaceLeft<=0 and displayObjectsForListingPart.none?{|object| object["isRunning"] }
        end

        [position, verticalSpaceLeft, focusobject]
    end

    # NSXCatalystUI::getCutOffMetricForNextDisplay()
    def self.getCutOffMetricForNextDisplay()
        pair = NSXLucilleCalendarFileUtils::getUniqueStruct3FilepathPair()
        struct3 = pair["struct3"]
        struct3["todo"].size == 0 ? 1 : ((struct3["todo"].first.lines.first and struct3["todo"].first.lines.first.include?("@low-priority-88e84d15")) ? 0.40 : 0.60)
    end

    # NSXCatalystUI::performPrimaryDisplayWithCatalystObjects(displayObjects)
    def self.performPrimaryDisplayWithCatalystObjects(displayObjects)

        system("clear")

        verticalSpaceLeft = NSXMiscUtils::screenHeight()-2

        if displayObjects.size==0 then

            vspace = NSXCatalystUI::printLucilleInstanceFileAsNext(verticalSpaceLeft)
            verticalSpaceLeft = verticalSpaceLeft - vspace

            puts "No objects found"
            print "--> "
            command = STDIN.gets().strip
            NSXGeneralCommandHandler::processCatalystCommandManager(nil, command)
            return
        end

        focusobject = nil

        displayObjectsForListing = displayObjects.map{|object| object.clone }
        # displayObjectsForListing is being consumed while displayObjects should remain static

        # TODO: There is a better way to split this array in two parts.
        displayObjectsForListingPart1, displayObjectsForListingPart2 = displayObjectsForListing.partition { |object| object["metric"] >= NSXCatalystUI::getCutOffMetricForNextDisplay() }

        position = 0
        position, verticalSpaceLeft, focusobject = NSXCatalystUI::printDisplayObjectsForListingInTwoParts(displayObjectsForListingPart1, position, focusobject, verticalSpaceLeft)

        vspace = NSXCatalystUI::printLucilleInstanceFileAsNext(verticalSpaceLeft)
        verticalSpaceLeft = verticalSpaceLeft - vspace

        position, verticalSpaceLeft, focusobject = NSXCatalystUI::printDisplayObjectsForListingInTwoParts(displayObjectsForListingPart2, position, focusobject, verticalSpaceLeft)

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

        NSXGeneralCommandHandler::processCatalystCommandManager(focusobject, command)
    end

    # NSXCatalystUI::standardUILoop()
    def self.standardUILoop()
        loop {
            if STARTING_CODE_HASH != NSXEstateServices::locationHashRecursively(CATALYST_CODE_FOLDERPATH) then
                puts "Code change detected. Exiting."
                return
            end
            NSXEstateServices::collectInboxPackage()
            objects = NSXCatalystObjectsOperator::getCatalystListingObjectsOrdered()
            NSXCatalystUI::performPrimaryDisplayWithCatalystObjects(objects)
        }
    end
end


