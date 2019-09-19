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
        ["expose", "metadata"]
    end

    # NSXDisplayUtils::agentCommands(object)
    def self.agentCommands(object)
        agentdata = NSXBob::getAgentDataByAgentUUIDOrNull(object["agentuid"])
        raise "Error: 0b00c9b7" if agentdata.nil?
        agentdata["agent-commands"].call()
    end

    # NSXDisplayUtils::objectInferfaceString(object)
    def self.objectInferfaceString(object)
        scheduleStoreItemId = object["scheduleStoreItemId"]
        scheduleStoreItem = NSXScheduleStore::getItemOrNull(scheduleStoreItemId)
        raise "Error: e34954d5" if scheduleStoreItem.nil?
        defaultCommand = NSXScheduleStoreUtils::scheduleStoreItemToDefaultCommandOrNull(scheduleStoreItemId, scheduleStoreItem)
        part2 = 
            [
                NSXMiscUtils::hasXNote(object["uuid"]) ? nil : "note".yellow,
                NSXScheduleStoreUtils::scheduleStoreItemToCommands(scheduleStoreItem).join(" "),
                NSXDisplayUtils::agentCommands(object).join(" "),
                NSXDisplayUtils::defaultCatalystObjectCommands().join(" "),
                defaultCommand ? "(#{defaultCommand.green})" : nil
            ].compact.reject{|command| command=='' }.join(" ")
        part2.strip
    end

    # NSXDisplayUtils::objectDisplayStringForCatalystListing(object, isFocus, displayOrdinal)
    def self.objectDisplayStringForCatalystListing(object, isFocus, displayOrdinal)

        announceOrBodyLines = lambda{|object, announce, body|
            if body then
                if body.lines.size>1 then
                    [
                        "\n",
                        object["decoration:isRunning"] ? NSXDisplayUtils::addLeftPaddingToLinesOfText(body, NSX0746_StandardPadding).green : NSXDisplayUtils::addLeftPaddingToLinesOfText(body, NSX0746_StandardPadding),
                    ]
                else
                    [
                        " ",
                       (object["decoration:isRunning"] ? body.green : body),
                    ]
                end
            else
                [
                    " ",
                   (object["decoration:isRunning"] ? announce.green : announce),
                ]
            end
        }

        xnoteForPrint = lambda{|objectuuid|
            "\n              " + "note".green + ":\n" + NSXMiscUtils::getXNote(objectuuid).lines.first(10).map{|line| (" " * 22)+line }.join()
        }

        announce = NSXContentStoreUtils::contentStoreItemIdToAnnounceOrNull(object['contentStoreItemId'])
        body = NSXContentStoreUtils::contentStoreItemIdToBodyOrNull(object['contentStoreItemId'])
        lines = 
        if isFocus then
            [
                "[#{"*".green}#{"%2d" % displayOrdinal}]",
                " ",
                "(#{"%5.3f" % object["decoration:metric"]})"
            ] + 
            announceOrBodyLines.call(object, announce, body) +
            [
                NSXMiscUtils::hasXNote(object["uuid"]) ? xnoteForPrint.call(object["uuid"]) : "",
                "\n" + NSX0746_StandardPadding + NSXDisplayUtils::objectInferfaceString(object)
            ]
        else
            [
                "[ #{"%2d" % displayOrdinal}]",
                " ",
                "(#{"%5.3f" % object["decoration:metric"]})",
                " ",
                (object["decoration:isRunning"] ? (announce[0,NSXMiscUtils::screenWidth()-9]).green : announce[0,NSXMiscUtils::screenWidth()-15])
            ]
        end
        lines.join()
    end

    # NSXDisplayUtils::doPresentObjectInviteAndExecuteCommand(object)
    def self.doPresentObjectInviteAndExecuteCommand(object)
        return if object.nil?
        puts NSXDisplayUtils::objectDisplayStringForCatalystListing(object, true, 1)
        print "--> "
        command = STDIN.gets().strip
        NSXGeneralCommandHandler::processCatalystCommandManager(object, command, true)
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