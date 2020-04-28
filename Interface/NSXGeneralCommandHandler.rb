
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

require_relative "../Catalyst-Common/Catalyst-Common.rb"

class NSXGeneralCommandHandler

    # NSXGeneralCommandHandler::helpLines()
    def self.helpLines()
        [
            "Special General Commands:",
            "\n",
            [
                "help",
                "/                    General Menu",
                "l+                   spawn new catalyst item",
            ].map{|command| "        "+command }.join("\n"),
            "\n",
            "Special Object Commands:",
            "\n",
            [
                "..                   default command",
                "+datetimecode",
                "++                   +1 hour",
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
                "New Lucille text item",
            ]
            option = LucilleCore::selectEntityFromListOfEntitiesOrNull("option", options)
            return if option.nil?
            if option == "New Lucille text item" then
                text = NSXMiscUtils::editTextUsingTextmate("").strip
                location = "#{CATALYST_COMMON_CATALYST_FOLDERPATH}/Lucille/Items/#{NSXMiscUtils::timeStringL22()}.txt"
                File.open(location, "w"){|f| f.puts(text) }
                description = nil
                if text.lines.to_a.size == 1 then
                    description = text
                else
                    description = LucilleCore::askQuestionAnswerAsString("description: ")
                end
                KeyValueStore::set(nil, "3bbaacf8-2114-4d85-9738-0d4784d3bbb2:#{location}", description)
            end
            return
        end

        if command == "/" then
            options = [
                "Nyx Search",
                "Nyx",
                "Open Cycles",
                "Lucille",
                "Wave",
                "Catalyst",
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
                        JSON.parse(IO.read("#{CATALYST_COMMON_CATALYST_FOLDERPATH}/TheBridge/sources.json"))
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
            if option == "Nyx" then
                system("/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/Nyx/nyx")
            end
            if option == "Nyx Search" then
                system("/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/Nyx/nyx-search")
            end
            if option == "Wave" then
                system("/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/Wave/wave")
            end
            if option == "open Cycles" then
                system("/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/OpenCycles/opencycles")
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
        if object and command == "start+open" then
            NSXGeneralCommandHandler::processCatalystCommandCore(object, "start")
            NSXGeneralCommandHandler::processCatalystCommandCore(object, "open")
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