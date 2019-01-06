#!/usr/bin/ruby

# encoding: UTF-8

=begin

(DisplayState) {
    "nsx26:object-still-to-go"          => Array[CatalystObject],
    "nsx26:lines-to-display"            => Array[String],
    "nsx26:screen-left-height"          => 10,
    "nsx26:standard-listing-position"   => Int
    "nsx26:current-position-cursor"     => Int,
    "nsx26:should-stop-display-process" => Boolean
    "nsx26:focus-object"                => nil or object
}

=end

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
        announce = NSXMiscUtils::makeGreenIfObjectRunning(announce, object["isRunning"])
        [
            "(#{"%.3f" % object["metric"]})",
            object['announce'].lines.count > 1 ? " MULTILINE:" : "",
            " #{announce}",
            NSXMiscUtils::object2DoNotShowUntilAsString(object),
        ].join()
    end

    # NSXDisplayUtils::objectInferfaceString(object)
    def self.objectInferfaceString(object)
        announce = object['announce'].strip
        part2 = 
            [
                " #{object["commands"].join(" ")}",
                object["defaultExpression"] ? " (#{object["defaultExpression"].green})" : ""
            ].join()
        part2.strip
    end

    # NSXDisplayUtils::objectToMultipleLinesForCatalystListings(object, position, standardlp)
    def self.objectToMultipleLinesForCatalystListings(object, position, standardlp)
        addLeftPadding = lambda{|string, padding|
            string
                .lines
                .map{|line| padding+line }
                .join()
        }
        [
            "(#{"%.3f" % object["metric"]}) #{NSXMiscUtils::object2DoNotShowUntilAsString(object)}",
            NSXMiscUtils::makeGreenIfObjectRunning(addLeftPadding.call(object['announce'], "               "),object["isRunning"]),
        ].join("\n")
    end

    # NSXDisplayUtils::objectToStringForCatalystListing(object, position, standardlp)
    def self.objectToStringForCatalystListing(object, position, standardlp)
        if position == standardlp then
            if object['announce'].lines.to_a.size > 1 then
                [
                    NSXDisplayUtils::positionPrefix(standardlp, position),
                    " ",
                    NSXDisplayUtils::objectToMultipleLinesForCatalystListings(object, position, standardlp),
                    "\n",
                    "              " + NSXDisplayUtils::objectInferfaceString(object)
                ].join("")
            else
                [
                   NSXDisplayUtils::positionPrefix(standardlp, position),
                   " ",
                   NSXDisplayUtils::objectToOneLineForCatalystDisplay(object),
                   "\n",
                   "               " + NSXDisplayUtils::objectInferfaceString(object)
                ].join("")
            end
        else
            [
               NSXDisplayUtils::positionPrefix(standardlp, position),
               " ",
               NSXDisplayUtils::objectToOneLineForCatalystDisplay(object)[0,NSXMiscUtils::screenWidth()-9]
            ].join("")
        end
    end

    # NSXDisplayUtils::doPresentObjectInviteAndExecuteCommand(object)
    def self.doPresentObjectInviteAndExecuteCommand(object)
        return if object.nil?
        puts NSXDisplayUtils::objectToOneLineForCatalystDisplay(object)
        puts NSXDisplayUtils::objectInferfaceString(object)
        print "--> "
        command = STDIN.gets().strip
        command = command.size>0 ? command : ( object["defaultExpression"] ? object["defaultExpression"] : "" )
        NSXGeneralCommandHandler::processCommand(object, command)
    end

    # NSXDisplayUtils::doListCalaystObjectsAndSeLectedOneObjectAndInviteAndExecuteCommand(objects)
    def self.doListCalaystObjectsAndSeLectedOneObjectAndInviteAndExecuteCommand(objects)
        object = LucilleCore::selectEntityFromListOfEntitiesOrNull("object:", objects, lambda{|object| NSXDisplayUtils::objectToOneLineForCatalystDisplay(object) })
        return if object.nil?
        puts NSXDisplayUtils::objectToOneLineForCatalystDisplay(object)
        puts NSXDisplayUtils::objectInferfaceString(object)
        print "--> "
        command = STDIN.gets().strip
        command = command.size>0 ? command : ( object["defaultExpression"] ? object["defaultExpression"] : "" )
        NSXGeneralCommandHandler::processCommand(object, command)
    end

end