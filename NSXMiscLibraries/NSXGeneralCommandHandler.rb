#!/usr/bin/ruby

# encoding: UTF-8

require 'fileutils'
# FileUtils.mkpath '/a/b/c'
# FileUtils.cp(src, dst)
# FileUtils.mv 'oldname', 'newname'
# FileUtils.rm(path_to_image)
# FileUtils.rm_rf('dir/to/remove')

# This subsystem entire purpose is to receive commands from the user and either:
	# The command is "special" and going to be captured and executed at some point along the code
	# The command is handled by an agent and the signal forwarded to the NSXCatalystObjectsOperator

class NSXGeneralCommandHandler

    # NSXGeneralCommandHandler::helpLines()
    def self.helpLines()
        [
            "catalyst --allowEmailQueriesOnLucille19",
            "Special General Commands: help , :<p> , '<p> , + , / , new: <line> | 'text' , inbox: <line> | 'text' , search: <pattern> , ,, , // , /p",
            "Special Object Commands: ,, , .. , -- , +datetimecode , +<weekdayname> , +<integer>day(s) , +<integer>hour(s) , +YYYY-MM-DD expose , planning"
        ]
    end
    
    # NSXGeneralCommandHandler::interactiveMakeNewStreamItem()
    def self.interactiveMakeNewStreamItem()
        description = LucilleCore::askQuestionAnswerAsString("description (can use 'text') or url: ")
        description = NSXMiscUtils::processItemDescriptionPossiblyAsTextEditorInvitation(description)
        genericContentsItem = 
            if description.start_with?("http") then
                NSXGenericContents::issueItemURL(description)
            else
                NSXGenericContents::issueItemText(description)
            end
        streamDescription = NSXStreamsUtils::interactivelySelectStreamDescriptionOrNull()
        streamuuid = NSXStreamsUtils::streamDescriptionToStreamUUIDOrNull(description)
        streamItem = NSXStreamsUtils::issueNewStreamItem(streamuuid, genericContentsItem, NSXMiscUtils::makeStreamItemOrdinal())
        puts JSON.pretty_generate(streamItem)
    end

    # NSXGeneralCommandHandler::processCommand(object, command)
    def self.processCommand(object, command)

        # no object needed

        if command == "" then
            return
        end

        if command == 'help' then
            puts NSXBob::agents().map{|agentdata| agentdata["agent-name"] }.join(", ")
            puts NSXGeneralCommandHandler::helpLines().join("\n")
            LucilleCore::pressEnterToContinue()
            return
        end

        if command == "+" then
            NSXMiscUtils::setStandardListingPosition(NSXMiscUtils::getStandardListingPosition()+1)
            return
        end

        if command.start_with?(":") and NSXMiscUtils::isInteger(command[1, command.size]) then
            position = command[1, command.size].strip.to_i
            NSXMiscUtils::setStandardListingPosition([position, 0].max)
            return
        end

        if command.start_with?("new:") then
            text = command[4, command.size].strip
            if text == "text" then
                text = NSXMiscUtils::editTextUsingTextmate("")
            end
            type = LucilleCore::selectEntityFromListOfEntitiesOrNull("type:", ["Stream", "Wave"])
            catalystobjectuuid = nil
            if type == "Stream" then
                genericContentsItem = NSXGenericContents::issueItemText(text)
                streamDescription = NSXStreamsUtils::interactivelySelectStreamDescriptionOrNull()
                streamuuid = NSXStreamsUtils::streamDescriptionToStreamUUIDOrNull(streamDescription)
                streamItem = NSXStreamsUtils::issueNewStreamItem(streamuuid, genericContentsItem, NSXMiscUtils::makeStreamItemOrdinal())
                puts JSON.pretty_generate(streamItem)
                catalystobjectuuid = streamItem["uuid"]
            end
            if type == "Wave" then
                catalystobjectuuid = NSXMiscUtils::spawnNewWaveItem(text)
            end
            if catalystobjectuuid then
                datecode = LucilleCore::askQuestionAnswerAsString("datecode (leave empty for nothing): ")
                datetime = NSXMiscUtils::codeToDatetimeOrNull(datecode)
                return if datetime.nil?
                NSXDoNotShowUntilDatetime::setDatetime(catalystobjectuuid, datetime)
            end
            return
        end

        if command.start_with?("inbox:") then
            text = command[6, command.size].strip
            if text == "text" then
                text = NSXMiscUtils::editTextUsingTextmate("")
            end
            genericContentsItem = NSXGenericContents::issueItemText(text)
            puts JSON.pretty_generate(genericContentsItem)
            streamItem = NSXStreamsUtils::issueNewStreamItem("03b79978bcf7a712953c5543a9df9047", genericContentsItem, NSXMiscUtils::makeStreamItemOrdinal())
            puts JSON.pretty_generate(streamItem)
            return
        end

        if command.start_with?("search:") then
            pattern = command[7, command.size].strip
            loop {
                objects = NSXCatalystObjectsOperator::getAllObjects()
                searchobjects1 = objects.select{|object| object["uuid"].downcase.include?(pattern.downcase) }
                searchobjects2 = objects.select{|object| object["announce"].downcase.include?(pattern.downcase) }
                searchobjects = searchobjects1 + searchobjects2
                status = NSXDisplayUtils::doListCalaystObjectsAndSeLectedOneObjectAndInviteAndExecuteCommand(searchobjects)
                break if !status
            }
        end

        if command == "/p" then
            options = [
                "focus",
                "new placement", 
                "destroy placement"
            ]
            option = LucilleCore::selectEntityFromListOfEntitiesOrNull("option", options)
            if option == "new placement" then
                description = LucilleCore::askQuestionAnswerAsString("description: ")
                placement = NSXPlacements::issuePlacement(description)
                puts JSON.pretty_generate(placement)
            end
            if option == "focus" then
                placement = NSXPlacements::selectPlacementOrNullInteractively()
                $GLOBAL_PLACEMENT = placement
            end
            if option == "destroy placement" then
                placement = NSXPlacements::selectPlacementOrNullInteractively()
                return if placement.nil?
                NSXPlacements::destroyPlacement(placement)
                if $GLOBAL_PLACEMENT and $GLOBAL_PLACEMENT["uuid"]==placement["uuid"] then
                    $GLOBAL_PLACEMENT = nil
                end
            end
            return
        end

        if command == "/" then
            options = [
                "new Stream Item", 
                "new wave (repeat item)", 
                "email-sync",
                "speed"
            ]
            option = LucilleCore::selectEntityFromListOfEntitiesOrNull("option", options)
            return if option.nil?
            if option == "new Stream Item" then
                NSXGeneralCommandHandler::interactiveMakeNewStreamItem()
            end
            if option == "new wave (repeat item)" then
                description = LucilleCore::askQuestionAnswerAsString("description (can use 'text'): ")
                NSXMiscUtils::spawnNewWaveItem(description)
            end
            if option == "email-sync" then
                begin
                    NSXMiscUtils::emailSync(true)
                rescue SocketError
                    puts "-> Could not retrieve emails"
                end
            end
            if option == "speed" then
                puts "Agents Speed Report"
                NSXBob::agents()
                    .map{|agentinterface| 
                        startTime = Time.new.to_f
                        agentinterface["get-objects"].call()
                        endTime = Time.new.to_f
                        timeSpanInSeconds = endTime - startTime
                        [ agentinterface["agent-name"], timeSpanInSeconds ]
                    }
                    .sort{|p1, p2| p1[1] <=> p2[1] }
                    .reverse
                    .each{|pair|
                        agentName = pair[0]
                        timeSpanInSeconds = pair[1]
                        puts "  - #{agentName}: #{timeSpanInSeconds.round(2)}"
                    }
                LucilleCore::pressEnterToContinue()
            end
            return
        end

        return if object.nil?

        # object needed

        if command == ".." and object["defaultExpression"] and object["defaultExpression"]!=".." then
            command = object["defaultExpression"]
            return NSXGeneralCommandHandler::processCommand(object, command)
        end

        if command == ',,' then
            NSXDoNotShowUntilDatetime::setDatetime(object["uuid"], NSXMiscUtils::codeToDatetimeOrNull("+2 hours"))
            return
        end

        if command == '//' then
            placement = NSXPlacements::selectPlacementOrNullInteractively()
            if placement.nil? then
                if LucilleCore::askQuestionAnswerAsBoolean("Would you like to create a new placement for this item ? ") then
                    description = LucilleCore::askQuestionAnswerAsString("description: ")
                    placement = NSXPlacements::issuePlacement(description)
                else
                    return
                end
            end
            puts JSON.pretty_generate(placement)
            claim = NSXPlacements::issuePlacementClaim(placement, object["uuid"])
            puts JSON.pretty_generate(claim)
            return
        end

        if command == 'expose' then
            puts JSON.pretty_generate(object)
            claim = NSXEmailTrackingClaims::getClaimByStreamItemUUIDOrNull(object["uuid"])
            if claim then
                puts JSON.pretty_generate(claim)
            end
            LucilleCore::pressEnterToContinue()
            return
        end

        if command == 'planning' then
            text = NSXMiscUtils::editTextUsingTextmate(NSXMiscUtils::getPlanningText(object["uuid"]))
            NSXMiscUtils::setPlanningText(object["uuid"], text)
            return
        end

        if command.start_with?('+') and (datetime = NSXMiscUtils::codeToDatetimeOrNull(command)) then
            puts "Pushing to #{datetime}"
            NSXDoNotShowUntilDatetime::setDatetime(object["uuid"], datetime)
            if object["agentuid"] == "d2de3f8e-6cf2-46f6-b122-58b60b2a96f1" then
                claim = NSXEmailTrackingClaims::getClaimByStreamItemUUIDOrNull(object["uuid"])
                if claim then
                    claim["status"] = "detached"
                    NSXEmailTrackingClaims::commitClaimToDisk(claim)
                end
            end
            return
        end

        command.split(";").map{|t| t.strip }
            .each{|command|
                agentdata = NSXBob::getAgentDataByAgentUUIDOrNull(object["agentuid"])
                next if agentdata.nil?
                agentdata["object-command-processor"].call(object, command)
            }
    end
end