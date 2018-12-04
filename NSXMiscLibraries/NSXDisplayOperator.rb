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

    # NSXDisplayOperator::positionPrefix(standardlp, position)
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

    # NSXDisplayOperator::objectInferfaceString(object)
    def self.objectInferfaceString(object)
        announce = object['announce'].strip
        defaultExpressionAsString = object["default-expression"] ? object["default-expression"] : ""
        part2 = 
            [
                " (#{object["commands"].join(" ").green})",
                " \"#{defaultExpressionAsString.green}\""
            ].join()
        part2.strip
    end

    # NSXDisplayOperator::objectToMultipleLinesForCatalystListings(object, position, standardlp)
    def self.objectToMultipleLinesForCatalystListings(object, position, standardlp)
        addLeftPadding = lambda{|string, padding|
            string
                .lines
                .map{|line| padding+line }
                .join()
        }
        [
            "(#{"%.3f" % object["metric"]}) #{NSXMiscUtils::object2DoNotShowUntilAsString(object)}",
            NSXMiscUtils::addMetricDrivenColoursToString(addLeftPadding.call(object['announce'], "               "),object["metric"]),
        ].join("\n")
    end

    # NSXDisplayOperator::objectToStringForCatalystListing(object, position, standardlp)
    def self.objectToStringForCatalystListing(object, position, standardlp)
        if position == standardlp then
            if object['announce'].lines.to_a.size > 1 then
                [
                    NSXDisplayOperator::positionPrefix(standardlp, position),
                    " ",
                    NSXDisplayOperator::objectToMultipleLinesForCatalystListings(object, position, standardlp),
                    "\n",
                    "              " + NSXDisplayOperator::objectInferfaceString(object)
                ].join("")
            else
                [
                   NSXDisplayOperator::positionPrefix(standardlp, position),
                   " ",
                   NSXMiscUtils::objectToOneLineForCatalystDisplay(object),
                   "\n",
                   "               " + NSXDisplayOperator::objectInferfaceString(object)
                ].join("")
            end
        else
            [
               NSXDisplayOperator::positionPrefix(standardlp, position),
               " ",
               NSXMiscUtils::objectToOneLineForCatalystDisplay(object)[0,NSXMiscUtils::screenWidth()-9]
            ].join("")
        end
    end

    # NSXDisplayOperator::doPresentObjectInviteAndExecuteCommand(object)
    def self.doPresentObjectInviteAndExecuteCommand(object)
        return if object.nil?
        puts NSXMiscUtils::objectToOneLineForCatalystDisplay(object)
        puts NSXDisplayOperator::objectInferfaceString(object)
        print "--> "
        command = STDIN.gets().strip
        command = command.size>0 ? command : ( object["default-expression"] ? object["default-expression"] : "" )
        NSXGeneralCommandHandler::processCommand(object, command)
    end

end