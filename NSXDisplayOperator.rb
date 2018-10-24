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

    # NSXDisplayOperator::makeGenesysDisplayState(screenLeftHeight, standardlp, shouldShowBelowSpaceLevel)
    def self.makeGenesysDisplayState(screenLeftHeight, standardlp, shouldShowBelowSpaceLevel) # : DisplayState
        objects = NSXDisplayOperator::flockObjectsProcessedForCatalystDisplay(shouldShowBelowSpaceLevel)
        {
            "nsx26:object-still-to-go"               => objects.sort{|o1,o2| o1['metric']<=>o2['metric'] }.reverse,
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

        displayState["nsx26:lines-to-display"] << NSXDisplayOperator::objectToColoredLineForMainListing(object, displayState["nsx26:current-position-cursor"], displayState["nsx26:standard-listing-position"])
        displayState["nsx26:screen-left-height"] = displayState["nsx26:screen-left-height"] - 1 

        if displayState["nsx26:current-position-cursor"] == displayState["nsx26:standard-listing-position"] then
            displayState["nsx26:focus-object"] = object
            if object[":light-thread-data:"] then
                displayState["nsx26:lines-to-display"] << (" "*15) + "(" + ( object[":light-thread-data:"]["secondary-object-run-status"] ? "/stop" : "/start" ).red + ")"
                displayState["nsx26:screen-left-height"] = displayState["nsx26:screen-left-height"] - 1 
            end
            displayState["nsx26:lines-to-display"] << (" "*15)+NSXDisplayOperator::objectInferfaceString(object)
            displayState["nsx26:screen-left-height"] = displayState["nsx26:screen-left-height"] - 1 
        end

        if displayState["nsx26:screen-left-height"] <= 0 then
            displayState["nsx26:should-stop-display-process"] = true
        end

        if displayState["nsx26:object-still-to-go"].count == 0 then
            displayState["nsx26:should-stop-display-process"] = true
        end

        displayState
    end

    # NSXDisplayOperator::printScreen(displayScreenSizeReductionIndex, standardlp, shouldShowBelowSpaceLevel)
    def self.printScreen(displayScreenSizeReductionIndex, standardlp, shouldShowBelowSpaceLevel)
        focusobject = nil
        displayState = NSXDisplayOperator::makeGenesysDisplayState(NSXMiscUtils::screenHeight()-displayScreenSizeReductionIndex, standardlp, shouldShowBelowSpaceLevel)
        loop {
            displayState["nsx26:lines-to-display"].each{|line|
                puts line
            }
            displayState = NSXDisplayOperator::displayStateTransition(displayState)
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

    # NSXDisplayOperator::lightThreadDataForSecondaryObjectOrNull(secondaryObjectUUID, ltmap)
    def self.lightThreadDataForSecondaryObjectOrNull(secondaryObjectUUID, ltmap)
        claim = NSXMiscUtils::getLT1526ClaimOrNull(secondaryObjectUUID)
        return nil if claim.nil?
        lightThreadUUID = claim["light-thread-uuid"]
        lightThread = NSXLightThreadUtils::getLightThreadByUUIDOrNull(lightThreadUUID)
        return nil if lightThread.nil?
        metric =
            if lightThread["status"][0]=="running-since" then
                0.99*ltmap[lightThread["uuid"]]-NSXMiscUtils::traceToMetricShift(secondaryObjectUUID)
            else
                1.01*ltmap[lightThread["uuid"]]-NSXMiscUtils::traceToMetricShift(secondaryObjectUUID)
            end
        {
            "light-thread" => lightThread,
            "description"  => lightThread["description"],
            "metric"       => metric,
            "secondary-object-run-status" => NSXMiscUtils::getLightThreadSecondaryObjectRunningStatusOrNull(secondaryObjectUUID)
        }
    end

    # NSXDisplayOperator::flockObjectsProcessedForCatalystDisplay(shouldShowBelowSpaceLevel)
    def self.flockObjectsProcessedForCatalystDisplay(shouldShowBelowSpaceLevel)
        
        ltmap = {} # Map[LightThreadUUID, Metric]

        NSXCatalystObjectsOperator::getObjects()
            .select{|object| object["agent-uid"]=="201cac75-9ecc-4cac-8ca1-2643e962a6c6" }
            .map{|object| NSXMiscUtils::fDoNotShowUntilDateTimeUpdateForDisplay(object) }
            .each{|object|
                ltmap[object["item-data"]["lightThread"]["uuid"]] = object["metric"]
            }

        lightThreadObjectUUIDs = []

        NSXCatalystObjectsOperator::getObjects()
            .select{|object| object["agent-uid"]=="201cac75-9ecc-4cac-8ca1-2643e962a6c6" }
            .each{|lightThread|
                lightThreadObjectUUIDs << lightThread["uuid"]
                NSXMiscUtils::getLT1526SecondaryObjectUUIDsForLightThread(lightThread["uuid"]).each{|objectuuid| lightThreadObjectUUIDs << objectuuid }
            }

        NSXCatalystObjectsOperator::getObjects()
            .map{|object|
                object.clone
            }
            .map{|object| 
                object[":metric-from-agent:"] = object["metric"]
                object
            }
            .map{|object|
                if ( lightThreadDataForSecondaryObject = NSXDisplayOperator::lightThreadDataForSecondaryObjectOrNull(object["uuid"],ltmap) ) then
                    originalAnnounce = object["announce"] # might be used in the notification

                    runningStatement = 
                        if lightThreadDataForSecondaryObject["secondary-object-run-status"] then
                            lightThreadDataForSecondaryObject["metric"] = 2
                            runningForInSeconds = Time.new.to_i - lightThreadDataForSecondaryObject["secondary-object-run-status"]["start-unixtime"]
                            " [" + "running for #{ (runningForInSeconds.to_f/3600).round(2) } hours".yellow + "]"
                        else
                            ""
                        end
                    if lightThreadDataForSecondaryObject["secondary-object-run-status"] then
                        object["is-running"] = true
                    end
                    object[":light-thread-data:"] = lightThreadDataForSecondaryObject
                    object["announce"] = "#{lightThreadDataForSecondaryObject["description"].green}#{runningStatement}: #{object["announce"]}"
                    object["metric"] = lightThreadDataForSecondaryObject["metric"]

                    # Notification
                    percentage = NSXMiscUtils::lightThreadSecondaryObjectUUIDToLightThreadLivePercentageOrNull(object["uuid"])
                    if percentage and (percentage>100) then
                        NSXMiscUtils::issueScreenNotification("Catalyst Display Operator", "#{originalAnnounce} is done")
                    end
                end
                object
            }
            .map{|object| NSXMiscUtils::fDoNotShowUntilDateTimeUpdateForDisplay(object) }
            .map{|object| NSXMetricWeight::updateObjectWithNewMetric(object) }
    end

end