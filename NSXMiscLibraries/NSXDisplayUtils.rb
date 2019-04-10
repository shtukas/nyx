#!/usr/bin/ruby

# encoding: UTF-8

NSX0746_StandardPadding = "        "

class NSXDisplayUtils

    # NSXDisplayUtils::addLeftPaddingToLinesOfText(text, padding)
    def self.addLeftPaddingToLinesOfText(text, padding)
        text.lines.map{|line| padding+line }.join()
    end

    # NSXDisplayUtils::objectInferfaceString(object)
    def self.objectInferfaceString(object)
        announce = object['announce'].strip
        part2 = 
            [
                object["commands"] ? " #{object["commands"].join(" ")}" : '',
                object["defaultExpression"] ? " (#{object["defaultExpression"].green})" : ""
            ].join()
        part2.strip
    end

    # NSXDisplayUtils::objectCatalystListingDisplayString(object, isFocus, displayOrdinal)
    def self.objectCatalystListingDisplayString(object, isFocus, displayOrdinal)
        object["commands"] = object["commands"].reject{|command| command.include?('planning') }
        object["commands"] = ( NSXMiscUtils::hasPlanningText(object["uuid"]) ? ["planning".green] : ["planning".yellow] ) + object["commands"]
        if isFocus then
            if object['body'] then
                [
                    "[#{isFocus ? "*".green : " "}#{"%2d" % displayOrdinal}]",
                    " ",
                    "(#{"%5.3f" % object["metric"]})",
                    "\n",
                    object["isRunning"] ? NSXDisplayUtils::addLeftPaddingToLinesOfText(object['body'], NSX0746_StandardPadding).green : NSXDisplayUtils::addLeftPaddingToLinesOfText(object['body'], NSX0746_StandardPadding),
                    "\n" + NSX0746_StandardPadding + NSXDisplayUtils::objectInferfaceString(object),
                ].join()
            else
                [
                    "[#{isFocus ? "*".green : " "}#{"%2d" % displayOrdinal}]",
                    " ",
                    "(#{"%5.3f" % object["metric"]})",
                    " ",
                   (object["isRunning"] ? object['announce'].green : object['announce']),
                   "\n" + NSX0746_StandardPadding + NSXDisplayUtils::objectInferfaceString(object),
                ].join()
            end
        else
            [
                "[#{isFocus ? "*".green : " "}#{"%2d" % displayOrdinal}]",
                " ",
                "(#{"%5.3f" % object["metric"]})",
                " ",
                (object["isRunning"] ? (object['announce'][0,NSXMiscUtils::screenWidth()-9]).green : object['announce'][0,NSXMiscUtils::screenWidth()-15])
            ].join()
        end
    end

    # NSXDisplayUtils::doPresentObjectInviteAndExecuteCommand(object)
    def self.doPresentObjectInviteAndExecuteCommand(object)
        return if object.nil?
        puts NSXDisplayUtils::objectCatalystListingDisplayString(object, true, 1)
        print "-->(2) "
        command = STDIN.gets().strip
        command = command.size>0 ? command : ( object["defaultExpression"] ? object["defaultExpression"] : "" )
        NSXGeneralCommandHandler::processCommand(object, command)
    end

    # NSXDisplayUtils::doListCalaystObjectsAndSeLectedOneObjectAndInviteAndExecuteCommand(objects): Boolean
    # Return value specifies if an oject was chosen and processed
    def self.doListCalaystObjectsAndSeLectedOneObjectAndInviteAndExecuteCommand(objects)
        object = LucilleCore::selectEntityFromListOfEntitiesOrNull("object", objects, lambda{|object| object['announce'] })
        return false if object.nil?
        NSXDisplayUtils::doPresentObjectInviteAndExecuteCommand(object)
        true
    end

    # NSXDisplayUtils::verticalSize(displayStr)
    def self.verticalSize(displayStr)
        displayStr.lines.map{|line| (line.size.to_f/NSXMiscUtils::screenWidth()).ceil }.inject(0, :+)
    end
end