#!/usr/bin/ruby

# encoding: UTF-8
require "/Galaxy/Software/Misc-Common/Ruby-Libraries/LucilleCore.rb"

require 'securerandom'
# SecureRandom.hex    #=> "eb693ec8252cd630102fd0d0fb7c3485"
# SecureRandom.hex(4) #=> "eb693123"
# SecureRandom.uuid   #=> "2d931510-d99f-494a-8c67-87feb05e1594"
require "time"

require "/Galaxy/Software/Misc-Common/Ruby-Libraries/BTreeSets.rb"
=begin
    BTreeSets::values(repositorylocation or nil, setuuid: String): Array[Value]
    BTreeSets::set(repositorylocation or nil, setuuid: String, valueuuid: String, value)
    BTreeSets::getOrNull(repositorylocation or nil, setuuid: String, valueuuid: String): nil | Value
    BTreeSets::destroy(repositorylocation, setuuid: String, valueuuid: String)
=end

require "/Galaxy/Software/Misc-Common/Ruby-Libraries/KeyValueStore.rb"
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
        JSON.parse(IO.read("#{CATALYST_COMMON_DATABANK_CATALYST_SHARED_FOLDERPATH}/Agents-Data/Daily-Time-Commitments/entries.json"))
    end

    # NSXAgentDailyTimeCommitmentsHelpers::baseMetric()
    def self.baseMetric() # for the moment only the base metric
        return 0.85 if Time.new.hour < 9
        0.55
    end

    # NSXAgentDailyTimeCommitmentsHelpers::metric(entry)
    def self.metric(entry)
        uuid = entry["uuid"]
        isRunning = NSXRunner::isRunning?(uuid)
        if isRunning then
            2
        else
            NSXAlgebraicTimePoints::metric(uuid, NSXAgentDailyTimeCommitmentsHelpers::baseMetric())
        end
    end

    # NSXAgentDailyTimeCommitmentsHelpers::entryToCatalystObject(entry)
    def self.entryToCatalystObject(entry)
        uuid = entry["uuid"]
        collectionValue = NSXAlgebraicTimePoints::getCollectionCumulatedValue(uuid)
        isRunning = NSXRunner::isRunning?(uuid)
        {
            "uuid"      => uuid,
            "agentuid"  => NSXAgentDailyTimeCommitments::agentuid(),
            "metric"    => NSXAgentDailyTimeCommitmentsHelpers::metric(entry),
            "announce"  => "Daily Time Commitment: #{entry["description"]} (commitment: #{entry["commitmentInHours"]} hours; done: #{collectionValue.to_i} seconds, #{(collectionValue.to_f/3600).round(3)} hours)",
            "commands"  => isRunning ? ["stop"] : ["start"],
            "isRunning" => isRunning,
            ":base-metric:" => NSXAgentDailyTimeCommitmentsHelpers::baseMetric(),
            ":last-negative-mark-unixtime:" => NSXAgentDailyTimeCommitmentsHelpers::getLastNegativeMarkUnixtimeForEntry(entry),
            ":last-negative-mark-datetime:" => Time.at(NSXAgentDailyTimeCommitmentsHelpers::getLastNegativeMarkUnixtimeForEntry(entry)).to_s
        }
    end

    # NSXAgentDailyTimeCommitmentsHelpers::getLastNegativeMarkUnixtimeForEntry(entry)
    def self.getLastNegativeMarkUnixtimeForEntry(entry)
        KeyValueStore::getOrDefaultValue(nil, "fd8d4e07-0fc7-4c95-a0c9-0f7f2d5784e0:#{entry["uuid"]}", Time.new.to_i.to_s).to_i
    end

    # NSXAgentDailyTimeCommitmentsHelpers::setLastNegativeMarkUnixtimeForEntry(entry)
    def self.setLastNegativeMarkUnixtimeForEntry(entry)
        KeyValueStore::set(nil, "fd8d4e07-0fc7-4c95-a0c9-0f7f2d5784e0:#{entry["uuid"]}", Time.new.to_i)
    end

    # NSXAgentDailyTimeCommitmentsHelpers::performNegativeValueForEntryIfTimeReady(entry)
    def self.performNegativeValueForEntryIfTimeReady(entry)
        if NSXMiscUtils::trueNoMoreOftenThanNEverySeconds(nil, "591e1ce5-92ca-49a0-ac80-c3387f30d874:#{entry["uuid"]}", 3600) then
            unixtime = NSXAgentDailyTimeCommitmentsHelpers::getLastNegativeMarkUnixtimeForEntry(entry)
            timespanInSeconds = Time.new.to_i - unixtime
            commitmentInSecondsPerDay = entry["commitmentInHours"]*3600
            fractionOfADaySinceLastUpdate = timespanInSeconds.to_f/86400
            negativeValue = -commitmentInSecondsPerDay*fractionOfADaySinceLastUpdate
            NSXAlgebraicTimePoints::issuePoint(entry["uuid"], negativeValue)
            NSXMultiInstancesWrite::issueEventDailyTimeCommitmentTimePoint(entry["uuid"], {
                "collection" => entry["uuid"],
                "weigthInSeconds" => negativeValue
            })
            NSXAgentDailyTimeCommitmentsHelpers::setLastNegativeMarkUnixtimeForEntry(entry)
        end
    end

    # NSXAgentDailyTimeCommitmentsHelpers::performNegativeValuesIfTimeReady()
    def self.performNegativeValuesIfTimeReady()
        NSXAgentDailyTimeCommitmentsHelpers::getEntries()
        .each{|entry|
            NSXAgentDailyTimeCommitmentsHelpers::performNegativeValueForEntryIfTimeReady(entry)
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
            NSXAgentDailyTimeCommitmentsHelpers::performNegativeValuesIfTimeReady()
        end
        NSXAgentDailyTimeCommitments::getAllObjects()
    end

    # NSXAgentDailyTimeCommitments::getAllObjects()
    def self.getAllObjects()
        NSXAgentDailyTimeCommitmentsHelpers::getEntries()
            .map{|entry| NSXAgentDailyTimeCommitmentsHelpers::entryToCatalystObject(entry) }
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
            timeInSeconds = NSXRunner::stop(objectuuid)
            NSXAlgebraicTimePoints::issuePoint(objectuuid, timeInSeconds)
            NSXMultiInstancesWrite::issueEventDailyTimeCommitmentTimePoint(objectuuid, {
                "collection" => objectuuid,
                "weigthInSeconds" => timeInSeconds
            })
            return
        end
    end
end

Thread.new {
    loop {
        sleep 120
        status = NSXAgentDailyTimeCommitmentsHelpers::getEntries()
            .select{|entry| NSXRunner::isRunning?(entry["uuid"]) }
            .map{|entry| NSXAlgebraicTimePoints::getCollectionCumulatedValue(entry["uuid"]) }
            .any?{|value| value > 0 }
        if status then
            NSXMiscUtils::onScreenNotification("Daily time commitment", "Running item is overflowing")
        end
    }
}

