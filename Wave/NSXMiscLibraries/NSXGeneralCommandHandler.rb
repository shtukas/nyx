
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
                "/                   General Menu",
                "l+ spawn new catalyst item",
                "[] apply next transformation to Lucille's top item",
                ">> ifcs recommended next"
            ].map{|command| "        "+command }.join("\n"),
            "\n",
            "Special Object Commands:",
            "\n",
            [
                "..                  default command",
                "+datetimecode",
                "++                  +1 hour",
                "+<weekdayname>",
                "+<integer>day(s)",
                "+<integer>hour(s)",
                "+YYYY-MM-DD",
                "+1@23:45",
                "expose"
            ].map{|command| "        "+command }.join("\n")
        ]
    end

    # NSXGeneralCommandHandler::processCatalystCommandCore(object, command)
    def self.processCatalystCommandCore(object, command)

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

        if command == ">>" then
            system("/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/InFlightControlSystem/ifcs-apply-next")
            return
        end

        if command.start_with?("l'") then
            indx = command[2,99].strip.to_i
            system("/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/Lucille/lucille-open-file-identified-by-index #{indx}")
            return
        end

        if command == "l+" then
            text = NSXMiscUtils::editTextUsingTextmate("")
            filepath = "/Users/pascal/Galaxy/DataBank/Catalyst/Lucille/Items/#{NSXMiscUtils::timeStringL22()}.txt"
            File.open(filepath, "w"){|f| f.puts(text) }
            return
        end

        if command == "WaveGeneralMenu" then
            loop {
                options = [
                    "new wave",
                    "search",
                    "agents generation speed",
                    "TheBridge generation speed",
                    "ui generation speed",
                ]
                option = LucilleCore::selectEntityFromListOfEntitiesOrNull("option", options)
                break if option.nil?
                if option == "new wave" then
                    line = LucilleCore::askQuestionAnswerAsString("line: ")
                    NSXMiscUtils::spawnNewWaveItem(line)
                end
                if option == "search" then
                    pattern = LucilleCore::askQuestionAnswerAsString("pattern: ")
                    loop {
                        objects = NSXCatalystObjectsOperator::getAllObjectsFromAgents()
                        searchobjects1 = objects.select{|object| object["uuid"].downcase.include?(pattern.downcase) }
                        searchobjects2 = objects.select{|object| NSX1ContentsItemUtils::contentItemToAnnounce(object['contentItem']).downcase.include?(pattern.downcase) }
                        searchobjects = searchobjects1 + searchobjects2
                        status = NSXDisplayUtils::doListCalaystObjectsAndSeLectedOneObjectAndInviteAndExecuteCommand(searchobjects)
                        break if !status
                    }
                end
                if option == "agents generation speed" then
                    puts "Agent speed report"
                    NSXMiscUtils::agentsSpeedReport().reverse.each{|object|
                        puts "    - #{object["agent-name"]}: #{"%.3f" % object["retreive-time"]}"
                    }
                    LucilleCore::pressEnterToContinue()
                end
                if option == "TheBridge generation speed" then
                    puts "TheBridge generation speed report"
                    NSXAgentTheBridge::getGenerationSpeeds()
                        .sort{|o1, o2| o1["timespan"]<=>o2["timespan"] }
                        .reverse
                        .each{|object|
                            puts "    - #{object["source"]}: #{"%.3f" % object["timespan"]}"
                        }
                    LucilleCore::pressEnterToContinue()
                end
                if option == "ui generation speed" then
                    t1 = Time.new.to_f
                    NSXCatalystObjectsOperator::getCatalystListingObjectsOrdered()
                        .each{|object| NSXDisplayUtils::objectDisplayStringForCatalystListing(object, true, 1) } # All in focus at position 1
                    t2 = Time.new.to_f
                    puts "UI generation speed: #{(t2-t1).round(3)} seconds"
                    LucilleCore::pressEnterToContinue()
                end
            }
            return
        end

        if command == "/" then
            options = [
                "Wave",
                "In Flight Control System",
                "Nyx",
                "Todo",
            ]
            option = LucilleCore::selectEntityFromListOfEntitiesOrNull("option", options)
            if option == "Wave" then
                NSXGeneralCommandHandler::processCatalystCommandCore(object, "WaveGeneralMenu")
            end
            if option == "In Flight Control System" then
                system("/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/InFlightControlSystem/ifcs")
            end
            if option == "Nyx" then
                system("/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/Nyx/nyx")
            end
            if option == "Todo" then
                system("/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/Todo/todo")
            end
            return
        end

        # ---------------------------------------
        # General Utility Command Against Object
        # ---------------------------------------

        return false if object.nil?

        if command == '..' and object["defaultCommand"] then
            NSXGeneralCommandHandler::processCatalystCommandManager(object, object["defaultCommand"])
            return
        end

        if command == 'expose' then
            puts JSON.pretty_generate(object)
            LucilleCore::pressEnterToContinue()
            return
        end

        if command == "++" then
            NSXGeneralCommandHandler::processCatalystCommandCore(object, "+1 hour")
            return
        end

        if command.start_with?('+') and (datetime = NSXMiscUtils::codeToDatetimeOrNull(command)) then
            puts "Pushing to #{datetime}"
            NSXDoNotShowUntilDatetime::setDatetime(object["uuid"], datetime)
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
        Object.const_get(agentdata["agent-name"]).send("processObjectAndCommand", objectuuid, command)
    end

    # NSXGeneralCommandHandler::processCatalystCommandManager(object, command)
    def self.processCatalystCommandManager(object, command)
        if object and object["shell-redirects"] and object["shell-redirects"][command] then
            shellpath = object["shell-redirects"][command]
            puts shellpath
            system(shellpath)
            return
        end
        if object and command == "open" then
            NSXGeneralCommandHandler::processCatalystCommandCore(object, "open")
            NSXDisplayUtils::doPresentObjectInviteAndExecuteCommand(object)
            return
        end
        if object and ( command == "open+done" ) then
            NSXGeneralCommandHandler::processCatalystCommandCore(object, "open")
            NSXGeneralCommandHandler::processCatalystCommandCore(object, "done")
            return
        end
        NSXGeneralCommandHandler::processCatalystCommandCore(object, command)
    end

end