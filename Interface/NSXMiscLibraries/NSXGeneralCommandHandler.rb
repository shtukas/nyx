
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

        if command == "l+" then
            options = [
                "New Lucille item",
                "New Lucille item + IFCS registration",
            ]
            option = LucilleCore::selectEntityFromListOfEntitiesOrNull("option", options)
            return if option.nil?
            if option == "New Lucille item" then
                text = NSXMiscUtils::editTextUsingTextmate("")
                filepath = "/Users/pascal/Galaxy/DataBank/Catalyst/Lucille/Items/#{NSXMiscUtils::timeStringL22()}.txt"
                File.open(filepath, "w"){|f| f.puts(text) }
            end
            if option == "New Lucille item + IFCS registration" then
                text = NSXMiscUtils::editTextUsingTextmate("")
                filepath = "/Users/pascal/Galaxy/DataBank/Catalyst/Lucille/Items/#{NSXMiscUtils::timeStringL22()}.txt"
                File.open(filepath, "w"){|f| f.puts(text) }

                location = filepath
                # First we start my migrating the location to timeline [Open Cycles]
                system("/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/Lucille/lucille-set-location-timeline '#{location}' '[Open Cycles]'")
                # Now we need to create a new ifcs item, the only non trivial step if to decide the position
                makeNewIFCSItemPosition = lambda {
                    JSON.parse(`/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/InFlightControlSystem/ifcs-items`)
                        .sort{|i1, i2| i1["position"] <=> i2["position"]}
                        .each{|item|
                            puts "   - (#{"%5.3f" % item["position"]}) #{item["lucilleLocationBasename"]}"
                        }
                    LucilleCore::askQuestionAnswerAsString("position: ").to_f
                }
                position = makeNewIFCSItemPosition.call()
                uuid = SecureRandom.uuid
                item = {
                    "uuid"                    => uuid,
                    "lucilleLocationBasename" => File.basename(location),
                    "description"             => LucilleCore::askQuestionAnswerAsString("Description for IFCS item: "),
                    "position"                => position
                }
                File.open("/Users/pascal/Galaxy/DataBank/Catalyst/InFlightControlSystem/items/#{uuid}.json", "w"){|f| f.puts(JSON.pretty_generate(item)) }

            end
            return
        end

        if command == ">>" then
            system("/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/InFlightControlSystem/ifcs-apply-next")
            return
        end

        if command == "/" then
            options = [
                "Catalyst",
                "Lucille",
                "Wave",
                "In Flight Control System",
            ]
            option = LucilleCore::selectEntityFromListOfEntitiesOrNull("option", options)
            if option == "Catalyst" then
                loop {
                    options = [
                        "TheBridge generation speed",
                        "ui generation speed",
                    ]
                    option = LucilleCore::selectEntityFromListOfEntitiesOrNull("option", options)
                    break if option.nil?
                    if option == "TheBridge generation speed" then
                        puts "TheBridge generation speed report"
                        JSON.parse(IO.read("#{CATALYST_FOLDERPATH}/TheBridge/sources.json"))
                            .map{|source|
                                t1 = Time.new.to_f
                                JSON.parse(`#{source}`)
                                t2 = Time.new.to_f
                                {
                                    "source" => source,
                                    "timespan" => t2-t1 
                                }
                            }
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
            end
            if option == "Lucille" then
                system("/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/Lucille/lucille")
            end
            if option == "Wave" then
                system("/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/Wave/wave")
            end
            if option == "In Flight Control System" then
                system("/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/InFlightControlSystem/ifcs")
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

        if command.start_with?('+') and (unixtime = NSXMiscUtils::codeToUnixtimeOrNull(command)) then
            puts "Pushing to #{Time.at(unixtime).to_s}"
            DoNotShowUntil::setUnixtime(object["uuid"], unixtime)
            return
        end

        # ---------------------------------------
        # shell-redirects
        # ---------------------------------------

        if object and object["shell-redirects"] and object["shell-redirects"][command] then
            shellpath = object["shell-redirects"][command]
            puts shellpath
            system(shellpath)
            return
        end
    end

    # NSXGeneralCommandHandler::processCatalystCommandManager(object, command)
    def self.processCatalystCommandManager(object, command)
        if object and command == "open" then
            NSXGeneralCommandHandler::processCatalystCommandCore(object, "open")
            NSXDisplayUtils::doPresentObjectInviteAndExecuteCommand(object)
            return
        end
        if object and command == "start" then
            NSXGeneralCommandHandler::processCatalystCommandCore(object, "start")
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