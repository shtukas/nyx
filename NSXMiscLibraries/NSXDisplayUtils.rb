#!/usr/bin/ruby

# encoding: UTF-8

NSX0746_StandardPadding = "              "

class NSXDisplayUtils

    # NSXDisplayUtils::addLeftPaddingToLinesOfText(text, padding)
    def self.addLeftPaddingToLinesOfText(text, padding)
        text.lines.map{|line| padding+line }.join()
    end

    # NSXDisplayUtils::defaultCatalystObjectCommands()
    def self.defaultCatalystObjectCommands()
        # This doesn't include x-note
        ["expose"]
    end

    # NSXDisplayUtils::agentCommands(object)
    def self.agentCommands(object)
        agentdata = NSXBob::getAgentDataByAgentUUIDOrNull(object["agentuid"])
        raise "Error: 0b00c9b7" if agentdata.nil?
        agentdata["agent-commands"].call()
    end

    # NSXDisplayUtils::objectInferfaceString(object)
    def self.objectInferfaceString(object)
        scheduleStoreItem = NSXScheduleStore::getItemOrNull(object["scheduleStoreItemId"])
        raise "Error: e34954d5" if scheduleStoreItem.nil?
        scheduleStoreCommands = NSXScheduleStoreUtils::scheduleStoreItemToCommands(object["uuid"], scheduleStoreItem)
        part2 = 
            [
                NSXMiscUtils::hasXNote(object["uuid"]) ? "x-note".green : "x-note".yellow,
                NSXScheduleStoreUtils::scheduleStoreItemToCommands(object["uuid"], scheduleStoreItem).join(" "),
                NSXDisplayUtils::agentCommands(object).join(" "),
                NSXDisplayUtils::defaultCatalystObjectCommands().join(" "),
                object["defaultCommand"] ? "(#{object["defaultCommand"].green})" : ""
            ].join(" ")
        part2.strip
    end

    # NSXDisplayUtils::objectDisplayStringForCatalystListing(object, isFocus, displayOrdinal)
    def self.objectDisplayStringForCatalystListing(object, isFocus, displayOrdinal)
        announce = NSXContentStoreUtils::contentStoreItemIdToAnnounceOrNull(object['contentStoreItemId'])
        body = NSXContentStoreUtils::contentStoreItemIdToBodyOrNull(object['contentStoreItemId'])
        if isFocus then
            if body then
                if body.lines.size>1 then
                    [
                        "[#{"*".green}#{"%2d" % displayOrdinal}]",
                        " ",
                        "(#{"%5.3f" % object["metric"]})",
                        "\n",
                        object["isRunning"] ? NSXDisplayUtils::addLeftPaddingToLinesOfText(body, NSX0746_StandardPadding).green : NSXDisplayUtils::addLeftPaddingToLinesOfText(body, NSX0746_StandardPadding),
                        "\n" + NSX0746_StandardPadding + NSXDisplayUtils::objectInferfaceString(object),
                    ].join()
                else
                    [
                        "[#{"*".green}#{"%2d" % displayOrdinal}]",
                        " ",
                        "(#{"%5.3f" % object["metric"]})",
                        " ",
                       (object["isRunning"] ? body.green : body),
                       "\n" + NSX0746_StandardPadding + NSXDisplayUtils::objectInferfaceString(object),
                    ].join()
                end
            else
                [
                    "[#{"*".green}#{"%2d" % displayOrdinal}]",
                    " ",
                    "(#{"%5.3f" % object["metric"]})",
                    " ",
                   (object["isRunning"] ? announce.green : announce),
                   "\n" + NSX0746_StandardPadding + NSXDisplayUtils::objectInferfaceString(object),
                ].join()
            end
        else
            [
                "[ #{"%2d" % displayOrdinal}]",
                " ",
                "(#{"%5.3f" % object["metric"]})",
                " ",
                (object["isRunning"] ? (announce[0,NSXMiscUtils::screenWidth()-9]).green : announce[0,NSXMiscUtils::screenWidth()-15])
            ].join()
        end
    end

    # NSXDisplayUtils::doPresentObjectInviteAndExecuteCommand(object)
    def self.doPresentObjectInviteAndExecuteCommand(object)
        return if object.nil?
        puts NSXDisplayUtils::objectDisplayStringForCatalystListing(object, true, 1)
        print "-->(object: command only) "
        command = STDIN.gets().strip
        NSXGeneralCommandHandler::processCommandAgainstCatalystObject(object, command)
    end

    # NSXDisplayUtils::doListCalaystObjectsAndSeLectedOneObjectAndInviteAndExecuteCommand(objects): Boolean
    # Return value specifies if an oject was chosen and processed
    def self.doListCalaystObjectsAndSeLectedOneObjectAndInviteAndExecuteCommand(objects)
        object = LucilleCore::selectEntityFromListOfEntitiesOrNull("object", objects, lambda{|object| NSXContentStoreUtils::contentStoreItemIdToAnnounceOrNull(object['contentStoreItemId']) })
        return false if object.nil?
        NSXDisplayUtils::doPresentObjectInviteAndExecuteCommand(object)
        true
    end

    # NSXDisplayUtils::verticalSize(displayStr)
    def self.verticalSize(displayStr)
        displayStr.lines.map{|line| (line.size.to_f/NSXMiscUtils::screenWidth()).ceil }.inject(0, :+)
    end
end