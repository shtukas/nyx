
# encoding: UTF-8

NSX0746_StandardPadding = "              "

class NSXDisplayUtils

    # NSXDisplayUtils::contentItemToAnnounce(item)
    def self.contentItemToAnnounce(item)
        if item["type"] == "line" then
            return item["line"]
        end
        if item["type"] == "lines" then
            return (item["lines"][0] || "contentItem of type lines needs at least one line")
        end
        if item["type"] == "line-and-body" then
            return item["line"]
        end
        "[8f854b3a] I don't know how to announce: #{JSON.generate(item)}"
    end

    # NSXDisplayUtils::contentItemToBody(item)
    def self.contentItemToBody(item)
        if item["type"] == "line" then
            return item["line"]
        end
        if item["type"] == "line-and-body" then
            return item["body"]
        end
        "[09bab884] I don't know how to body: #{JSON.generate(item)}"
    end

    # NSXDisplayUtils::addLeftPaddingToLinesOfText(text, padding)
    def self.addLeftPaddingToLinesOfText(text, padding)
        text.lines.map{|line| padding+line }.join()
    end

    # NSXDisplayUtils::defaultCatalystObjectCommands()
    def self.defaultCatalystObjectCommands()
        ["expose", "note"]
    end

    # NSXDisplayUtils::objectInferfaceString(object)
    def self.objectInferfaceString(object)
        defaultCommand = object["defaultCommand"]
        commands = object["commands"]
        if defaultCommand then
            commands = commands.reject{|c| c == defaultCommand }
        end
        part2 = 
            [
                defaultCommand ? "#{defaultCommand.green}" : nil,
                commands.join(" "),
                NSXDisplayUtils::defaultCatalystObjectCommands().join(" ")
            ].compact.reject{|command| command=='' }.join(" ")
        part2.strip
    end

    # NSXDisplayUtils::objectDisplayStringForCatalystListing(object, isFocus, displayOrdinal)
    def self.objectDisplayStringForCatalystListing(object, isFocus, displayOrdinal)
        # NSXMiscUtils::screenWidth()
        contentItemToCoreLines = lambda {|contentItem|
            if contentItem["type"] == "line" then
                return [contentItem["line"]]
            end
            if contentItem["type"] == "lines" then
                return contentItem["lines"]
            end
            if contentItem["type"] == "line-and-body" then
                return contentItem["line"] + contentItem["body"].lines.map{|line| line[0, line.size-1] } # the map is to remove the ending line return
            end
            [ "I don't know how to contentItemToCoreLines: #{contentItem}" ]
        }
        getNoteLines = lambda{|objectuuid|
            if NSXMiscUtils::hasXNote(objectuuid) then
                [ "-- note ---------------------------------------" ] +
                NSXMiscUtils::getXNoteOrNull(object["uuid"]).lines.first(10).map{|line| line[0, line.size-1] } +
                [ "-----------------------------------------------" ]
            else
                []
            end
        }
        corelines = contentItemToCoreLines.call(object["contentItem"])
        if isFocus then
            firstcoreline = corelines.shift + (NSXMiscUtils::hasXNote(object["uuid"]) ? " [note]" : "")
            answerline0 = "[ #{"%2d" % displayOrdinal}] (#{"%5.3f" % object["metric"]}) " + (object["isRunning"] ? firstcoreline.green : firstcoreline)
            answerlinesOnePlus = corelines.map{|line| NSX0746_StandardPadding + (object["isRunning"] ? line.green : line) }
            ([ answerline0 ] +  getNoteLines.call(object["uuid"]).map{|line| NSX0746_StandardPadding + line }.map{|line| object["isRunning"] ? line.green : line } + answerlinesOnePlus + [ NSX0746_StandardPadding + NSXDisplayUtils::objectInferfaceString(object)]).join("\n")
        else
            firstcoreline = corelines.shift + (NSXMiscUtils::hasXNote(object["uuid"]) ? " [note]" : "")
            answerline0 = "[ #{"%2d" % displayOrdinal}] (#{"%5.3f" % object["metric"]}) " + (object["isRunning"] ? firstcoreline.green : firstcoreline)
            answerline0
        end
    end

    # NSXDisplayUtils::doPresentObjectInviteAndExecuteCommand(object)
    def self.doPresentObjectInviteAndExecuteCommand(object)
        return if object.nil?
        puts NSXDisplayUtils::objectDisplayStringForCatalystListing(object, true, 1)
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