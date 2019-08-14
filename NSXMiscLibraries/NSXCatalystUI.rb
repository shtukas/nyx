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

    # NSXCatalystUI::canPerformAnAsynchronousDoneWithoutRecomputingObjects(object)
    def self.canPerformAnAsynchronousDoneWithoutRecomputingObjects(object)
        return true if object["agentuid"] == "283d34dd-c871-4a55-8610-31e7c762fb0d"
        false
    end

    # NSXCatalystUI::performPrimaryDisplayWithCatalystObjects(displayObjects)
    def self.performPrimaryDisplayWithCatalystObjects(displayObjects)

        system("clear")

        while displayObjects.size>0 and NSXMiscUtils::objectIsAutoDone(displayObjects.first) do
            puts "-> processing auto done".green
            NSXGeneralCommandHandler::processCommand(displayObjects.first, "done")
            displayObjects = displayObjects.drop(1)
            return
        end

        verticalSpaceLeft = NSXMiscUtils::screenHeight()-2

        nextContents = IO.read("/Users/pascal/Desktop/Catalayst-Next.txt")
                            .strip
                            .lines
                            .first(10)
                            .join
        if nextContents.size>0 then
            puts "-- next ---------------"
            puts nextContents
            puts "-----------------------"
            verticalSpaceLeft = verticalSpaceLeft - (nextContents.lines.to_a.size + 1)
        end

        if displayObjects.size==0 then
            puts "No objects found"
            print "--> "
            command = STDIN.gets().strip
            NSXGeneralCommandHandler::processCommand(nil, command)
            return
        end

        standardlp = NSXMiscUtils::getStandardListingPosition()
        focusobject = nil

        displayObjects
            .each_with_index{|object, indx|
                position = indx+1
                if (position>1 and verticalSpaceLeft<=0) then
                    next
                end
                if position == standardlp then
                    focusobject = object
                end 

                displayStr = NSXDisplayUtils::objectDisplayStringForCatalystListing(object, position == standardlp, position)
                verticalSize = NSXDisplayUtils::verticalSize(displayStr)
                if (position > 1) and (position > standardlp) and (verticalSpaceLeft < verticalSize) then
                    break
                end
                puts displayStr
                verticalSpaceLeft = verticalSpaceLeft - verticalSize
            }

        if focusobject.nil? and (standardlp>1) then
            NSXMiscUtils::setStandardListingPosition(1)
            return
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

        if focusobject["executionLambdas"] and focusobject["executionLambdas"][command] then
            focusobject["executionLambdas"][command].call(focusobject)
            return
        end

        if command=="done" and NSXCatalystUI::canPerformAnAsynchronousDoneWithoutRecomputingObjects(focusobject) then
            Thread.new {
                NSXGeneralCommandHandler::processCommand(focusobject, "done")
            }
            NSXCatalystUI::performPrimaryDisplayWithCatalystObjects(displayObjects.reject{|o| o["uuid"] == focusobject["uuid"] })
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
            objects = NSXCatalystObjectsOperator::getCatalystListingObjectsOrdered()
            NSXCatalystUI::performPrimaryDisplayWithCatalystObjects(objects)
        }
    end
end


