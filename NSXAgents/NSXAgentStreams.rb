#!/usr/bin/ruby

# encoding: UTF-8
require "/Galaxy/Software/Misc-Common/Ruby-Libraries/LucilleCore.rb"
require 'securerandom'
# SecureRandom.hex    #=> "eb693ec8252cd630102fd0d0fb7c3485"
# SecureRandom.hex(4) #=> "eb693123"
# SecureRandom.uuid   #=> "2d931510-d99f-494a-8c67-87feb05e1594"
require "time"

# -------------------------------------------------------------------------------------

class NSXAgentStreams

    # NSXAgentStreams::agentuuid()
    def self.agentuuid()
        "d2de3f8e-6cf2-46f6-b122-58b60b2a96f1"
    end

    # NSXAgentStreams::getObjects()
    def self.getObjects()
        $STREAM_ITEMS_MANAGER.getItemsForDisplay()
    end

    # NSXAgentStreams::stopStreamItem(item): item
    def self.stopStreamItem(item)
        return item if item.nil?
        return item if !NSXRunner::isRunning?(item["uuid"])
        if item["run-data"].nil? then
            item["run-data"] = []
        end
        runningTimeInSeconds = NSXRunner::stop(item["uuid"])
        StreamTimeTracking::addTimeInSecondsToStream(item["streamuuid"], runningTimeInSeconds)
        item["run-data"] << [Time.new.to_i, runningTimeInSeconds]
        if item["run-data"].map{|x| x[1] }.inject(0, :+) >= 3600 then
            item["run-data"] = []
            item["ordinal"] = NSXStreamsUtils::newPositionNOrdinalForStreamItem(item["streamuuid"], 5, item["uuid"])
        end
        item
    end

    # NSXAgentStreams::doneStreamItemEmailCarrier(itemuuid)
    def self.doneStreamItemEmailCarrier(itemuuid)
        claim = NSXEmailTrackingClaims::getClaimByStreamItemUUIDOrNull(itemuuid)
        return if claim.nil?
        if claim["status"]=="init" then
            claim["status"] = "deleted-on-local"
            NSXEmailTrackingClaims::commitClaimToDisk(claim)
        end
        if claim["status"]=="detached" then
            claim["status"] = "deleted-on-local"
            NSXEmailTrackingClaims::commitClaimToDisk(claim)
        end
        if claim["status"]=="deleted-on-server" then
            claim["status"] = "dead"
            NSXEmailTrackingClaims::commitClaimToDisk(claim)
        end
        if claim["status"]=="deleted-on-local" then
        end
        if claim["status"]=="dead" then
        end
    end

    # NSXAgentStreams::doneStreamItem(object)
    def self.doneStreamItem(object)
        # If the object carries a stream item that is an email with a tracking claim, then we need to update the tracking claim
        if object["agentuid"] == "d2de3f8e-6cf2-46f6-b122-58b60b2a96f1" then
            if NSXEmailTrackingClaims::getClaimByStreamItemUUIDOrNull(object["uuid"]) then
                NSXAgentStreams::doneStreamItemEmailCarrier(object["uuid"])
                return
            end
        end
        $STREAM_ITEMS_MANAGER.destroyItem(object)
    end

    # NSXAgentStreams::processObjectAndCommand(object, command)
    def self.processObjectAndCommand(object, command)
        if command == "open" then
            genericContentItem = NSXGenericContents::viewGenericContentItemReturnUpdatedItemOrNull(object["generic-content-item"])
            if genericContentItem then
                object["generic-content-item"] = genericContentItem
                $STREAM_ITEMS_MANAGER.commitItem(object)
            end
        end
        if command == "start" then
            NSXRunner::start(object["uuid"])
            NSXMiscUtils::setStandardListingPosition(1)
            object["prioritization"] = "running"
            $STREAM_ITEMS_MANAGER.commitItem(object)
        end
        if command == "stop" then
            object = NSXAgentStreams::stopStreamItem(object)
            object["prioritization"] = "standard"
            NSXPlacement::relocateToBackOfTheQueue(object["uuid"])
            $STREAM_ITEMS_MANAGER.commitItem(object)
        end
        if command == "done" then
            NSXAgentStreams::doneStreamItemEmailCarrier(object["uuid"])
            $STREAM_ITEMS_MANAGER.destroyItem(object)
        end
        if command == "recast" then
            # If the object carries a stream item that is an email with a tracking claim, then we need to update the tracking claim
            if object["agentuid"] == "d2de3f8e-6cf2-46f6-b122-58b60b2a96f1" then
                claim = NSXEmailTrackingClaims::getClaimByStreamItemUUIDOrNull(object["uuid"])
                if claim then
                    if claim["status"]=="init" then
                        claim["status"] = "detached"
                        NSXEmailTrackingClaims::commitClaimToDisk(claim)
                    end
                    if claim["status"]=="detached" then
                    end
                    if claim["status"]=="deleted-on-server" then
                    end
                    if claim["status"]=="deleted-on-local" then
                    end
                    if claim["status"]=="dead" then
                    end
                end
            end
            object = NSXAgentStreams::stopStreamItem(object)
            object = NSXStreamsUtils::recastStreamItem(object)
            $STREAM_ITEMS_MANAGER.commitItem(object)
        end
        if command == "push" then
            object["ordinal"] = NSXStreamsUtils::newPositionNOrdinalForStreamItem(object["streamuuid"], 5, object["uuid"])
            $STREAM_ITEMS_MANAGER.commitItem(object)
        end
    end
end
