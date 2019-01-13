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
            "Special General Commands: help , :<p> , '<p> , + , / , new: <line> | 'text'",
            "Special General Commands: search: <pattern>",
            "Special Object Commands: ,, .. @<spotname> +datetimecode +<weekdayname> +<integer>day(s) +<integer>hour(s) +YYYY-MM-DD expose"
        ]
    end
    
    # NSXGeneralCommandHandler::interactiveMakeNewStreamItem()
    def self.interactiveMakeNewStreamItem()
        description = LucilleCore::askQuestionAnswerAsString("description (can use 'text') or url: ")
        description = NSXMiscUtils::processItemDescriptionPossiblyAsTextEditorInvitation(description)
        lightThread = NSXLightThreadUtils::interactivelySelectLightThreadOrNull()
        return if lightThread.nil?
        genericContentsItem = 
            if description.start_with?("http") then
                NSXGenericContents::issueItemURL(description)
            else
                NSXGenericContents::issueItemText(description)
            end
        streamItem = NSXStreamsUtils::issueItemAtNextOrdinalUsingGenericContentsItem(lightThread["streamuuid"], genericContentsItem)
        puts JSON.pretty_generate(streamItem)
    end

    # NSXGeneralCommandHandler::processCommand(object, command)
    def self.processCommand(object, command)

        # no object needed

        if command == "" then
            return
        end

        if ( agentdata = NSXBob::getAgentDataByAgentNameOrNull(command) ) then
            agentdata["interface"].call()
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
            type = LucilleCore::selectEntityFromListOfEntitiesOrNull("type:", ["LightThread", "Wave"])
            catalystobjectuuid = nil
            if type == "LightThread" then
                genericContentsItem = NSXGenericContents::issueItemText(text)
                pair = NSXStreamsUtils::interactivelySelectStreamUUIDAndOrdinalPairOrNull()
                return if pair.nil?
                streamuuid, ordinal = pair
                streamItem = NSXStreamsUtils::issueItemAtOrdinalUsingGenericContentsItem(streamuuid, genericContentsItem, ordinal)
                puts JSON.pretty_generate(streamItem)
                catalystobjectuuid = streamItem["uuid"][0,8]
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

        if command.start_with?("search:") then
            pattern = command[7, command.size].strip
            searchobjects1 = NSXCatalystObjectsOperator::getObjects().select{|object| object["uuid"].downcase.include?(pattern.downcase) }
            searchobjects2 = NSXCatalystObjectsOperator::getObjects().select{|object| NSXDisplayUtils::objectToOneLineForCatalystDisplay(object).downcase.include?(pattern.downcase) }
            searchobjects = searchobjects1 + searchobjects2
            NSXDisplayUtils::doListCalaystObjectsAndSeLectedOneObjectAndInviteAndExecuteCommand(searchobjects)
        end

        if command == "/" then
            options = [
                "new Stream Item", 
                "new wave (repeat item)", 
                "new LightThread",
                "LightThreads",
                "spots:activate",
                "spots:dive",
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
            if option == "new LightThread" then
                description = LucilleCore::askQuestionAnswerAsString("description: ")
                dailyTimeCommitment = NSXLightThreadUtils::dailyTimeCommitmentPickerOrNull()
                isPriorityThread = LucilleCore::askQuestionAnswerAsBoolean("Is priority ?")
                lightThread = NSXLightThreadUtils::makeNewLightThread(description, dailyTimeCommitment, isPriorityThread)
                puts JSON.pretty_generate(lightThread)
            end
            if option == "LightThreads" then
                NSXLightThreadUtils::lightThreadsDive()
            end
            if option == "spots:activate" then
                selected, _ = LucilleCore::selectZeroOrMore("spotname", [], NSXSpots::getSpotNames())
                selected.each{|spotname| NSXSpots::unblockSpotName(spotname) }
            end
            if option == "spots:dive" then
                spotnames = NSXSpots::getSpotNames()
                spotname = LucilleCore::selectEntityFromListOfEntitiesOrNull("spotname", spotnames)
                return if spotname.nil?
                objectuuids = NSXSpots::getObjectUUIDsForSpotName(spotname)
                catalystObjects = NSXCatalystObjectsOperator::objectUUIDsToCatalystObjects(objectuuids)
                NSXDisplayUtils::doListCalaystObjectsAndSeLectedOneObjectAndInviteAndExecuteCommand(catalystObjects)
            end
            if option == "email-sync" then
                NSXMiscUtils::emailSync(true)
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

        if object["commandsLambdas"] and object["commandsLambdas"][command] then
            object["commandsLambdas"][command].call(object)
            return
        end

        if command == ".." and object["defaultExpression"] and object["defaultExpression"]!=".." then
            command = object["defaultExpression"]
            return NSXGeneralCommandHandler::processCommand(object, command)
        end

        if command == ',,' then
            NSXDoNotShowUntilDatetime::setDatetime(object["uuid"], NSXMiscUtils::codeToDatetimeOrNull("+0.2 hour"))
            return
        end

        if command == 'expose' then
            puts JSON.pretty_generate(object)
            LucilleCore::pressEnterToContinue()
            return
        end

        if command.start_with?('+') and (datetime = NSXMiscUtils::codeToDatetimeOrNull(command)) then
            puts "Pushing to #{datetime}"
            NSXDoNotShowUntilDatetime::setDatetime(object["uuid"], datetime)
            return
        end

        if command.start_with?('@') then
            spotname = command[1,999].strip
            NSXSpots::issueSpotClaim(spotname, object["uuid"])
            return
        end
        
        if object["agentuid"] then
            command.split(";").map{|t| t.strip }
                .each{|command|
                    NSXBob::getAgentDataByAgentUUIDOrNull(object["agentuid"])["object-command-processor"].call(object, command)
                }
        end
    end

end