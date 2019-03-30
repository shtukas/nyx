#!/usr/bin/ruby

# encoding: UTF-8

class NSXDisplayUtils

    # NSXDisplayUtils::positionPrefix(standardlp, position)
    def self.positionPrefix(standardlp, position)
        if standardlp and position and standardlp==position then
            "[* #{"%2d" % position}]"
        else
            if position then
                "[  #{"%2d" % position}]"
            else
                "[]"
            end
        end
    end

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

    # NSXDisplayUtils::objectToStringForCatalystListing(object, position, standardlp)
    def self.objectToStringForCatalystListing(object, position, standardlp)
        if position == standardlp then
            planningText = NSXMiscUtils::getPlanningText(object["uuid"])
            hasPlanningText = planningText.strip.size>0

            if object['announce'].lines.to_a.size > 1 then
                [
                    NSXDisplayUtils::positionPrefix(standardlp, position) + " " + NSXDisplayUtils::objectToMultipleLinesForCatalystListings(object),
                    "\n" + "              " + NSXDisplayUtils::objectInferfaceString(object) + ( NSXMiscUtils::objectIsDoneOnEmptyCommand(object) ? " [ DONE ON EMPTY COMMAND ]".green : "" ),
                    ( hasPlanningText ? ("               " + "planning".green) : "" )
                ].join()
            else
                [
                   NSXDisplayUtils::positionPrefix(standardlp, position) + " " + NSXDisplayUtils::objectToOneLineForCatalystDisplay(object),
                   "\n" + "               " + NSXDisplayUtils::objectInferfaceString(object) + ( NSXMiscUtils::objectIsDoneOnEmptyCommand(object) ? " [ DONE ON EMPTY COMMAND ]".green : "" ),
                   ( hasPlanningText ? ("\n" + "               " + "planning".green) : "" )
                ].join()
            end
        else
            NSXDisplayUtils::positionPrefix(standardlp, position) + " " + NSXDisplayUtils::objectToOneLineForCatalystDisplay(object)[0,NSXMiscUtils::screenWidth()-9]
        end
    end

    # NSXDisplayUtils::doPresentObjectInviteAndExecuteCommand(object)
    def self.doPresentObjectInviteAndExecuteCommand(object)
        return if object.nil?
        puts NSXDisplayUtils::objectToStringForCatalystListing(object, nil, nil)
        puts NSXDisplayUtils::objectInferfaceString(object)
        print "--> "
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