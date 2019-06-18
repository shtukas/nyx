# encoding: UTF-8

$X573751EE = []

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

    # NSXCatalystUI::performPrimaryDisplayWithCatalystObjects(displayObjects)
    def self.performPrimaryDisplayWithCatalystObjects(displayObjects)

        $X573751EE = displayObjects.map{|object| object.clone }

        system("clear")

        while displayObjects.size>0 and NSXMiscUtils::objectIsAutoDone(displayObjects.first) do
            puts "-> processing auto done".green
            NSXGeneralCommandHandler::processCommand(displayObjects.first, "done")
            displayObjects = displayObjects.drop(1)
            return
        end
        
        verticalSpaceLeft = NSXMiscUtils::screenHeight()-2

        if displayObjects.size==0 then
            puts "No objects found"
            print "--> "
            command = STDIN.gets().strip
            NSXGeneralCommandHandler::processCommand(nil, command)
            return
        end

        performanceReportExecutableFilepath = "/Galaxy/LucilleOS/Binaries/month-performance"
        if !File.exists?(performanceReportExecutableFilepath) then
            puts "[error:4206ef88] I can't see the performance report executable filepath"
            exit
        else
            report = `#{performanceReportExecutableFilepath}`.strip
            if report.size==0 then
                puts "[error:b87d8617] I can't get the performance report"
                exit
            else
                report = JSON.parse(report)
                if report["rent-percentage"] < 110 then
                    puts "Month performance: #{report["rent-percentage"]} %".yellow
                    verticalSpaceLeft = verticalSpaceLeft - 1
                end
            end
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

                displayStr = NSXDisplayUtils::objectCatalystListingDisplayString(object, position == standardlp, position)
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

        if command == ",," then
            NSXMiscUtils::resetMetricWeightRatio(focusobject["uuid"])
            $X573751EE = $X573751EE.reject{|object| object["uuid"]==focusobject["uuid"] }
            return if $X573751EE.size==0
            displayObjects = $X573751EE.map{|object| object.clone }
            NSXCatalystUI::performPrimaryDisplayWithCatalystObjects(displayObjects)
            return
        end

        if command == "open" then
            NSXGeneralCommandHandler::processCommand(focusobject, "open")
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
            objects = NSXCatalystObjectsOperator::getCatalystListingObjectsOrdered()
            NSXCatalystUI::performPrimaryDisplayWithCatalystObjects(objects)
        }
    end
end


