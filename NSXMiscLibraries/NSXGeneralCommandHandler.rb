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
            ["help", ":<p>", "+", "/", "new: <line> | 'text'", "inbox: <line> | 'text'", "search: <pattern>"].map{|command| "        "+command }.join("\n"),
            "\n",
            "Special Object Commands:",
            "\n",
            ["..", ",,", "ordinal/release", "+datetimecode", "+<weekdayname>", "+<integer>day(s)", "+<integer>hour(s)", "+YYYY-MM-DD", "+1@23:45", "expose", "planning"].map{|command| "        "+command }.join("\n")
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

    # NSXGeneralCommandHandler::processCommand(object, command)
    def self.processCommand(object, command)

        # no object needed

        if command == "" then
            return [nil]
        end

        if command == 'help' then
            puts NSXGeneralCommandHandler::helpLines().join()
            LucilleCore::pressEnterToContinue()
            return [nil]
        end

        if command == "+" then
            NSXMiscUtils::setStandardListingPosition(NSXMiscUtils::getStandardListingPosition()+1)
            return [nil]
        end

        if command.start_with?(":") and NSXMiscUtils::isInteger(command[1, command.size]) then
            position = command[1, command.size].strip.to_i
            NSXMiscUtils::setStandardListingPosition([position, 0].max)
            return [nil]
        end

        if command.start_with?("new:") then
            text = command[4, command.size].strip
            if text == "text" then
                text = NSXMiscUtils::editTextUsingTextmate("")
            end
            type = LucilleCore::selectEntityFromListOfEntitiesOrNull("type:", ["Stream", "Wave"])
            catalystobjectuuid = nil
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
            if catalystobjectuuid then
                datecode = LucilleCore::askQuestionAnswerAsString("datecode (leave empty for nothing): ")
                datetime = NSXMiscUtils::codeToDatetimeOrNull(datecode)
                if datetime then
                    NSXDoNotShowUntilDatetime::setDatetime(catalystobjectuuid, datetime)
                end
            end
            if catalystobjectuuid then
                ordinal = LucilleCore::askQuestionAnswerAsString("ordinal (leave empty for nothing): ")
                if ordinal.size>0 then
                    ordinal = ordinal.to_f
                    NSXOrdinals::setOrdinal(catalystobjectuuid, ordinal)
                end
            end
            return [nil]
        end

        if command.start_with?("inbox:") then
            text = command[6, command.size].strip
            if text == "text" then
                text = NSXMiscUtils::editTextUsingTextmate("")
            end
            genericContentsItem = NSXGenericContents::issueItemText(text)
            puts JSON.pretty_generate(genericContentsItem)
            streamItem = NSXStreamsUtils::issueNewStreamItem("03b79978bcf7a712953c5543a9df9047", genericContentsItem, NSXMiscUtils::makeEndOfQueueStreamItemOrdinal())
            puts JSON.pretty_generate(streamItem)
            ordinal = LucilleCore::askQuestionAnswerAsString("ordinal (leave empty for nothing): ")
            if ordinal.size>0 then
                ordinal = ordinal.to_f
                NSXOrdinals::setOrdinal(streamItem["uuid"], ordinal)
            end
            return [nil]
        end

        if command.start_with?("search:") then
            pattern = command[7, command.size].strip
            loop {
                objects = NSXCatalystObjectsOperator::getAllObjectsFromAgents()
                searchobjects1 = objects.select{|object| object["uuid"].downcase.include?(pattern.downcase) }
                searchobjects2 = objects.select{|object| object["announce"].downcase.include?(pattern.downcase) }
                searchobjects = searchobjects1 + searchobjects2
                status = NSXDisplayUtils::doListCalaystObjectsAndSeLectedOneObjectAndInviteAndExecuteCommand(searchobjects)
                break if !status
            }
            return [nil]
        end

        if command == "/" then
            options = [
                "new Stream Item", 
                "new wave (repeat item)", 
                "email-sync"
            ]
            option = LucilleCore::selectEntityFromListOfEntitiesOrNull("option", options)
            return [nil] if option.nil?
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
            return [nil]
        end

        return [nil] if object.nil?

        # object needed

        if command == ".." and object["defaultExpression"] and object["defaultExpression"]!=".." then
            command = object["defaultExpression"]
            return NSXGeneralCommandHandler::processCommand(object, command)
        end

        if command == 'expose' then
            puts JSON.pretty_generate(object)
            claim = NSXEmailTrackingClaims::getClaimByStreamItemUUIDOrNull(object["uuid"])
            if claim then
                puts JSON.pretty_generate(claim)
            end
            LucilleCore::pressEnterToContinue()
            return [nil]
        end

        if command == "ordinal" then
            value = LucilleCore::askQuestionAnswerAsString("ordinal: ").to_f
            NSXOrdinals::setOrdinal(object["uuid"], value)
            return [nil]
        end

        if command == "release" then
            NSXOrdinals::unsetOrdinal(object["uuid"])
            return ["remove", object["uuid"]]
        end

        if command == 'planning' then
            text = NSXMiscUtils::editTextUsingTextmate(NSXMiscUtils::getPlanningText(object["uuid"]))
            NSXMiscUtils::setPlanningText(object["uuid"], text)
            return [nil]
        end

        if command == ',,' then
            NSXMiscUtils::resetMetricWeightRatio(object["uuid"])
            return [nil]
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
            return ["remove", object["uuid"]]
        end

        command.split(";").map{|t| t.strip }
            .each{|command|
                agentdata = NSXBob::getAgentDataByAgentUUIDOrNull(object["agentuid"])
                next if agentdata.nil?
                signal = agentdata["object-command-processor"].call(object, command)
                NSXCatalystObjectsOperator::processProcessingSignal(signal)
            }
        [nil]
    end
end