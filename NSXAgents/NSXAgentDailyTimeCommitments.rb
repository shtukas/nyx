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

# -------------------------------------------------------------------------------------

=begin

DailyTimeCommitment {
    uuid: String
    description: String
    commitmentInHours : Float
}

TimingEntry {
    date
    unixtime
    timespan
}

=end

NSXAgentDailyTimeCommitmentsPrimarySetDataPath = "#{CATALYST_COMMON_DATABANK_CATALYST_INSTANCE_FOLDERPATH}/Agents-Data/Daily-Time-Commitments/BTreeSets"
NSXAgentDailyTimeCommitmentsPrimarySetUUID = "679bd7b9-7eec-4455-b8d7-d089785d2595"

class NSXAgentDailyTimeCommitments

    # NSXAgentDailyTimeCommitments::agentuid()
    def self.agentuid()
        "8b881a6f-33b7-497a-9293-2aaeefa16c18"
    end

    # NSXAgentDailyTimeCommitments::getObjects()
    def self.getObjects()
        NSXAgentDailyTimeCommitments::getAllObjects()
    end

    # NSXAgentDailyTimeCommitments::getEntries()
    def self.getEntries()
        JSON.parse(IO.read("#{CATALYST_COMMON_DATABANK_CATALYST_INSTANCE_FOLDERPATH}/Agents-Data/Daily-Time-Commitments/entries.json"))
    end

    # NSXAgentDailyTimeCommitments::baseMetric()
    def self.baseMetric() # for the moment only the base metric
        return 0.85 if Time.new.hour < 9
        0.55
    end

    # NSXAgentDailyTimeCommitments::metric(entry)
    def self.metric(entry)
        uuid = entry["uuid"]
        isRunning = NSXRunner::isRunning?(uuid)
        if isRunning then
            2
        else
            NSXAlgebraicTimePoints::metric(uuid, NSXAgentDailyTimeCommitments::baseMetric())
        end
    end

    # NSXAgentDailyTimeCommitments::entryToCatalystObject(entry)
    def self.entryToCatalystObject(entry)
        uuid = entry["uuid"]
        collectionValue = NSXAlgebraicTimePoints::getCollectionCumulatedValue(uuid)
        isRunning = NSXRunner::isRunning?(uuid)
        {
            "uuid"      => uuid,
            "agentuid"  => NSXAgentDailyTimeCommitments::agentuid(),
            "metric"    => NSXAgentDailyTimeCommitments::metric(entry),
            "announce"  => "Daily Time Commitment: #{entry["description"]} (commitment: #{entry["commitmentInHours"]} hours, done: #{collectionValue.round(3)} seconds)",
            "commands"  => isRunning ? ["stop"] : ["start"],
            "isRunning" => isRunning
        }
    end

    # NSXAgentDailyTimeCommitments::getAllObjects()
    def self.getAllObjects()
        NSXAgentDailyTimeCommitments::getEntries()
            .map{|entry| NSXAgentDailyTimeCommitments::entryToCatalystObject(entry) }
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
            point = {
                "collection" => Time.new.to_i,
                "weigthInSeconds" => timeInSeconds
            }
            NSXAlgebraicTimePoints::issuePoint(objectuuid, timeInSeconds)
            NSXMultiInstancesWrite::issueEventDailyTimeCommitmentTimePoint(objectuuid, point)
            return
        end
    end
end

Thread.new {
    loop {
        sleep 120
        status = NSXAgentDailyTimeCommitments::getEntries()
            .select{|entry| NSXRunner::isRunning?(entry["uuid"]) }
            .map{|entry| NSXAlgebraicTimePoints::getCollectionCumulatedValue(entry["uuid"]) }
            .any?{|value| value > 0 }
        if status then
            NSXMiscUtils::onScreenNotification("Daily time commitment", "Running item is overflowing")
        end
    }
}

