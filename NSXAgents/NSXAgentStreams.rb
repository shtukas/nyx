#!/usr/bin/ruby

# encoding: UTF-8
require "/Galaxy/Software/Misc-Common/Ruby-Libraries/LucilleCore.rb"
require 'securerandom'
# SecureRandom.hex    #=> "eb693ec8252cd630102fd0d0fb7c3485"
# SecureRandom.hex(4) #=> "eb693123"
# SecureRandom.uuid   #=> "2d931510-d99f-494a-8c67-87feb05e1594"
require "time"

require "/Galaxy/Software/Misc-Common/Ruby-Libraries/Torr.rb"
=begin
    Torr::event(repositorylocation, collectionuuid, mass)
    Torr::weight(repositorylocation, collectionuuid, stabililityPeriodInSeconds, simulationWeight = 0)
    Torr::metric(repositorylocation, collectionuuid, stabililityPeriodInSeconds, targetWeight, metricAtZero, metricAtTarget)
=end

# -------------------------------------------------------------------------------------

class NSXAgentStreams

    # NSXAgentStreams::agentuuid()
    def self.agentuuid()
        "d2de3f8e-6cf2-46f6-b122-58b60b2a96f1"
    end

    # NSXAgentStreams::getObjects()
    def self.getObjects()
        if $NSXStreamSmallCarrier then
            return $NSXStreamSmallCarrier.getWatchedCatalystObjects()
        end
        NSXStreamsUtils::getCatalystObjectsForDisplay()
    end

    def self.getAllObjects()
        NSXStreamsUtils::getAllCatalystObjects()
    end

    # NSXAgentStreams::stopStreamItem(item): item
    def self.stopStreamItem(item)
        return item if item.nil?
        return item if !NSXRunner::isRunning?(item["uuid"])
        if item["run-data"].nil? then
            item["run-data"] = []
        end
        runningTimeInSeconds = NSXRunner::stop(item["uuid"])
        NSXStreamsTimeTracking::addTimeInSecondsToStream(item["streamuuid"], runningTimeInSeconds)
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

    # NSXAgentStreams::processObjectAndCommand(item, command)
    def self.processObjectAndCommand(item, command)
        if command == "open" then
            genericContentItem = NSXGenericContents::viewGenericContentItemReturnUpdatedItemOrNull(item["generic-content-item"])
            if genericContentItem then
                item["generic-content-item"] = genericContentItem
                NSXStreamsUtils::commitItemToDisk(item)
            end
            return
        end
        if command == "folder" then
            folderpath = NSXGenericContents::resolveFoldernameToFolderpathOrNull(item["generic-content-item"]["parent-foldername"])
            return if folderpath.nil?
            system("open '#{folderpath}'")
            return
        end
        if command == "start" then
            NSXRunner::start(item["uuid"])
            NSXMiscUtils::setStandardListingPosition(1)
            NSXStreamsUtils::commitItemToDisk(item)
            return
        end
        if command == "stop" then
            item = NSXAgentStreams::stopStreamItem(item)
            NSXStreamsUtils::commitItemToDisk(item)
            return
        end
        if command == "done" then
            # We need to record a small activity
            Torr::event(nil, "dd1a4ed5-a8eb-4bd9-8124-294ad6536b46:#{item["streamuuid"]}", 0.1) # We mark all of them but we are only interested in `Catalyst Inbox`
            NSXAgentStreams::doneStreamItemEmailCarrier(item["uuid"])
            NSXStreamsUtils::destroyItem(item)
            $NSXStreamSmallCarrier.removeObject(item["uuid"])
            return
        end
        if command == "recast" then
            # If the item carries a stream item that is an email with a tracking claim, then we need to update the tracking claim
            if item["agentuid"] == "d2de3f8e-6cf2-46f6-b122-58b60b2a96f1" then
                claim = NSXEmailTrackingClaims::getClaimByStreamItemUUIDOrNull(item["uuid"])
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
            item = NSXAgentStreams::stopStreamItem(item)
            item = NSXStreamsUtils::recastStreamItem(item)
            NSXStreamsUtils::commitItemToDisk(item)
            $NSXStreamSmallCarrier.removeObject(item["uuid"])
            return
        end
        if command == "push" then
            options = [
                "put to position 5 on stream",
                "put to end of stream"
            ]
            option = LucilleCore::selectEntityFromListOfEntitiesOrNull("option", options)
            if option == "put to position 5 on stream" then
                item["ordinal"] = NSXStreamsUtils::newPositionNOrdinalForStreamItem(item["streamuuid"], 5, item["uuid"])
                NSXStreamsUtils::commitItemToDisk(item)
            end
            if option == "put to end of stream" then
                item["ordinal"] = NSXMiscUtils::makeEndOfQueueStreamItemOrdinal()
                NSXStreamsUtils::commitItemToDisk(item)
            end
            $NSXStreamSmallCarrier.removeObject(item["uuid"])
            return
        end
    end
end
