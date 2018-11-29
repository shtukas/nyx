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

    # NSXGeneralCommandHandler::putshelp()
    def self.putshelp()
        puts "Special General Commands"
        puts "    help"
        puts "    search <pattern>"
        puts "    :<p>        # set the listing reference point"
        puts "    +           # add 1 to the standard listing position"
        puts "    ++          # delete the first line of DayNotes.txt"
        puts ""
        puts "    wave:       # create a new wave (repeat item) with that description (can use 'text')"
        puts "    streamitem: # create a new stream with that description (can use 'text')"
        puts "    thread:     # create a new LightThread, details entered interactively"
        puts "    airpoint:   # create a new Air Point"
        puts ""
        puts "    threads     # LightThreads dive"
        puts "    airpoints   # AirPoints dive"
        puts "    email-sync  # Run email sync"
        puts "    speed       # Report of agents's speed"
        puts ""
    end

    # NSXGeneralCommandHandler::specialObjectCommandsAsString()
    def self.specialObjectCommandsAsString()
        "Special Object Commands : .. ,, ;; +datetimecode, +<weekdayname>, +<integer>day(s), +<integer>hour(s), +YYYY-MM-DD, expose"
    end

    # NSXGeneralCommandHandler::processCommand(object, command)
    def self.processCommand(object, command)

        # no object needed

        if command == 'help' then
            NSXGeneralCommandHandler::putshelp()
            LucilleCore::pressEnterToContinue()
            return
        end

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

        if command == '++' then
            NSXDayNotes::deleteFirstLine()
            return
        end

        if command == 'wave:' then
            description = LucilleCore::askQuestionAnswerAsString("description (can use 'text'): ")
            NSXMiscUtils::spawnNewWaveItem(description)
            return
        end

        if command == 'streamitem:' then
            description = LucilleCore::askQuestionAnswerAsString("description (can use 'text') or url: ")
            description = NSXMiscUtils::processItemDescriptionPossiblyAsTextEditorInvitation(description)
            genericContentsItem = 
                if description.start_with?("http") then
                    NSXGenericContents::issueItemURL(description)
                else
                    NSXGenericContents::issueItemText(description)
                end
            lightThread = NSXLightThreadUtils::interactivelySelectALightThread()
            streamItem = NSXStreamsUtils::issueItemAtNextOrdinalUsingGenericContentsItem(lightThread["streamuuid"], genericContentsItem)
            puts JSON.pretty_generate(streamItem)
            return
        end

        if command == 'thread:' then
            description = LucilleCore::askQuestionAnswerAsString("description: ")
            priorityXp = NSXLightThreadUtils::lightThreadPriorityXPPickerOrNull()
            if priorityXp.nil? then
                puts "You have not provided a priority. Aborting."
                LucilleCore::pressEnterToContinue()
                return
            end
            lightThread = NSXLightThreadUtils::makeNewLightThread(description, priorityXp)
            puts JSON.pretty_generate(lightThread)
            return
        end

        if command == "airpoint:" then
            description = LucilleCore::askQuestionAnswerAsString("description: ")
            atlasReference = LucilleCore::askQuestionAnswerAsString("atlas reference (leave empty for new folder in Desktop/AirPointsFolders): ")
            if atlasReference.size==0 then
                atlasReference = "atlas-#{SecureRandom.hex(8)}"
                folderpath = "/Users/pascal/Desktop/AirPointsFolders/#{atlasReference}"
                FileUtils.mkpath(folderpath)
                system("open '#{folderpath}'")
            end
            airPoint = NSXAirPointsUtils::makeAirPoint(atlasReference, description)
            NSXAirPointsUtils::commitAirPointToDisk(airPoint)
            return
        end

        if command == 'threads' then
            NSXLightThreadUtils::lightThreadsDive()
            return
        end

        if command == 'airpoints' then
            NSXAirPointsUtils::airPointsDive()
            return
        end  

        if command == 'email-sync' then
            NSXMiscUtils::emailSync(true)
            return
        end

        if command == "speed" then
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
                NSXBob::getAgentDataByAgentUUIDOrNull(object["agent-uid"])["object-command-processor"].call(object, command)
            }
    end
end