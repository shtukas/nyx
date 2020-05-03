
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

require "/Users/pascal/Galaxy/LucilleOS/Software-Common/Ruby-Libraries/KeyValueStore.rb"
=begin
    KeyValueStore::setFlagTrue(repositorylocation or nil, key)
    KeyValueStore::setFlagFalse(repositorylocation or nil, key)
    KeyValueStore::flagIsTrue(repositorylocation or nil, key)

    KeyValueStore::set(repositorylocation or nil, key, value)
    KeyValueStore::getOrNull(repositorylocation or nil, key)
    KeyValueStore::getOrDefaultValue(repositorylocation or nil, key, defaultValue)
    KeyValueStore::destroy(repositorylocation or nil, key)
=end

require "/Users/pascal/Galaxy/LucilleOS/Software-Common/Ruby-Libraries/Mercury.rb"
=begin
    Mercury::postValue(channel, value)

    Mercury::discardFirstElementsToEnforeQueueSize(channel, size)
    Mercury::discardFirstElementsToEnforceTimeHorizon(channel, unixtime)

    Mercury::getQueueSize(channel)
    Mercury::getAllValues(channel)

    Mercury::getFirstValueOrNull(channel)
    Mercury::deleteFirstValue(channel)
=end

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
                timelines = JSON.parse(`/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/Lucille/lucille-timelines`)
                timeline = LucilleCore::selectEntityFromListOfEntitiesOrNull("timeline:", timelines)
                timeline = timeline || "Inbox"
                packet = {
                    "text" => text,
                    "timeline" => timeline
                }
                Mercury::postValue("AF39EC62-4779-4C00-85D9-D2F19BD2D71E", packet)
            end
            return
        end

        if command == "[]" then
            CatalystCommon::copyLocationToCatalystBin("/Users/pascal/Desktop/Lucille.txt")
            parts = IO.read("/Users/pascal/Desktop/Lucille.txt").split('@separation-e3cdf0ec-4119-43d8-8701-a363a74c398b')
            part1 = parts[0].strip
            part2 = parts[1].strip
            part1 = NSXMiscUtils::applyNextTransformationToContent(part1)
            content = [part1, part2].join("\n\n@separation-e3cdf0ec-4119-43d8-8701-a363a74c398b\n\n")
            File.open("/Users/pascal/Desktop/Lucille.txt", "w"){|f| f.puts(content) }
        end

        if command == ">>" then
            system("/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/InFlightControlSystem/catalyst-objects-processing stop-whichever-is-running")
        end

        if command == "/" then
            options = [
                "Nyx Search",
                "Nyx",
                "Calendar",
                "In Flight Control System",
                "Open Cycles",
                "Lucille",
                "Wave",
                "Catalyst",
            ]
            option = LucilleCore::selectEntityFromListOfEntitiesOrNull("option", options)
            if option == "Catalyst" then
                loop {
                    options = [
                        "TheBridge items generation speed",
                        "TheBridge + UI generation speed"
                    ]
                    option = LucilleCore::selectEntityFromListOfEntitiesOrNull("option", options)
                    break if option.nil?
                    if option == "TheBridge items generation speed" then
                        puts "TheBridge items generation speed report"
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
                    if option == "TheBridge + UI generation speed" then
                        t1 = Time.new.to_f
                        NSXCatalystObjectsOperator::getCatalystListingObjectsOrdered()
                            .each{|object| NSXDisplayUtils::objectDisplayStringForCatalystListing(object, true, 1) } # All in focus at position 1
                        t2 = Time.new.to_f
                        puts "UI generation speed: #{(t2-t1).round(3)} seconds"
                        LucilleCore::pressEnterToContinue()
                    end
                }
            end
            if option == "In Flight Control System" then
                system("/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/InFlightControlSystem/ifcs")
            end
            if option == "Calendar" then
                system("/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/Calendar/calendar")
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
            if option == "Open Cycles" then
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
        NSXGeneralCommandHandler::processCatalystCommandCore(object, command)
    end

end