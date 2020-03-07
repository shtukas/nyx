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
        ["expose"]
    end

    # NSXDisplayUtils::objectInferfaceString(object)
    def self.objectInferfaceString(object)
        defaultCommand = object["defaultCommand"]
        part2 = 
            [
                object["commands"].join(" "),
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
                        object["isRunning"] ? NSXDisplayUtils::addLeftPaddingToLinesOfText(body, NSX0746_StandardPadding).green : NSXDisplayUtils::addLeftPaddingToLinesOfText(body, NSX0746_StandardPadding),
                    ]
                else
                    [
                        " ",
                       (object["isRunning"] ? body.green : body),
                    ]
                end
            else
                [
                    " ",
                   (object["isRunning"] ? announce.green : announce),
                ]
            end
        }
        
        announce = NSX1ContentsItemUtils::contentItemToAnnounce(object['contentItem'])
        body = NSX1ContentsItemUtils::contentItemToBody(object['contentItem'])
        lines = 
        if isFocus then
            [
                "[#{"*".green}#{"%2d" % displayOrdinal}]",
                " ",
                "(#{"%5.3f" % object["metric"]})"
            ] + 
            announceOrBodyLines.call(object, announce, body) +
            [
                "\n" + NSX0746_StandardPadding + NSXDisplayUtils::objectInferfaceString(object)
            ]
        else
            [
                "[ #{"%2d" % displayOrdinal}]",
                " ",
                "(#{"%5.3f" % object["metric"]})",
                " ",
                (object["isRunning"] ? (announce[0,NSXMiscUtils::screenWidth()-9]).green : announce[0,NSXMiscUtils::screenWidth()-15])
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
        NSXGeneralCommandHandler::processCatalystCommandManager(object, command)
    end

    # NSXDisplayUtils::doListCalaystObjectsAndSeLectedOneObjectAndInviteAndExecuteCommand(objects): Boolean
    # Return value specifies if an oject was chosen and processed
    def self.doListCalaystObjectsAndSeLectedOneObjectAndInviteAndExecuteCommand(objects)
        object = LucilleCore::selectEntityFromListOfEntitiesOrNull("object", objects, lambda{|object| NSX1ContentsItemUtils::contentItemToAnnounce(object['contentItem']) })
        return false if object.nil?
        NSXDisplayUtils::doPresentObjectInviteAndExecuteCommand(object)
        true
    end

    # NSXDisplayUtils::verticalSize(displayStr)
    def self.verticalSize(displayStr)
        displayStr.lines.map{|line| (line.size.to_f/NSXMiscUtils::screenWidth()).ceil }.inject(0, :+)
    end
end