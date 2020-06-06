
# encoding: UTF-8

FlamePadding = "              "

class NSXDisplayUtils

    # NSXDisplayUtils::contentItemToAnnounce(item)
    def self.contentItemToAnnounce(item)
        if item["type"] == "line" then
            return item["line"]
        end
        if item["type"] == "line-and-body" then
            return item["line"]
        end
        if item["type"] == "block" then
            return "[block]"
        end
        "[8f854b3a] I don't know how to announce: #{item["type"]}"
    end

    # NSXDisplayUtils::defaultCatalystObjectCommands()
    def self.defaultCatalystObjectCommands()
        ["expose"]
    end

    # NSXDisplayUtils::makeInferfaceString(object)
    def self.makeInferfaceString(object)
        defaultCommand = object["defaultCommand"]
        commands = object["commands"]
        if defaultCommand then
            commands = commands.reject{|c| c == defaultCommand }
        end
        [
            FlamePadding[0, FlamePadding.size-1],
            defaultCommand ? "#{defaultCommand.green}" : nil,
            commands.join(" "),
            NSXDisplayUtils::defaultCatalystObjectCommands().join(" ")
        ].compact.reject{|command| command=='' }.join(" ")
    end

    # NSXDisplayUtils::makeDisplayStringForCatalystListing(object, isFocus, displayOrdinal)
    def self.makeDisplayStringForCatalystListing(object, isFocus, displayOrdinal)
        # NSXMiscUtils::screenWidth()

        width = NSXMiscUtils::screenWidth()-15

        contentItem = object["contentItem"]

        if contentItem["type"] == "line" then
            if isFocus then
                line = contentItem["line"]
                line = object["isRunning"] ? line.green : line
                return [
                    "[*#{"%2d" % displayOrdinal}] (#{"%5.3f" % object["metric"]}) #{line}",
                    NSXDisplayUtils::makeInferfaceString(object)
                ].join("\n")
            else
                line = contentItem["line"]
                line = line[0, width]
                line = object["isRunning"] ? line.green : line
                return "[ #{"%2d" % displayOrdinal}] (#{"%5.3f" % object["metric"]}) #{line}"
            end
        end

        if contentItem["type"] == "line-and-body" then
          if isFocus then
                strs = contentItem["body"]
                            .lines
                            .to_a
                            .map
                            .with_index{|line, indx|
                                line = line.rstrip
                                if indx == 0 then
                                    "[*#{"%2d" % displayOrdinal}] (#{"%5.3f" % object["metric"]}) #{line[0, width]}"
                                else
                                    "              #{line[0, width]}"
                                end
                            }
                return  (strs + [ NSXDisplayUtils::makeInferfaceString(object) ]).join("\n")
            else
                line = contentItem["line"]
                line = object["isRunning"] ? line.green : line
                return "[ #{"%2d" % displayOrdinal}] (#{"%5.3f" % object["metric"]}) #{line[0, width]}"
            end
        end

        if contentItem["type"] == "block" then
            strs = contentItem["block"]
                        .lines
                        .to_a
                        .map
                        .with_index{|line, indx|
                            line = line.rstrip
                            if indx == 0 then
                                "[#{isFocus ? "*" : " "}#{"%2d" % displayOrdinal}] (#{"%5.3f" % object["metric"]}) #{line[0, width]}"
                            else
                                "              #{line[0, width]}"
                            end
                        }
            return  (strs + [ NSXDisplayUtils::makeInferfaceString(object) ]).join("\n")
        end
    end

    # NSXDisplayUtils::doPresentObjectInviteAndExecuteCommand(object)
    def self.doPresentObjectInviteAndExecuteCommand(object)
        return if object.nil?
        puts NSXDisplayUtils::makeDisplayStringForCatalystListing(object, true, 1)
        print "--> "
        command = STDIN.gets().strip

        if command == "open" or (command == '..' and object["defaultCommand"] == "open") then
            NSXGeneralCommandHandler::processCatalystCommandManager(object, "open")
            NSXDisplayUtils::doPresentObjectInviteAndExecuteCommand(object)
            return
        end

        NSXGeneralCommandHandler::processCatalystCommandManager(object, command)
    end

    # NSXDisplayUtils::doListCalaystObjectsAndSeLectedOneObjectAndInviteAndExecuteCommand(objects): Boolean
    # Return value specifies if an oject was chosen and processed
    def self.doListCalaystObjectsAndSeLectedOneObjectAndInviteAndExecuteCommand(objects)
        object = LucilleCore::selectEntityFromListOfEntitiesOrNull("object", objects, lambda{|object| NSXDisplayUtils::contentItemToAnnounce(object['contentItem']) })
        return false if object.nil?
        NSXDisplayUtils::doPresentObjectInviteAndExecuteCommand(object)
        true
    end

    # NSXDisplayUtils::verticalSize(displayStr)
    def self.verticalSize(displayStr)
        displayStr.lines.map{|line| (line.size.to_f/NSXMiscUtils::screenWidth()).ceil }.inject(0, :+)
    end
end