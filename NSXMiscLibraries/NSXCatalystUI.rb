
# encoding: UTF-8


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

    # NSXCatalystUI::cardinalForTakingAllTheRunnings(objects)
    def self.cardinalForTakingAllTheRunnings(objects, cardinal = 0)
        objects = objects.clone
        if objects.any?{|object| object["prioritization"]=="running" } then
            NSXCatalystUI::cardinalForTakingAllTheRunnings(objects[1, objects.size], cardinal+1)
        else
            cardinal
        end
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
        
        verticalSpaceLeft = NSXMiscUtils::screenHeight()-2 # 2 for prompt and last empty line

        if displayObjects.size==0 then
            puts "No objects found"
            print "--> "
            command = STDIN.gets().strip
            NSXGeneralCommandHandler::processCommand(nil, command)
            return
        end

        performanceReportExecutableFilepath = "/Galaxy/LucilleOS/Binaries/month-performance"
        if !File.exists?(performanceReportExecutableFilepath) then
            puts "I can see the performance report executable filepath"
            LucilleCore::pressEnterToContinue()
            return
        else
            report = `#{performanceReportExecutableFilepath}`
            report = JSON.parse(report)
            if report["rent-percentage"] < 110 then
                puts "Month performance: #{report["rent-percentage"]} %".yellow
                verticalSpaceLeft = verticalSpaceLeft - 1
            end
        end

        standardlp = NSXMiscUtils::getStandardListingPosition()
        focusobject = nil

        displayObjects
            .first([NSXCatalystUI::cardinalForTakingAllTheRunnings(displayObjects), verticalSpaceLeft].max)
            .each_with_index{|object, indx|
                position = indx+1
                if (position>1 and verticalSpaceLeft<=0) then
                    next
                end
                if position == standardlp then
                    focusobject = object
                end 
                displayStr = NSXDisplayUtils::objectToStringForCatalystListing(object, position == standardlp)
                verticalSize = NSXDisplayUtils::verticalSize(displayStr)
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
        endOfPrintTime = Time.new.to_f
        command = STDIN.gets().strip
        commandTime = Time.new.to_f
        if command=='' and (commandTime - endOfPrintTime) < 0.5 then
            return
        end

        # -----------------------------------------------------------------------------------

        if command == "open" then
            NSXGeneralCommandHandler::processCommand(focusobject, "open")
            if focusobject["agentuid"] == "d2de3f8e-6cf2-46f6-b122-58b60b2a96f1" then
                focusobject = $STREAM_ITEMS_MANAGER.getItemByUUIDOrNull(focusobject["uuid"])
            end
            NSXDisplayUtils::doPresentObjectInviteAndExecuteCommand(focusobject)
            return
        end

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
            objects = NSXCatalystObjectsOperator::catalystObjectsForMainListing()
            NSXCatalystUI::performPrimaryDisplayWithCatalystObjects(objects)
        }
    end
end


