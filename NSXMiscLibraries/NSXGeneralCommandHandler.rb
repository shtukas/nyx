#!/usr/bin/ruby

# encoding: UTF-8

# This subsystem entire purpose is to receive commands from the user and either:
	# The command is "special" and going to be captured and executed at some point along the code
	# The command is handled by an agent and the signal forwarded to the NSXCatalystObjectsOperator

class NSXGeneralCommandHandler

    # NSXGeneralCommandHandler::putshelp()
    def self.putshelp()
        puts "Special General Commands"
        puts "    help"
        puts "    search <pattern>"
        puts "    :<p>                    # set the listing reference point"
        puts "    +                       # add 1 to the standard listing position"
        puts ""
        puts "    wave: <description>     # create a new wave with that description (can use 'text')"
        puts "    stream:                 # create a new stream with that description (can use 'text')"
        puts "    thread:                 # create a new lightThread, details entered interactively"
        puts ""
        puts "    threads                 # lightThreads listing dive"
        puts ""
        puts "    email-sync              # run email sync"
        puts ""
    end

    # NSXGeneralCommandHandler::specialObjectCommandsAsString()
    def self.specialObjectCommandsAsString()
        "Special Object Commands : .. ;; +datetimecode, +<weekdayname>, +<integer>day(s), +<integer>hour(s), +YYYY-MM-DD, expose, >thread"
    end

    # NSXGeneralCommandHandler::processCommand(object, command)
    def self.processCommand(object, command)

        # no object needed

        if command == "+" then
            NSXMiscUtils::setStandardListingPosition(NSXMiscUtils::getStandardListingPosition()+1)
            return
        end
        
        if command.start_with?(":") then
            if NSXMiscUtils::isInteger(command[1, command.size]) then
                position = command[1, command.size].strip.to_i
                NSXMiscUtils::setStandardListingPosition([position, 0].max)
            end
            return
        end

        if command == 'help' then
            NSXGeneralCommandHandler::putshelp()
            LucilleCore::pressEnterToContinue()
            return
        end

        if command.start_with?('wave:') then
            description = command[5, command.size].strip
            NSXMiscUtils::waveInsertNewItemInteractive(description)
            return
        end

        if command == 'stream:' then
            description = LucilleCore::askQuestionAnswerAsString("text or url: ")
            description = NSXMiscUtils::processItemDescriptionPossiblyAsTextEditorInvitation(description)
            genericContentsItem = 
                if description.start_with?("http") then
                    NSXGenericContents::issueItemURL(description)
                else
                    NSXGenericContents::issueItemText(description)
                end
            streamName = LucilleCore::selectEntityFromListOfEntitiesOrNull("stream name:", ["Right-Now", "Today-Important", "XStream"])
            streamItem = NSXStreamsUtils::issueUsingGenericItem(streamName, genericContentsItem)
            puts JSON.pretty_generate(streamItem)
            LucilleCore::pressEnterToContinue()
            return
        end

        if command == 'thread:' then
            description = LucilleCore::askQuestionAnswerAsString("description: ")
            commitment = LucilleCore::askQuestionAnswerAsString("time commitment every day: ").to_f
            priority = NSXLightThreadUtils::interactivelySelectALightThreadPriority()
            lightThread = NSXLightThreadUtils::makeNewLightThread(description, commitment, priority)
            puts JSON.pretty_generate(lightThread)
            LucilleCore::pressEnterToContinue()
            return
        end

        if command == 'threads' then
            NSXLightThreadUtils::lightThreadsDive()
            return
        end

        if command == 'email-sync' then
            NSXMiscUtils::emailSync(true)
            return
        end

        if command.start_with?("search") then
            pattern = command[6,command.size].strip
            loop {
                searchobjects1 = NSXCatalystObjectsOperator::getObjects().select{|object| object["uuid"].downcase.include?(pattern.downcase) }
                searchobjects2 = NSXCatalystObjectsOperator::getObjects().select{|object| NSXMiscUtils::objectToString(object).downcase.include?(pattern.downcase) }                
                searchobjects = searchobjects1 + searchobjects2
                break if searchobjects.size==0
                selectedobject = LucilleCore::selectEntityFromListOfEntitiesOrNull("object", searchobjects, lambda{ |object| NSXMiscUtils::objectToString(object) })
                break if selectedobject.nil?
                NSXDisplayOperator::doPresentObjectInviteAndExecuteCommand(selectedobject)
            }
            return
        end

        return if object.nil?

        # object needed

        if command == "/start" then
            if object[":light-thread-data:"] then
                if object[":light-thread-data:"]["secondary-object-run-status"].nil? then
                    lightThreadUUID = object[":light-thread-data:"]["light-thread"]["uuid"]               
                    NSXMiscUtils::startLightThreadSecondaryObject(object["uuid"], lightThreadUUID)
                    NSXMiscUtils::setStandardListingPosition(1)
                end
            end
            return
        end

        if command == "/stop" then
            if object[":light-thread-data:"] then
                if object[":light-thread-data:"]["secondary-object-run-status"] then
                    lightThreadUUID = object[":light-thread-data:"]["light-thread"]["uuid"]
                    runningStatus = NSXMiscUtils::getLightThreadSecondaryObjectRunningStatusOrNull(object["uuid"])
                    timeSpanInSeconds = Time.new.to_i - runningStatus["start-unixtime"]
                    NSXLightThreadUtils::lightThreadAddTime(lightThreadUUID, timeSpanInSeconds.to_f/3600)
                    NSXMiscUtils::unsetLightThreadSecondaryObjectRunningStatus(object["uuid"])
                end
            end
            return
        end

        if command == '>thread' then
            NSXMiscUtils::InteractiveLightThreadChoiceAndMakeLT1526Claim(object["uuid"])
            return
        end

        if command == 'expose' then
            puts JSON.pretty_generate(object)
            LucilleCore::pressEnterToContinue()
            return
        end

        if command.start_with?('+') then
            code = command
            if (datetime = NSXMiscUtils::codeToDatetimeOrNull(code)) then
                NSXDoNotShowUntilDatetime::setDatetime(object["uuid"], datetime)
            end
            return
        end
        
        command.split(";").map{|t| t.strip }
            .each{|command|
                signal = NSXBob::getAgentDataByAgentUUIDOrNull(object["agent-uid"])["object-command-processor"].call(object, command)
                NSXCatalystObjectsOperator::processAgentProcessorSignal(signal)
            }
    end
end