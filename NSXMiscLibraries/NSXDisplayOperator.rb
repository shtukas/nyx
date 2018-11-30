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

class NSXDisplayOperator

    # NSXDisplayOperator::doPresentObjectInviteAndExecuteCommand(object)
    def self.doPresentObjectInviteAndExecuteCommand(object)
        return if object.nil?
        puts NSXMiscUtils::objectToString(object)
        puts NSXDisplayOperator::objectInferfaceString(object)
        print "--> "
        command = STDIN.gets().strip
        command = command.size>0 ? command : ( object["default-expression"] ? object["default-expression"] : "" )
        NSXGeneralCommandHandler::processCommand(object, command)
    end

    # NSXDisplayOperator::positionPrefixForMailListingDisplay(standardlp, position)
    def self.positionPrefixForMailListingDisplay(standardlp, position)
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

    # NSXDisplayOperator::objectInferfaceString(object)
    def self.objectInferfaceString(object)
        announce = object['announce'].strip
        defaultExpressionAsString = object["default-expression"] ? object["default-expression"] : ""
        part2 = 
            [
                " (#{object["commands"].join(" ").red})",
                " \"#{defaultExpressionAsString.green}\""
            ].join()
        part2.strip
    end

    # NSXDisplayOperator::objectToString(object)
    def self.objectToString(object)
        announce = object['announce'].strip
        defaultExpressionAsString = object["default-expression"] ? object["default-expression"] : ""
        part1 = 
            [
                "(#{"%.3f" % object["metric"]})",
                " [#{object["uuid"]}]",
                " #{announce}",
            ].join()
        if object["is-running"] then
            part1 = part1.green
        end
        part2 = NSXDisplayOperator::objectInferfaceString(object)
        part1 + part2
    end

    # NSXDisplayOperator::objectToLineForMainListing(object, position, standardlp)
    def self.objectToLineForMainListing(object, position, standardlp)
        if position == standardlp then
            [
                "#{NSXDisplayOperator::positionPrefixForMailListingDisplay(standardlp, position)} #{NSXMiscUtils::objectToString(object)}",
                "               " + NSXDisplayOperator::objectInferfaceString(object)
            ].join("\n")
        else
            "#{NSXDisplayOperator::positionPrefixForMailListingDisplay(standardlp, position)} #{NSXMiscUtils::objectToString(object)[0,NSXMiscUtils::screenWidth()-9]}"
        end
    end

end