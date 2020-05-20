
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

require "/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/Catalyst/Common.rb"

require "/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/Catalyst/DataPoints.rb"

class NSXGeneralCommandHandler

    # NSXGeneralCommandHandler::helpLines()
    def self.helpLines()
        [
            "Special General Commands:",
            "\n",
            [
                "help",
                "/                    General Menu",
                "::                   Open Interface-Top.txt"
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

        if command == '' then
            puts NSXGeneralCommandHandler::helpLines().join()
            LucilleCore::pressEnterToContinue()
            return
        end

        if command == '::' then
            system("open '/Users/pascal/Galaxy/DataBank/Catalyst/Interface/Interface-Top.txt'")
            LucilleCore::pressEnterToContinue()
            return
        end

        if command == "[]" then
            rewriteFile = lambda {|filepath|
                CatalystCommon::copyLocationToCatalystBin(filepath)
                content = IO.read(filepath)
                content = NSXMiscUtils::applyNextTransformationToContent(content)
                File.open(filepath, "w"){|f| f.puts(content) }
            }
            interfaceTopFilepath = "/Users/pascal/Galaxy/DataBank/Catalyst/Interface/Interface-Top.txt"
            interfaceContents = IO.read(interfaceTopFilepath).strip
            if interfaceContents.size > 0 then
                rewriteFile.call(interfaceTopFilepath)
            else
                rewriteFile.call("/Users/pascal/Desktop/Lucille.txt")
            end
            return
        end

        if command == "/" then
            options = [
                "Make new [something]",
                "DataExplorer",
                "DataReferences",
                "OpenCycles",
                "Todo",
                "Calendar",
                "Wave",
                "Catalyst",
            ]
            option = LucilleCore::selectEntityFromListOfEntitiesOrNull("option", options)

            if option == "Todo" then
                system("/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/Todo/todo")
            end
            if option == "Calendar" then
                system("/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/Calendar/calendar")
            end
            if option == "DataExplorer" then
                system("/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/DataExplorer/dataexplorer")
            end
            if option == "Wave" then
                system("/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/Wave/wave")
            end
            if option == "OpenCycles" then
                system("/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/OpenCycles/opencycles")
            end
            if option == "DataReferences" then
                system("/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/DataReferences/references")
            end
            if option == "Make new [something]" then
                options = [
                    "DataReference",
                    "OpenCycle [with existing datapoint]",
                    "OpenCycle [with new datapoint]",
                    "DataPoint"
                ]
                option = LucilleCore::selectEntityFromListOfEntitiesOrNull("option", options)
                return if option.nil?
                if option == "DataReference" then
                    system("/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/DataReferences/x-make-new")
                end
                if option == "OpenCycle [with existing datapoint]" then
                    system("/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/OpenCycles/x-make-new-with-existing-datapoint")
                end
                if option == "OpenCycle [with new datapoint]" then
                    system("/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/OpenCycles/x-make-new-with-new-datapoint")
                end
                if option == "DataPoint" then
                    DataPoints::issueDataPointInteractivelyOrNull()
                end
            end
            if option == "Catalyst" then
                loop {
                    options = [
                        "Applications generation speed",
                        "UI generation speed"
                    ]
                    option = LucilleCore::selectEntityFromListOfEntitiesOrNull("option", options)
                    break if option.nil?
                    if option == "Applications generation speed" then
                        puts "Applications generation speed report"
                        ["Anniversaries", "BackupsMonitor", "Calendar", "Gwork", "LucilleTxt", "Todo", "Vienna", "Wave", "YouTubeVideoStream"]
                            .map{|appname| "/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/#{appname}/x-catalyst-objects" }
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
                    if option == "UI generation speed" then
                        t1 = Time.new.to_f
                        NSXCatalystObjectsOperator::getCatalystListingObjectsOrdered()
                            .each{|object| NSXDisplayUtils::objectDisplayStringForCatalystListing(object, true, 1) } # All in focus at position 1
                        t2 = Time.new.to_f
                        puts "UI generation speed: #{(t2-t1).round(3)} seconds"
                        LucilleCore::pressEnterToContinue()
                    end
                }
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

        if command == "note" then
            NSXMiscUtils::editXNote(object["uuid"])
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