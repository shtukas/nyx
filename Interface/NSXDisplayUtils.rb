
# encoding: UTF-8

FlamePadding = "              "

class NSXDisplayUtils

    # NSXDisplayUtils::contentItemToAnnounce(item)
    def self.contentItemToAnnounce(item)
        if item["type"] == "line" then
            return item["line"]
        end
        if item["type"] == "listing-and-focus" then
            return item["listing"]
        end
        "[8f854b3a] I don't know how to announce: #{JSON.generate(item)}"
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
        [
            FlamePadding[0, FlamePadding.size-1],
            defaultCommand ? "#{defaultCommand.green}" : nil,
            commands.join(" "),
            NSXDisplayUtils::defaultCatalystObjectCommands().join(" ")
        ].compact.reject{|command| command=='' }.join(" ")
    end

    # NSXDisplayUtils::objectDisplayStringForCatalystListing(object, isFocus, displayOrdinal)
    def self.objectDisplayStringForCatalystListing(object, isFocus, displayOrdinal)
        # NSXMiscUtils::screenWidth()
        contentItemToDisplayLines = lambda {|contentItem|
            if contentItem["type"] == "line" then
                return [contentItem["line"]]
            end
            if contentItem["type"] == "listing-and-focus" then
                return contentItem["focus"].lines.map{|line| line.rstrip }
            end
            [ "I don't know how to contentItemToDisplayLines: #{contentItem}" ]
        }
        displaylines = contentItemToDisplayLines.call(object["contentItem"].clone)
        if isFocus then
            firstdisplayline = displaylines.shift
            line0 = "[*#{"%2d" % displayOrdinal}] (#{"%5.3f" % object["metric"]}) " + (object["isRunning"] ? firstdisplayline.green : firstdisplayline)
            lines1 = displaylines.map{|line| FlamePadding + (object["isRunning"] ? line.green : line) }
            ([ line0 ] + lines1 + [ NSXDisplayUtils::objectInferfaceString(object) ]).join("\n")
        else
            firstdisplayline = displaylines.shift
            line0 = "[ #{"%2d" % displayOrdinal}] (#{"%5.3f" % object["metric"]}) " + (object["isRunning"] ? firstdisplayline.green : firstdisplayline)
            line0[0, NSXMiscUtils::screenWidth()-1]
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