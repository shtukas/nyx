
# encoding: UTF-8

NSX0746_StandardPadding = "              "

class NSXDisplayUtils

    # NSXDisplayUtils::contentItemToAnnounce(item)
    def self.contentItemToAnnounce(item)
        if item["type"] == "line" then
            return item["line"]
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
        announce = NSXDisplayUtils::contentItemToAnnounce(object['contentItem'])
        body = NSXDisplayUtils::contentItemToBody(object['contentItem'])
        onFocusObjectPrefix = lambda{ |displayOrdinal, object|
            "[#{"*".green}#{"%2d" % displayOrdinal}] (#{"%5.3f" % object["metric"]})"
        }
        onFocusPossiblyLineReturnPrefixedObjectDisplayText = lambda{|object, announce, body|
            if body then
                if body.lines.size>1 then
                    "\n#{object["isRunning"] ? NSXDisplayUtils::addLeftPaddingToLinesOfText(body, NSX0746_StandardPadding).green : NSXDisplayUtils::addLeftPaddingToLinesOfText(body, NSX0746_StandardPadding)}"
                else
                    " #{(object["isRunning"] ? body.green : body)}"
                end
            else
                " #{(object["isRunning"] ? announce.green : announce)}"
            end
        }
        onFocusObjectNoteDisplayOrNull = lambda {|prefix, object|
            if NSXMiscUtils::hasXNote(object["uuid"]) and NSXMiscUtils::getXNoteOrNull(object["uuid"]).strip.size>0 then
                text = [
                    prefix,
                    "-- note ---------------------------------------\n",
                    NSXMiscUtils::getXNoteOrNull(object["uuid"]).lines.first(10).join() + "\n",
                    "-----------------------------------------------"
                ].join()
                NSXDisplayUtils::addLeftPaddingToLinesOfText(text, NSX0746_StandardPadding)
            else
                nil
            end
        }
        onFocusLineReturnPrefixedObjectSuffix = lambda {|object|
            [
                onFocusObjectNoteDisplayOrNull.call("\n", object),
                "\n", 
                NSX0746_StandardPadding,
                NSXDisplayUtils::objectInferfaceString(object)
            ].compact.join()
        }
        if isFocus then
            onFocusObjectPrefix.call(displayOrdinal, object) + onFocusPossiblyLineReturnPrefixedObjectDisplayText.call(object, announce, body) + onFocusLineReturnPrefixedObjectSuffix.call(object)
        else
            announce = "#{announce}#{NSXMiscUtils::hasXNote(object["uuid"]) ? " [note]" : ""}"
            "[ #{"%2d" % displayOrdinal}] (#{"%5.3f" % object["metric"]}) #{(object["isRunning"] ? (announce[0,NSXMiscUtils::screenWidth()-9]).green : announce[0,NSXMiscUtils::screenWidth()-15])}"
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