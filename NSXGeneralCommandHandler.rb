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
        puts "    wave: <description>     # create a new wave with that description"
        puts "    thread:                 # create a new lightThread, details entered interactively"
        puts ""
        puts "    threads                 # lightThreads listing dive"
        puts ""
        puts "    email-sync              # run email sync"
        puts "    house-on"
        puts "    house-off"
        puts ""
    end

    # NSXGeneralCommandHandler::specialObjectCommandsAsString()
    def self.specialObjectCommandsAsString()
        "Special Object Commands : ,, .. ordinal: <ordinal>, +datetimecode, +<weekdayname>, +<integer>day(s), +<integer>hour(s), +YYYY-MM-DD, expose, >thread"
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

        if command == 'email-sync' then
            NSXMiscUtils::emailSync(true)
            return
        end

        if command == "house-on" then
            NSXAgentsDataOperator::destroy(NSXAgentHouse::agentuuid(), "6af0644d-175e-4af9-97fb-099f71b505f5:#{NSXMiscUtils::currentDay()}")
            signal = ["reload-agent-objects", NSXAgentHouse::agentuuid()]
            NSXCatalystObjectsOperator::processAgentProcessorSignal(signal)
        end

        if command == "house-off" then
            NSXAgentsDataOperator::set(NSXAgentHouse::agentuuid(), "6af0644d-175e-4af9-97fb-099f71b505f5:#{NSXMiscUtils::currentDay()}", "killed")
            signal = ["reload-agent-objects", NSXAgentHouse::agentuuid()]
            NSXCatalystObjectsOperator::processAgentProcessorSignal(signal)
        end

        if command == 'threads' then
            NSXLightThreadUtils::lightThreadsDive()
            return
        end

        if command == 'thread:' then
            description = LucilleCore::askQuestionAnswerAsString("description: ")
            commitment = LucilleCore::askQuestionAnswerAsString("time commitment every day (every 20 hours): ").to_f
            target = nil
            lightThread = NSXLightThreadUtils::makeNewLightThread(description, commitment, target)
            puts JSON.pretty_generate(lightThread)
            LucilleCore::pressEnterToContinue()
            return
        end

        if command.start_with?('wave:') then
            description = command[5, command.size].strip
            NSXMiscUtils::waveInsertNewItemInteractive(description)
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

        if command == ',,' then
            NSXCatalystMetadataInterface::setMetricCycleUnixtimeForObject(object["uuid"], Time.new.to_i)
            return
        end

        if command == '>thread' then
            NSXMiscUtils::sendCatalystObjectToTimeProton(object["uuid"])
            return
        end

        if command == 'expose' then
            puts JSON.pretty_generate(object)
            metadata = NSXCatalystMetadataOperator::getMetadataForObject(object["uuid"])
            puts JSON.pretty_generate(metadata)
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

        if command.start_with?('ordinal:') then
            _, ordinal = NSXStringParser::decompose(command)
            if ordinal.nil? then
                puts "usage: ordinal: <ordinal>"
                LucilleCore::pressEnterToContinue()
                return
            end
            ordinal = ordinal.to_f
            NSXCatalystMetadataInterface::setOrdinal(object["uuid"], ordinal)
            signal = ["reload-agent-objects", object["agent-uid"]]
            NSXCatalystObjectsOperator::processAgentProcessorSignal(signal)
            return
        end

        command.split(";").map{|t| t.strip }
            .each{|command|
                signal = NSXBob::agentuuid2AgentDataOrNull(object["agent-uid"])["object-command-processor"].call(object, command)
                NSXCatalystObjectsOperator::processAgentProcessorSignal(signal)
            }
    end
end