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

    # NSXGeneralCommandHandler::processCatalystCommand(object, command)
    def self.processCatalystCommand(object, command)

        return false if command.nil?

        # ---------------------------------------
        # General Command
        puts "General Command"
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
            return
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
            return
        end

        if command == "/" then
            options = [
                "new Stream Item", 
                "new wave (repeat item)", 
                "generation-speed",
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
            return
        end

        if command == "next" then
            # Get rid of the first inner line of the Next file
            NSXMiscUtils::applyNextTransformationToLucilleInstanceFile()
            return
        end

        # ---------------------------------------
        # General Utility Command Against Object
        puts "General Utility Command Against Object"
        # ---------------------------------------

        return false if object.nil?

        if command == ".." and object["decoration:defaultCommand"] then
            NSXGeneralCommandHandler::processCatalystCommand(object, object["decoration:defaultCommand"])
            return
        end

        if command == 'expose' then
            puts JSON.pretty_generate(object)
            LucilleCore::pressEnterToContinue()
            return
        end

        if command == 'x-note' then
            text = NSXMiscUtils::editTextUsingTextmate(NSXMiscUtils::getXNote(object["uuid"]))
            NSXMiscUtils::setXNote(object["uuid"], text)
            return
        end

        if command.start_with?('+') and (datetime = NSXMiscUtils::codeToDatetimeOrNull(command)) then
            puts "Pushing to #{datetime}"
            NSXDoNotShowUntilDatetime::setDatetime(object["uuid"], datetime)
            NSXMultiInstancesWrite::sendEventToDisk({
                "instanceName" => NSXMiscUtils::instanceName(),
                "eventType"    => "MultiInstanceEventType:DoNotShowUntil",
                "payload"      => {
                    "objectuuid" => object["uuid"],
                    "datetime"   => datetime
                }
            })
            return
        end

        # ---------------------------------------
        # Schedule Store Item
        puts "Schedule Store Item"
        # ---------------------------------------

        scheduleStoreItemId = object["scheduleStoreItemId"]
        scheduleStoreItem = NSXScheduleStore::getItemOrNull(scheduleStoreItemId)
        puts scheduleStoreItem
        return if scheduleStoreItem.nil?

        if scheduleStoreItem["type"] == "todo-and-inform-agent-11b30518" then

        end
        if scheduleStoreItem["type"] == "toactivate-and-inform-agent-2d839ef7" then

        end
        if scheduleStoreItem["type"] == "wave-item-dc583ed2" then

        end
        if scheduleStoreItem["type"] == "stream-item-7e37790b" then
            if command == "start" then
                return if NSXRunner::isRunning?(scheduleStoreItemId)
                NSXRunner::start(scheduleStoreItemId)
                return
            end
            if command == "stop" then
                return if !NSXRunner::isRunning?(scheduleStoreItemId)
                timespanInSeconds = NSXRunner::stop(scheduleStoreItemId)
                NSXRunTimes::addPoint(scheduleStoreItem["collectionuid"], Time.new.to_i, timespanInSeconds)
                return
            end
        end
        if scheduleStoreItem["type"] == "24h-sliding-time-commitment-da8b7ca8" then
            if command == "start" then
                return if NSXRunner::isRunning?(scheduleStoreItemId)
                NSXRunner::start(scheduleStoreItemId)
                return
            end
            if command == "stop" then
                return if !NSXRunner::isRunning?(scheduleStoreItemId)
                timespanInSeconds = NSXRunner::stop(scheduleStoreItemId)
                NSXRunTimes::addPoint(scheduleStoreItem["collectionuid"], Time.new.to_i, timespanInSeconds)
                NSXMultiInstancesWrite::sendEventToDisk({
                    "instanceName" => NSXMiscUtils::instanceName(),
                    "eventType"    => "MultiInstanceEventType:RunTimesPoint",
                    "payload"      => {
                        "uuid"          => SecureRandom.hex,
                        "collectionuid" => scheduleStoreItem["collectionuid"],
                        "unixtime"      => Time.new.to_i,
                        "algebraicTimespanInSeconds" => timespanInSeconds
                    }
                })
                return
            end
        end

        # ---------------------------------------
        # Agent
        puts "Agent"
        # ---------------------------------------

        objectuuid = object["uuid"]

        agentuid = NSXCatalystObjectsOperator::getAgentUUIDByObjectUUIDOrNull(objectuuid)
        return if agentuid.nil?
        agentdata = NSXBob::getAgentDataByAgentUUIDOrNull(agentuid)
        return if agentdata.nil?
        agentdata["object-command-processor"].call(objectuuid, command, true)

    end

end