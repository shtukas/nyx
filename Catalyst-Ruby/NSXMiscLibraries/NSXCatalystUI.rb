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
        object["agentuid"] == CATALYST_INBOX_STREAMUUID and object["data"]["stream-item"]["streamuuid"] == "03b79978bcf7a712953c5543a9df9047"
    end

    # NSXCatalystUI::printLucilleInstanceFileAsNext()
    def self.printLucilleInstanceFileAsNext()
        nextContents = IO.read("/Users/pascal/Desktop/#{NSXMiscUtils::instanceName()}.txt")
                            .strip
                            .lines
                            .select{|line| line.strip.size>0 }
                            .take_while{|line| !line.start_with?(LUCILLE_FILE_MARKER) }
                            .first(10)
                            .join
        if nextContents.size>0 then
            puts "-- next " + "-" * (NSXMiscUtils::screenWidth()-9)
            puts nextContents.strip.green
            puts "-" * (NSXMiscUtils::screenWidth()-1)
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

        if displayObjects.size==0 then
            puts "No objects found"
            print "--> "
            command = STDIN.gets().strip
            NSXGeneralCommandHandler::processCatalystCommandManager(nil, command)
            return
        end

        displayObjectForListing = displayObjects.map{|object| object.clone }
        # displayObjectForListing is being consumed while displayObjects should remain static

        vspace = NSXCatalystUI::printLucilleInstanceFileAsNext()
        verticalSpaceLeft = verticalSpaceLeft - vspace

        position = 0

        while displayObjectForListing.size>0 do

            # Position management
            position = position + 1
            object = displayObjectForListing.shift
            if position == 1 then
                focusobject = object
            end
            displayStr = NSXDisplayUtils::objectDisplayStringForCatalystListing(object, position == 1, position)
            verticalSize = NSXDisplayUtils::verticalSize(displayStr)
            break if (position > 1) and (verticalSpaceLeft < verticalSize) and (displayObjectForListing + [object]).none?{|object| object["isRunning"] }

            # Display
            puts displayStr
            verticalSpaceLeft = verticalSpaceLeft - verticalSize
            break if verticalSpaceLeft<=0 and displayObjectForListing.none?{|object| object["isRunning"] }
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


