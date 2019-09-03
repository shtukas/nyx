# encoding: UTF-8

# This variable contains the objects of the current display.
# We use it to speed up display after some operations

class NSXCatalystUI

    # NSXCatalystUI::stringOrFirstString(content_type)
    def self.stringOrFirstString(content_type)
        if content_type.class.to_s == "String" then
            content_type
        else
            content_type.first
        end
    end

    # NSXCatalystUI::objectShouldTriggerOnScreenNotification(object)
    def self.objectShouldTriggerOnScreenNotification(object)
        object["agentuid"] == "d2de3f8e-6cf2-46f6-b122-58b60b2a96f1" and object["data"]["stream-item"]["streamuuid"] == "03b79978bcf7a712953c5543a9df9047"
    end

    # NSXCatalystUI::printLucilleInstanceFileAsNext()
    def self.printLucilleInstanceFileAsNext()
        nextContents = IO.read("/Users/pascal/Desktop/#{NSXMiscUtils::instanceName()}.txt")
                            .strip
                            .lines
                            .first(10)
                            .join
        if nextContents.size>0 then
            puts "-- next ---------------"
            puts nextContents.strip.red
            puts "-----------------------"
            nextContents.lines.to_a.size + 2
        else
            0
        end
    end

    # NSXCatalystUI::performPrimaryDisplayWithCatalystObjects(displayObjects)
    def self.performPrimaryDisplayWithCatalystObjects(displayObjects)

        system("clear")

        verticalSpaceLeft = NSXMiscUtils::screenHeight()-2

        focusobject = nil

        while displayObjects.size>0 and NSXMiscUtils::objectIsAutoDone(displayObjects.first) do
            puts "-> processing auto done".green
            NSXGeneralCommandHandler::processCommand(displayObjects.first, "done")
            displayObjects = displayObjects.drop(1)
            return
        end

        if displayObjects.size==0 then
            puts "No objects found"
            print "--> "
            command = STDIN.gets().strip
            NSXGeneralCommandHandler::processCommand(nil, command)
            return
        end

        displayObjectForListing = displayObjects.map{|object| object.clone }
        # displayObjectForListing is being consumed while displayObjects should remain static

        position = 0
        hasDisplayedCatalystNext = false
        while displayObjectForListing.size>0 do
            break if verticalSpaceLeft<=0

            if displayObjectForListing.all?{|object| object["metric"] <= 1 } and !hasDisplayedCatalystNext then
                vspace = NSXCatalystUI::printLucilleInstanceFileAsNext()
                verticalSpaceLeft = verticalSpaceLeft - vspace
                hasDisplayedCatalystNext = true
            end

            # Position management
            position = position + 1
            object = displayObjectForListing.shift
            if position == 1 then
                focusobject = object
            end
            displayStr = NSXDisplayUtils::objectDisplayStringForCatalystListing(object, position == 1, position)
            verticalSize = NSXDisplayUtils::verticalSize(displayStr)
            break if (position > 1) and (verticalSpaceLeft < verticalSize)

            # Display
            puts displayStr
            verticalSpaceLeft = verticalSpaceLeft - verticalSize
        end

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

        NSXGeneralCommandHandler::processCommand(focusobject, command)
    end

    # NSXCatalystUI::standardUILoop()
    def self.standardUILoop()
        loop {
            if STARTING_CODE_HASH != NSXEstateServices::locationHashRecursively(CATALYST_CODE_FOLDERPATH) then
                puts "Code change detected. Exiting."
                return
            end
            NSXEstateServices::collectInboxPackage()
            NSXMultiInstancesRead::processEvents()
            objects = NSXCatalystObjectsOperator::getCatalystListingObjectsOrdered()
            NSXCatalystUI::performPrimaryDisplayWithCatalystObjects(objects)
        }
    end
end


