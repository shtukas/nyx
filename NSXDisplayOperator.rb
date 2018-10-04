#!/usr/bin/ruby

# encoding: UTF-8

=begin

(DisplayState) {
    "nsx26:all-catalyst-objects"        => Array[CatalystObject],
    "nsx26:objects-already-processed"   => Array[CatalystObject],
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

    # NSXDisplayOperator::newDisplayState(displayState)
	def self.newDisplayState(displayState)
        newDisplayState = {}
        newDisplayState["nsx26:all-catalyst-objects"] = displayState["nsx26:all-catalyst-objects"].map{|o| o.clone }
        newDisplayState["nsx26:objects-already-processed"] = displayState["nsx26:objects-already-processed"].map{|o| o.clone }
        newDisplayState["nsx26:object-still-to-go"] = displayState["nsx26:object-still-to-go"].map{|o| o.clone }
        newDisplayState["nsx26:lines-to-display"] = displayState["nsx26:lines-to-display"].clone
        newDisplayState["nsx26:screen-left-height"] = displayState["nsx26:screen-left-height"]
        newDisplayState["nsx26:standard-listing-position"] = displayState["nsx26:standard-listing-position"]
        newDisplayState["nsx26:current-position-cursor"] = displayState["nsx26:current-position-cursor"]
        newDisplayState["nsx26:should-stop-display-process"] = displayState["nsx26:should-stop-display-process"]
        newDisplayState["nsx26:focus-object"] = displayState["nsx26:focus-object"] ? displayState["nsx26:focus-object"].clone : nil
        newDisplayState
	end

    # NSXDisplayOperator::makeGenesysDisplayState()
    def self.makeGenesysDisplayState(screenLeftHeight, standardlp) # : DisplayState
        objects = NSXMiscUtils::flockObjectsProcessedForCatalystDisplay()
        combinedTimeProtonObjectUUID = NSXCatalystMetadataInterface::lightThreadsAllCatalystObjectsUUIDs()
        regularObjects, lightThreadObjects = objects.partition {|object| !combinedTimeProtonObjectUUID.include?(object["uuid"]) }
        {
            "nsx26:all-catalyst-objects"             => objects,
            "nsx26:objects-already-processed"        => [],
            "nsx26:object-still-to-go"               => regularObjects.sort{|o1,o2| o1['metric']<=>o2['metric'] }.reverse,
            "nsx26:lines-to-display"                 => [],
            "nsx26:screen-left-height"               => screenLeftHeight,
            "nsx26:standard-listing-position"        => standardlp,
            "nsx26:current-position-cursor"          => 0,
            "nsx26:should-stop-display-process"      => false,
            "nsx26:focus-object"                     => nil
        }
    end

    # NSXDisplayOperator::displayStateTransition(displayState: DisplayState) : DisplayState
    def self.displayStateTransition(displayState) # return: DisplayState

        displayState["nsx26:current-position-cursor"] = displayState["nsx26:current-position-cursor"]+1
        displayState["nsx26:lines-to-display"] = []

        if displayState["nsx26:object-still-to-go"].size==0 then
            displayState["nsx26:should-stop-display-process"] = true
            return displayState
        end

        object = displayState["nsx26:object-still-to-go"].shift

        return nil if object["metric"] < 0.2 

        # --------------------------------------------------------------------------------
        if NSXBob::agentuuid2AgentDataOrNull(object["agent-uid"]).nil? then
            NSXCatalystObjectsOperator::processAgentProcessorSignal(["remove", object["uuid"]])
            return nil
        end

        # --------------------------------------------------------------------------------
        # Sometimes a wave item that is an email, gets deleted by the NSXEmailClients process.
        # In such a case they are still in Flock and should not be showed
        if object["agent-uid"]=="283d34dd-c871-4a55-8610-31e7c762fb0d" then
            if object["schedule"][":wave-email:"] then
                if !File.exists?(object["item-data"]["folderpath"]) then
                    NSXGeneralCommandHandler::processCommand(object, "done")
                    return NSXDisplayOperator::displayStateTransition(displayState)
                end
            end
        end

        displayState["nsx26:objects-already-processed"] << object
        displayState["nsx26:lines-to-display"] << NSXDisplayOperator::objectToColoredLineForMainListing(object, displayState["nsx26:current-position-cursor"], displayState["nsx26:standard-listing-position"])
        displayState["nsx26:screen-left-height"] = displayState["nsx26:screen-left-height"] - 1 

        if displayState["nsx26:current-position-cursor"] == displayState["nsx26:standard-listing-position"] then
            displayState["nsx26:focus-object"] = object
            displayState["nsx26:lines-to-display"] << (" "*14)+NSXDisplayOperator::objectInferfaceString(object)
            displayState["nsx26:screen-left-height"] = displayState["nsx26:screen-left-height"] - 1 
        end

        if object["agent-uid"] == "201cac75-9ecc-4cac-8ca1-2643e962a6c6" then
            # We have a lightThread object
            displayState["nsx26:object-still-to-go"] = displayState["nsx26:object-still-to-go"]
                .map{|o| 
                    o["metric"] = o["metric"]-0.01 
                    o
                }
            loop {
                lightThread = object["item-data"]["lightThread"]
                lightThreadCatalystObjectsUUIDs = NSXCatalystMetadataInterface::lightThreadCatalystObjectsUUIDs(lightThread["uuid"])
                break if lightThreadCatalystObjectsUUIDs.size==0
                ienum = LucilleCore::integerEnumerator() 
                displayState["nsx26:all-catalyst-objects"]
                    .select{|o| lightThreadCatalystObjectsUUIDs.include?(o["uuid"]) }   
                    .sort{|o1,o2| o1["uuid"]<=>o2["uuid"] }
                    .map{|o|
                        o["metric"] = object["metric"] - 0.01*Math.exp(-ienum.next()) 
                        o[":is-lightThread-listing-7fdfb1be:"] = true # This is an unofficial marker for objects which have been positioned as followers of the first lightThread.
                        o
                    }
                    .each{|o|
                        displayState["nsx26:object-still-to-go"].unshift(o)
                    }
                break
            }

        end

        if displayState["nsx26:screen-left-height"] <= 0 then
            displayState["nsx26:should-stop-display-process"] = true
        end

        if displayState["nsx26:object-still-to-go"].count == 0 then
            displayState["nsx26:should-stop-display-process"] = true
        end

        displayState
    end

    # NSXDisplayOperator::printScreen(displayScreenSizeReductionIndex, standardlp)
    def self.printScreen(displayScreenSizeReductionIndex, standardlp)
        focusobject = nil
        displayState = NSXDisplayOperator::makeGenesysDisplayState(NSXMiscUtils::screenHeight()-displayScreenSizeReductionIndex, standardlp)
        loop {
            displayState["nsx26:lines-to-display"].each{|line|
                puts line
            }
            displayState = NSXDisplayOperator::displayStateTransition(NSXDisplayOperator::newDisplayState(displayState))
            break if displayState.nil?
            focusobject = displayState["nsx26:focus-object"]
            break if displayState["nsx26:should-stop-display-process"]
        }
        focusobject
    end

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

    # NSXDisplayOperator::objectInferfaceString(object)
    def self.objectInferfaceString(object)
        announce = object['announce'].strip
        defaultExpressionAsString = object["default-expression"] ? object["default-expression"] : ""
        requirements = NSXCatalystMetadataInterface::getObjectsRequirements(object['uuid'])
        requirementsAsString = requirements.size>0 ? " ( #{requirements.join(", ")} )" : ''
        part2 = 
            [
                "#{requirementsAsString.green}",
                " (#{object["commands"].join(" ").red})",
                " \"#{defaultExpressionAsString.green}\""
            ].join()
        part2        
    end

    # NSXDisplayOperator::objectToString(object)
    def self.objectToString(object)
        announce = object['announce'].strip
        defaultExpressionAsString = object["default-expression"] ? object["default-expression"] : ""
        maybeOrdinal = NSXCatalystMetadataInterface::getOrdinalOrNull(object['uuid'])
        part1 = 
            [
                "(#{"%.3f" % object["metric"]})",
                maybeOrdinal ? " {ordinal: #{maybeOrdinal}}" : "",
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
            "#{NSXDisplayOperator::positionDisplay(standardlp, position)} #{NSXMiscUtils::objectToString(object)}"
        else
            "#{NSXDisplayOperator::positionDisplay(standardlp, position)} #{NSXMiscUtils::objectToString(object)[0,NSXMiscUtils::screenWidth()-9]}"
        end
    end

    # NSXDisplayOperator::objectToColoredLineForMainListing(object, position, standardlp)
    def self.objectToColoredLineForMainListing(object, position, standardlp)
        str = NSXDisplayOperator::objectToLineForMainListing(object, position, standardlp)
        if object["metric"]>1 then
            str = str.yellow
        end
        if position == standardlp then
            str = str.colorize(:background => :light_blue)
        end
        if object["is-running"] then
            str = str.green
        end
        str
    end

    # NSXDisplayOperator::positionDisplay(standardlp, position)
    def self.positionDisplay(standardlp, position)
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

end