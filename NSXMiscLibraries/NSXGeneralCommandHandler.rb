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
            "Special General Commands:",
            "\n",
            [
                "help",
                "/", 
                "new: <line> | 'text'", 
                "next",
                "search: <pattern>",
            ].map{|command| "        "+command }.join("\n"),
            "\n",
            "Special Object Commands:",
            "\n",
            ["..", "+datetimecode", "+<weekdayname>", "+<integer>day(s)", "+<integer>hour(s)", "+YYYY-MM-DD", "+1@23:45", "expose", "x-note"].map{|command| "        "+command }.join("\n")
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
        streamItem = NSXStreamsUtils::issueNewStreamItem(streamuuid, genericContentsItem, NSXMiscUtils::makeEndOfQueueStreamItemOrdinal())
        puts JSON.pretty_generate(streamItem)
    end

    # NSXGeneralCommandHandler::processCatalystGeneralCommand(command): Boolean 
    # The return value indicates whether the command was executed.
    def self.processCatalystGeneralCommand(command)

        if command == "" then
            return true
        end

        if command == 'help' then
            puts NSXGeneralCommandHandler::helpLines().join()
            LucilleCore::pressEnterToContinue()
            return true
        end

        if command.start_with?("new:") then
            text = command[4, command.size].strip
            if text == "" then
                text = LucilleCore::askQuestionAnswerAsString("description (use 'text' for editor): ")
            end
            if text == "text" then
                text = NSXMiscUtils::editTextUsingTextmate("")
            end
            type = LucilleCore::selectEntityFromListOfEntitiesOrNull("type:", ["Stream:Inbox", "Stream", "Wave"])
            catalystobjectuuid = nil
            if type == "Stream:Inbox" then
                genericContentsItem = NSXGenericContents::issueItemText(text)
                puts JSON.pretty_generate(genericContentsItem)
                streamItem = NSXStreamsUtils::issueNewStreamItem("03b79978bcf7a712953c5543a9df9047", genericContentsItem, NSXMiscUtils::makeEndOfQueueStreamItemOrdinal())
                puts JSON.pretty_generate(streamItem)
                catalystobjectuuid = streamItem["uuid"]
            end
            if type == "Stream" then
                streamDescription = NSXStreamsUtils::interactivelySelectStreamDescriptionOrNull()
                streamuuid = NSXStreamsUtils::streamDescriptionToStreamUUIDOrNull(streamDescription)
                streamItemOrdinal = NSXStreamsUtils::interactivelySpecifyStreamItemOrdinal(streamuuid)
                genericContentsItem = NSXGenericContents::issueItemText(text)
                streamItem = NSXStreamsUtils::issueNewStreamItem(streamuuid, genericContentsItem, streamItemOrdinal)
                puts JSON.pretty_generate(streamItem)
                catalystobjectuuid = streamItem["uuid"]
            end
            if type == "Wave" then
                catalystobjectuuid = NSXMiscUtils::spawnNewWaveItem(text)
            end
            return true
        end

        if command.start_with?("search:") then
            pattern = command[7, command.size].strip
            loop {
                objects = NSXCatalystObjectsOperator::getAllObjectsFromAgents()
                searchobjects1 = objects.select{|object| object["uuid"].downcase.include?(pattern.downcase) }
                searchobjects2 = objects.select{|object| NSXContentStoreUtils::contentStoreItemIdToAnnounceOrNull(object['contentStoreItemId']).downcase.include?(pattern.downcase) }
                searchobjects = searchobjects1 + searchobjects2
                status = NSXDisplayUtils::doListCalaystObjectsAndSeLectedOneObjectAndInviteAndExecuteCommand(searchobjects)
                break if !status
            }
            return true
        end

        if command == "/" then
            options = [
                "new Stream Item", 
                "new wave (repeat item)", 
                "email-sync",
                "agent-speed",
                "set no internet for this hour"
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
            if option == "agent-speed" then
                puts "Agent speed report"
                NSXMiscUtils::agentsSpeedReport().reverse.each{|object|
                    puts "    - #{object["agent-name"]}: #{"%.3f" % object["retreive-time"]}"
                }
                LucilleCore::pressEnterToContinue()
            end
            if option == "set no internet for this hour" then
                NSXMiscUtils::setNoInternetForThisHour()
            end
            return true
        end

        if command == "next" then
            # Get rid of the first inner line of the Next file
            NSXMiscUtils::applyNextTransformationToLucilleInstanceFile()
            return true
        end

        false
    end

    # NSXGeneralCommandHandler::processCatalystObjectMetaCommand(object, command): Boolean 
    # The return value indicates whether the command was executed.
    def self.processCatalystObjectMetaCommand(object, command)

        return false if object.nil?
        return false if command.nil?
        return false if command == ""

        if command == ".." and object["decoration:defaultCommand"] then
            # We we assume that a default command is never one of the current general object command.
            return true if NSXGeneralCommandHandler::processScheduleStoreCommand(object["uuid"], object["scheduleStoreItemId"], object["decoration:defaultCommand"])
            return NSXGeneralCommandHandler::processCommandAtAgent(object["uuid"], command)
        end

        if command == 'expose' then
            puts JSON.pretty_generate(object)
            LucilleCore::pressEnterToContinue()
            return true
        end

        if command == 'x-note' then
            text = NSXMiscUtils::editTextUsingTextmate(NSXMiscUtils::getXNote(object["uuid"]))
            NSXMiscUtils::setXNote(object["uuid"], text)
            return true
        end

        if command.start_with?('+') and (datetime = NSXMiscUtils::codeToDatetimeOrNull(command)) then
            puts "Pushing to #{datetime}"
            NSXDoNotShowUntilDatetime::setDatetime(object["uuid"], datetime)
            NSXMultiInstancesWrite::issueEventDoNotShowUntil(object["uuid"], datetime)
            if object["agentuid"] == "d2de3f8e-6cf2-46f6-b122-58b60b2a96f1" then
                claim = NSXEmailTrackingClaims::getClaimByStreamItemUUIDOrNull(object["uuid"])
                if claim then
                    claim["status"] = "detached"
                    NSXEmailTrackingClaims::commitClaimToDisk(claim)
                end
            end
            return true
        end

        false
    end

    # NSXGeneralCommandHandler::processScheduleStoreCommand(objectuuid, scheduleStoreItemId, command)
    def self.processScheduleStoreCommand(objectuuid, scheduleStoreItemId, command)
        return NSXScheduleStoreUtils::executeScheduleStoreItem(objectuuid, scheduleStoreItemId, command)
    end

    # NSXGeneralCommandHandler::processCommandAtAgent(objectuuid, command)
    def self.processCommandAtAgent(objectuuid, command)
        # TODO: we are retriveing the object only because we need the agentuid
        object = NSXCatalystObjectsOperator::getObjectIdentifiedByUUIDOrNull(objectuuid)
        return if object.nil?
        agentdata = NSXBob::getAgentDataByAgentUUIDOrNull(object["agentuid"])
        return if agentdata.nil?
        agentdata["object-command-processor"].call(objectuuid, command, true)
    end

end