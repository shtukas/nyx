#!/usr/bin/ruby

# encoding: UTF-8
require "/Users/pascal/Galaxy/Software/Misc-Common/Ruby-Libraries/LucilleCore.rb"

require 'securerandom'
# SecureRandom.hex    #=> "eb693ec8252cd630102fd0d0fb7c3485"
# SecureRandom.hex(4) #=> "eb693123"
# SecureRandom.uuid   #=> "2d931510-d99f-494a-8c67-87feb05e1594"
require "time"

require "/Users/pascal/Galaxy/Software/Misc-Common/Ruby-Libraries/BTreeSets.rb"
=begin
    BTreeSets::values(repositorylocation or nil, setuuid: String): Array[Value]
    BTreeSets::set(repositorylocation or nil, setuuid: String, valueuuid: String, value)
    BTreeSets::getOrNull(repositorylocation or nil, setuuid: String, valueuuid: String): nil | Value
    BTreeSets::destroy(repositorylocation, setuuid: String, valueuuid: String)
=end

require "/Users/pascal/Galaxy/Software/Misc-Common/Ruby-Libraries/KeyValueStore.rb"
=begin
    KeyValueStore::setFlagTrue(repositorylocation or nil, key)
    KeyValueStore::setFlagFalse(repositorylocation or nil, key)
    KeyValueStore::flagIsTrue(repositorylocation or nil, key)

    KeyValueStore::set(repositorylocation or nil, key, value)
    KeyValueStore::getOrNull(repositorylocation or nil, key)
    KeyValueStore::getOrDefaultValue(repositorylocation or nil, key, defaultValue)
    KeyValueStore::destroy(repositorylocation or nil, key)
=end

# -------------------------------------------------------------------------------------

=begin

DailyTimeCommitment {
    uuid: String
    description: String
    commitmentInHours : Float
}

=end

class NSXAgentDailyTimeCommitmentsHelpers

    # NSXAgentDailyTimeCommitmentsHelpers::getEntries()
    def self.getEntries()
        JSON.parse(IO.read("#{CATALYST_COMMON_DATABANK_CATALYST_INSTANCE_FOLDERPATH}/Agents-Data/Daily-Time-Commitments/entries.json"))
    end

    # NSXAgentDailyTimeCommitments::getEntryByUUIDOrNull(uuid)
    def self.getEntryByUUIDOrNull(uuid)
        NSXAgentDailyTimeCommitmentsHelpers::getEntries()
            .select{|entry| entry["uuid"] == uuid }
            .first
    end

    # NSXAgentDailyTimeCommitmentsHelpers::baseMetric()
    def self.baseMetric() # for the moment only the base metric
        return 0.85 if Time.new.hour < 9
        0.55
    end

    # NSXAgentDailyTimeCommitmentsHelpers::entryToCatalystObject(entry)
    def self.entryToCatalystObject(entry)
        uuid = entry["uuid"]
        runPoints = NSXRunTimes::getPoints(uuid)
        collectionValue = ( NSXRunner::runningTimeOrNull(uuid) || 0 ) + runPoints.map{|point| point["algebraicTimespanInSeconds"] }.inject(0, :+)
        announce = "Daily Time Commitment: #{entry["description"]} (commitment: #{entry["commitmentInHours"]} hours; done: #{collectionValue.to_i} seconds, #{(collectionValue.to_f/3600).round(2)} hours)"
        contentItem = {
            "type" => "line",
            "line" => announce
        }
        metric = NSXRunMetrics::metric1(runPoints, entry["commitmentInHours"]*3600, 86400, 0.8, 0.3)
        {
            "uuid"                => uuid,
            "agentuid"            => NSXAgentDailyTimeCommitments::agentuid(),
            "contentItem"         => contentItem,
            "metric"              => metric,
            "commands"            => ["start", "stop", "numbers"],
            "defaultCommand"      => NSXRunner::isRunning?(uuid) ? "stop" : "start",
            "isRunning"           => NSXRunner::isRunning?(uuid)
        }
    end

    # NSXAgentDailyTimeCommitmentsHelpers::performNegativeValueForEntry(entry)
    def self.performNegativeValueForEntry(entry)
        # We only do those calculations on alexandra
        return if !NSXMiscUtils::isLucille18()
        if !KeyValueStore::flagIsTrue(nil, "04ffa335-4bad-415a-a469-2101f0842c01:#{NSXMiscUtils::currentDay()}") then
            runPoints = NSXRunTimes::getPoints(entry["uuid"])
            existingWeight = runPoints.map{|point| point["algebraicTimespanInSeconds"] }.inject(0, :+)
            if existingWeight < 0 then
                KeyValueStore::setFlagTrue(nil, "04ffa335-4bad-415a-a469-2101f0842c01:#{NSXMiscUtils::currentDay()}")
                return
            end
            negativeValue = -entry["commitmentInHours"]*3600
            NSXRunTimes::addPoint(entry["uuid"], Time.new.to_i, negativeValue)
            NSXMultiInstancesWrite::sendEventToDisk({
                "instanceName" => NSXMiscUtils::instanceName(),
                "eventType"    => "MultiInstanceEventType:RunTimesPoint",
                "payload"      => {
                    "uuid"          => SecureRandom.hex,
                    "collectionuid" => entry["uuid"],
                    "unixtime"      => Time.new.to_i,
                    "algebraicTimespanInSeconds" => negativeValue
                }
            })
            KeyValueStore::setFlagTrue(nil, "04ffa335-4bad-415a-a469-2101f0842c01:#{NSXMiscUtils::currentDay()}")
        end
    end

    # NSXAgentDailyTimeCommitmentsHelpers::performNegativeValuesForEntries()
    def self.performNegativeValuesForEntries()
        NSXAgentDailyTimeCommitmentsHelpers::getEntries()
        .each{|entry|
            NSXAgentDailyTimeCommitmentsHelpers::performNegativeValueForEntry(entry)
        }
    end

end

class NSXAgentDailyTimeCommitments

    # NSXAgentDailyTimeCommitments::agentuid()
    def self.agentuid()
        "8b881a6f-33b7-497a-9293-2aaeefa16c18"
    end

    # NSXAgentDailyTimeCommitments::getObjects()
    def self.getObjects()
        if NSXMiscUtils::isLucille18() then
            NSXAgentDailyTimeCommitmentsHelpers::performNegativeValuesForEntries()
        end
        NSXAgentDailyTimeCommitments::getAllObjects()
    end

    # NSXAgentDailyTimeCommitments::getAllObjects()
    def self.getAllObjects()
        NSXAgentDailyTimeCommitmentsHelpers::getEntries()
            .map{|entry| NSXAgentDailyTimeCommitmentsHelpers::entryToCatalystObject(entry) }
    end

    # NSXAgentDailyTimeCommitments::getObjectByUUIDOrNull(objectuuid)
    def self.getObjectByUUIDOrNull(objectuuid)
        NSXAgentDailyTimeCommitments::getAllObjects()
            .select{|object| object["uuid"] == objectuuid }
            .first
    end

    # NSXAgentDailyTimeCommitments::processObjectAndCommand(objectuuid, command, isLocalCommand)
    def self.processObjectAndCommand(objectuuid, command, isLocalCommand)
        if command == "start" then
            return if NSXRunner::isRunning?(objectuuid)
            NSXRunner::start(objectuuid)
            return
        end
        if command == "stop" then
            return if !NSXRunner::isRunning?(objectuuid)
            timespanInSeconds = NSXRunner::stop(objectuuid)
            NSXRunTimes::addPoint(objectuuid, Time.new.to_i, timespanInSeconds)
            if isLocalCommand then
                NSXMultiInstancesWrite::sendEventToDisk({
                    "instanceName" => NSXMiscUtils::instanceName(),
                    "eventType"    => "MultiInstanceEventType:RunTimesPoint",
                    "payload"      => {
                        "uuid"          => SecureRandom.hex,
                        "collectionuid" => objectuuid,
                        "unixtime"      => Time.new.to_i,
                        "algebraicTimespanInSeconds" => timespanInSeconds
                    }
                })
            end
            metadata = NSXMetaDataStore::get(object["uuid"])
            (metadata["runtimes-targets-1738"] || [])
                .each{|timetargetuid|
                    NSXRunTimes::addPoint(timetargetuid, Time.new.to_i, timespanInSeconds)
                    if isLocalCommand then
                        NSXMultiInstancesWrite::sendEventToDisk({
                            "instanceName" => NSXMiscUtils::instanceName(),
                            "eventType"    => "MultiInstanceEventType:RunTimesPoint",
                            "payload"      => {
                                "uuid"          => SecureRandom.hex,
                                "collectionuid" => timetargetuid,
                                "unixtime"      => Time.new.to_i,
                                "algebraicTimespanInSeconds" => timespanInSeconds
                            }
                        })
                    end
                }
            return
        end
        if command == "numbers" then
            entry = NSXAgentDailyTimeCommitmentsHelpers::getEntryByUUIDOrNull(objectuuid)
            puts "live value: #{(NSXRunner::runningTimeOrNull(entry["uuid"]) || 0) + NSXRunTimes::getPoints(entry["uuid"]).map{|point| point["algebraicTimespanInSeconds"] }.inject(0, :+)}"

            runPoints = NSXRunTimes::getPoints(objectuuid)
            puts "metric: #{NSXRunMetrics::metric1(runPoints, entry["commitmentInHours"]*3600, 86400, 0.8, 0.3)}"
            LucilleCore::pressEnterToContinue()
            return
        end
    end
end

begin
    NSXBob::registerAgent(
        {
            "agent-name"  => "NSXAgentDailyTimeCommitments",
            "agentuid"    => NSXAgentDailyTimeCommitments::agentuid(),
        }
    )
rescue
end

Thread.new {
    loop {
        sleep 120
        status = NSXAgentDailyTimeCommitmentsHelpers::getEntries()
            .select{|entry| NSXRunner::isRunning?(entry["uuid"]) }
            .map{|entry| (NSXRunner::runningTimeOrNull(entry["uuid"]) || 0) + NSXRunTimes::getPoints(entry["uuid"]).map{|point| point["algebraicTimespanInSeconds"] }.inject(0, :+) }
            .any?{|value| value > 0 }
        if status then
            NSXMiscUtils::onScreenNotification("Daily time commitment", "Running item is overflowing")
        end
    }
}

