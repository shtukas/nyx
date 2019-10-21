#!/usr/bin/ruby

# encoding: UTF-8

require 'fileutils'
# FileUtils.mkpath '/a/b/c'
# FileUtils.cp(src, dst)
# FileUtils.mv 'oldname', 'newname'
# FileUtils.rm(path_to_image)
# FileUtils.rm_rf('dir/to/remove')

require 'securerandom'
# SecureRandom.hex    #=> "eb693ec8252cd630102fd0d0fb7c3485"
# SecureRandom.hex(4) #=> "eb693123"
# SecureRandom.uuid   #=> "2d931510-d99f-494a-8c67-87feb05e1594"

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
                "new: <line> | 'text'",
                "next",
                "search: <pattern>",
                "[]                  next Lucille file",
                "/                   Catalyst menu",
                "nyx                 nyx-search",
            ].map{|command| "        "+command }.join("\n"),
            "\n",
            "Special Object Commands:",
            "\n",
            [
                "..                  default command",
                "[]                  next XNote",
                "+datetimecode",
                "++                  +1 hour",
                "+<weekdayname>",
                "+<integer>day(s)",
                "+<integer>hour(s)",
                "+YYYY-MM-DD",
                "+1@23:45",
                "expose",
                "note",
                "||                  agent interface",
            ].map{|command| "        "+command }.join("\n")
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
        streamuuid = NSXStreamsUtils::streamPrincipalDescriptionToStreamPrincipalUUIDOrNull(description)
        streamItem = NSXStreamsUtils::issueNewStreamItem(streamuuid, genericContentsItem, NSXMiscUtils::getNewEndOfQueueStreamOrdinal())
        puts JSON.pretty_generate(streamItem)
    end

    # NSXGeneralCommandHandler::processCatalystCommandCore(object, command, isLocalCommand)
    def self.processCatalystCommandCore(object, command, isLocalCommand)

        return false if command.nil?

        # ---------------------------------------
        # General Command
        # ---------------------------------------

        if command == "" then
            return
        end

        if command == 'help' then
            puts NSXGeneralCommandHandler::helpLines().join()
            LucilleCore::pressEnterToContinue()
            return
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
                streamItem = NSXStreamsUtils::issueNewStreamItem(CATALYST_INBOX_STREAMUUID, genericContentsItem, NSXMiscUtils::getNewEndOfQueueStreamOrdinal())
                puts JSON.pretty_generate(streamItem)
                catalystobjectuuid = streamItem["uuid"]
            end
            if type == "Stream" then
                streamDescription = NSXStreamsUtils::interactivelySelectStreamDescriptionOrNull()
                streamuuid = NSXStreamsUtils::streamPrincipalDescriptionToStreamPrincipalUUIDOrNull(streamDescription)
                streamItemOrdinal = NSXStreamsUtils::interactivelySpecifyStreamItemOrdinal(streamuuid)
                genericContentsItem = NSXGenericContents::issueItemText(text)
                streamItem = NSXStreamsUtils::issueNewStreamItem(streamuuid, genericContentsItem, streamItemOrdinal)
                puts JSON.pretty_generate(streamItem)
                catalystobjectuuid = streamItem["uuid"]
            end
            if type == "Wave" then
                catalystobjectuuid = NSXMiscUtils::spawnNewWaveItem(text)
            end
            return
        end

        if command.start_with?("search:") then
            pattern = command[7, command.size].strip
            loop {
                objects = NSXCatalystObjectsOperator::getAllObjectsFromAgents()
                searchobjects1 = objects.select{|object| object["uuid"].downcase.include?(pattern.downcase) }
                searchobjects2 = objects.select{|object| NSXContentUtils::itemToAnnounce(object['contentItem']).downcase.include?(pattern.downcase) }
                searchobjects = searchobjects1 + searchobjects2
                status = NSXDisplayUtils::doListCalaystObjectsAndSeLectedOneObjectAndInviteAndExecuteCommand(searchobjects)
                break if !status
            }
            return
        end

        if command == "/" then
            options = [
                "new Stream Item", 
                "new wave (repeat item)", 
                "generation-speed",
                "set no internet for this hour",
                "make new Stream Principal"
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
            if option == "generation-speed" then
                puts "Agent speed report"
                NSXMiscUtils::agentsSpeedReport().reverse.each{|object|
                    puts "    - #{object["agent-name"]}: #{"%.3f" % object["retreive-time"]}"
                }
                t1 = Time.new.to_f
                NSXCatalystObjectsOperator::getCatalystListingObjectsOrdered()
                    .each{|object| NSXDisplayUtils::objectDisplayStringForCatalystListing(object, true, 1) } # All in focus at position 1
                t2 = Time.new.to_f
                puts "UI generation speed: #{(t2-t1).round(3)} seconds"
                LucilleCore::pressEnterToContinue()
            end
            if option == "set no internet for this hour" then
                NSXMiscUtils::setNoInternetForThisHour()
            end
            if option == "make new Stream Principal" then
                streamuuid = SecureRandom.hex
                description = LucilleCore::askQuestionAnswerAsString("Description: ")
                multiplicity = LucilleCore::askQuestionAnswerAsString("Multiplicity (multiple of 30 mins, recommended: 1) : ").to_f
                streamPrincipal = {
                    "streamuuid"   => streamuuid,
                    "description"  => description,
                    "multiplicity" => multiplicity
                }
                NSXStreamsUtils::commitStreamPrincipalToDisk(streamPrincipal)
            end
            return
        end

        if command == "[]" then
            if IO.read(LUCILLE_DATA_FILE_PATH).split('@marker-539d469a-8521-4460-9bc4-5fb65da3cd4b')[0].strip.size>0 then
                LucilleFileHelper::applyNextTransformationToLucilleFile()
                return
            end
        end

        if command == "nyx" then
            system("/Users/pascal/Galaxy/LucilleOS/Nyx/nyx-search")
        end

        # ---------------------------------------
        # General Utility Command Against Object
        # ---------------------------------------

        return false if object.nil?

        if command == "[]" then
            if NSXMiscUtils::hasXNote(object["uuid"]) then
                contents = NSXMiscUtils::getXNote(object["uuid"])
                contents = NSXMiscUtils::applyNextTransformationToContent(contents)
                NSXMiscUtils::setXNote(object["uuid"], contents)
                return
            end
        end

        if command == '..' and object["defaultCommand"] then
            NSXGeneralCommandHandler::processCatalystCommandManager(object, object["defaultCommand"], isLocalCommand)
            return
        end

        if command == 'expose' then
            puts JSON.pretty_generate(object)
            LucilleCore::pressEnterToContinue()
            return
        end

        if command == "++" then
            NSXGeneralCommandHandler::processCatalystCommandCore(object, "+1 hour", isLocalCommand)
        end

        if command.start_with?('+') and (datetime = NSXMiscUtils::codeToDatetimeOrNull(command)) then
            puts "Pushing to #{datetime}"
            NSXDoNotShowUntilDatetime::setDatetime(object["uuid"], datetime)
            if isLocalCommand then
                NSXMultiInstancesWrite::sendEventToDisk({
                    "instanceName" => NSXMiscUtils::instanceName(),
                    "eventType"    => "MultiInstanceEventType:DoNotShowUntil",
                    "payload"      => {
                        "objectuuid" => object["uuid"],
                        "datetime"   => datetime
                    }
                })
            end
            return
        end

        if command == 'note' then
            text = NSXMiscUtils::editTextUsingTextmate(NSXMiscUtils::getXNote(object["uuid"]))
            NSXMiscUtils::setXNote(object["uuid"], text)
            return
        end

        # ---------------------------------------
        # Agent
        # ---------------------------------------

        objectuuid = object["uuid"]

        agentuid = NSXCatalystObjectsOperator::getAgentUUIDByObjectUUIDOrNull(objectuuid)
        return if agentuid.nil?
        agentdata = NSXBob::getAgentDataByAgentUUIDOrNull(agentuid)
        return if agentdata.nil?
        Object.const_get(agentdata["agent-name"]).send("processObjectAndCommand", objectuuid, command, isLocalCommand)
    end

    # NSXGeneralCommandHandler::processCatalystCommandManager(object, command, isLocalCommand)
    def self.processCatalystCommandManager(object, command, isLocalCommand)
        if object and command == "open" then
            NSXGeneralCommandHandler::processCatalystCommandCore(object, "open", true)
            NSXDisplayUtils::doPresentObjectInviteAndExecuteCommand(object)
            return
        end
        if object and command == "start" then
            NSXGeneralCommandHandler::processCatalystCommandCore(object, "start", true)
            # We need to update the commands (this is important for Stream objects)
            if object["agentuid"] == "d2de3f8e-6cf2-46f6-b122-58b60b2a96f1" then
                object["commands"] = NSXStreamsUtils::streamItemToStreamCatalystObjectCommands(object["metadata"]["item"])
            end
            NSXDisplayUtils::doPresentObjectInviteAndExecuteCommand(object)
            return
        end
        NSXGeneralCommandHandler::processCatalystCommandCore(object, command, isLocalCommand)
    end

end