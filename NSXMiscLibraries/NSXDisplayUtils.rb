#!/usr/bin/ruby

# encoding: UTF-8

class NSXDisplayUtils

    # NSXDisplayUtils::objectToOneLineForCatalystDisplay(object)
    def self.objectToOneLineForCatalystDisplay(object)
        announce = (object['announce'].lines.first || "").strip
        announce = NSXMiscUtils::makeGreenIfObjectRunning(announce, object["prioritization"]=="running")
        [
            object['announce'].lines.count > 1 ? "MULTILINE: " : "",
            "#{announce}",
            NSXMiscUtils::object2DoNotShowUntilAsString(object),
        ].join()
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

    # NSXDisplayUtils::objectToMultipleLinesForCatalystListings(object)
    def self.objectToMultipleLinesForCatalystListings(object)
        controlAnnounceHeight = lambda{|text, object, screenHeight|
            if object["agentuid"]=="d2de3f8e-6cf2-46f6-b122-58b60b2a96f1" and object["generic-content-item"]["type"]=="email" then
                targetHeight = [10, (0.7*screenHeight).to_i].max
                text.lines.first(targetHeight).join()
            else
                text
            end
        }
        [
            NSXMiscUtils::object2DoNotShowUntilAsString(object),
            NSXMiscUtils::makeGreenIfObjectRunning(controlAnnounceHeight.call(object['announce'], object, NSXMiscUtils::screenHeight()) ,object["prioritization"]=="running")
        ].compact.join("\n")
    end

    # NSXDisplayUtils::objectToStringForCatalystListing(object, isFocus)
    def self.objectToStringForCatalystListing(object, isFocus)
        object["commands"] = object["commands"].reject{|command| command.include?('planning') }
        object["commands"] = ( NSXMiscUtils::hasPlanningText(object["uuid"]) ? ["planning".green] : ["planning".yellow] ) + object["commands"]
        if isFocus then
            if object['body'] then
                [
                    object['body'],
                    "\n" + "              " + NSXDisplayUtils::objectInferfaceString(object),
                ].join()
            else
                [
                    "[] ",
                   object['announce'],
                   "\n" + "               " + NSXDisplayUtils::objectInferfaceString(object),
                ].join()
            end
        else
            "[] "+object['announce'][0,NSXMiscUtils::screenWidth()-9]
        end
    end

    # NSXDisplayUtils::doPresentObjectInviteAndExecuteCommand(object)
    def self.doPresentObjectInviteAndExecuteCommand(object)
        return if object.nil?
        puts NSXDisplayUtils::objectToStringForCatalystListing(object, true)
        puts NSXDisplayUtils::objectInferfaceString(object)
        print "-->(2) "
        command = STDIN.gets().strip
        command = command.size>0 ? command : ( object["defaultExpression"] ? object["defaultExpression"] : "" )
        NSXGeneralCommandHandler::processCommand(object, command)
    end

    # NSXDisplayUtils::doListCalaystObjectsAndSeLectedOneObjectAndInviteAndExecuteCommand(objects): Boolean
    # Return value specifies if an oject was chosen and processed
    def self.doListCalaystObjectsAndSeLectedOneObjectAndInviteAndExecuteCommand(objects)
        object = LucilleCore::selectEntityFromListOfEntitiesOrNull("object", objects, lambda{|object| NSXDisplayUtils::objectToOneLineForCatalystDisplay(object) })
        return false if object.nil?
        NSXDisplayUtils::doPresentObjectInviteAndExecuteCommand(object)
        true
    end

    # NSXDisplayUtils::verticalSize(displayStr)
    def self.verticalSize(displayStr)
        displayStr.lines.map{|line| (line.size.to_f/NSXMiscUtils::screenWidth()).ceil }.inject(0, :+)
    end

end