
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
        if objects.any?{|object| object["isRunning"] } then
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
                displayStr = NSXDisplayUtils::objectToStringForCatalystListing(object, position, standardlp)
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

        if command == "" and NSXMiscUtils::objectIsDoneOnEmptyCommand(focusobject) then
            NSXGeneralCommandHandler::processCommand(focusobject, "done")
            return
        end

        if command == "done" then
            NSXGeneralCommandHandler::processCommand(focusobject, "done")
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
            if NSXMiscUtils::isLucille18() and NSXMiscUtils::trueNoMoreOftenThanNEverySeconds(nil, "632fdc97-d847-4769-b7b1-ade655cda231", 1200) then
                begin
                    NSXMiscUtils::emailSync(true)
                rescue SocketError
                    puts "-> Could not retrieve emails"
                end
            end
            if NSXMiscUtils::isLucille18() and NSXMiscUtils::trueNoMoreOftenThanNEverySeconds(nil, "cb3b93db-797f-43f6-a94d-4fbe96e490f", 3600) then
                NSXStreamsUtils::sendOrphanStreamItemsToInbox()
            end
            if NSXMiscUtils::isLucille18() and NSXMiscUtils::trueNoMoreOftenThanNEverySeconds(nil, "4021fd4d-8276-4523-b52f-491dd504e949", 86400) then
                NSXEstateServices::archivesTimelineGarbageCollection(true)
            end
            if NSXMiscUtils::isLucille18() and NSXMiscUtils::trueNoMoreOftenThanNEverySeconds(nil, "3651fd6f-1144-4dd0-85bf-1509ec71acf6", 86400) then
                NSXStreamsUtils::allStreamsItemsEnumerator()
                .each{|item|
                    next if item["emailTrackingClaim"].nil?
                    next if item["emailTrackingClaim"]["status"] != "dead"
                    next if item["emailTrackingClaim"]["lastStatusUpdateUnixtime"] < (Time.new.to_i - 86400*30) # We keep the dead ones for 30 days
                    puts JSON.pretty_generate(item)
                    NSXStreamsUtils::destroyItem(item["filename"])
                }
            end
            NSXEstateServices::collectInboxPackage()
            objects = NSXCatalystObjectsOperator::catalystObjectsForMainListing()
            NSXCatalystUI::performPrimaryDisplayWithCatalystObjects(objects)
        }
    end

end


