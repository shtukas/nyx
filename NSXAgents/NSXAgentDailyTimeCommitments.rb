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

NSXAgentDailyTimeCommitmentsPrimarySetDataPath = "/Galaxy/DataBank/Catalyst/Agents-Data/Daily-Time-Commitments/BTreeSets"
NSXAgentDailyTimeCommitmentsPrimarySetUUID = "679bd7b9-7eec-4455-b8d7-d089785d2595"

class NSXAgentDailyTimeCommitments

    # NSXAgentDailyTimeCommitments::agentuuid()
    def self.agentuuid()
        "8b881a6f-33b7-497a-9293-2aaeefa16c18"
    end

    # NSXAgentDailyTimeCommitments::getObjects()
    def self.getObjects()
        NSXAgentDailyTimeCommitments::getAllObjects()
    end

    # NSXAgentDailyTimeCommitments::getEntries()
    def self.getEntries()
        JSON.parse(IO.read("/Galaxy/DataBank/Catalyst/Agents-Data/Daily-Time-Commitments/entries.json"))
    end

    # NSXAgentDailyTimeCommitments::entryToCatalystObject(entry)
    def self.entryToCatalystObject(entry)
        uuid = entry["uuid"]
        todayTimeInSeconds = BTreeSets::values(nil, "entry-uuid-to-timing-set-uuids:qw213ew:#{uuid}")
            .select{|timingEntry| timingEntry["date"] == NSXMiscUtils::currentDay() }
            .map{|timingEntry| timingEntry["timespan"] }
            .inject(0, :+)
        percentageDone = 100 * todayTimeInSeconds.to_f/(entry["commitmentInHours"]*3600)
        isRunning = NSXRunner::isRunning?(uuid)
        {
            "uuid"      => uuid,
            "agentuid"  => NSXAgentDailyTimeCommitments::agentuuid(),
            "metric"    => isRunning ? 2 : 0.55,
            "announce"  => "Daily Time Commitment: #{entry["description"]} (commitment: #{entry["commitmentInHours"]} hours, done: #{percentageDone.round(3)} %)",
            "commands"  => isRunning ? ["stop"] : ["start"],
            "isRunning" => isRunning
        }
    end

    # NSXAgentDailyTimeCommitments::getAllObjects()
    def self.getAllObjects()
        NSXAgentDailyTimeCommitments::getEntries()
            .map{|entry| NSXAgentDailyTimeCommitments::entryToCatalystObject(entry) }
    end

    # NSXAgentDailyTimeCommitments::processObjectAndCommand(object, command)
    def self.processObjectAndCommand(object, command)
        uuid = object["uuid"]
        if command == "start" then
            return if NSXRunner::isRunning?(uuid)
            NSXRunner::start(uuid)
            return
        end
        if command == "stop" then
            return if !NSXRunner::isRunning?(uuid)
            timeInSeconds = NSXRunner::stop(uuid)
            timingEntry = {
                "date"     => NSXMiscUtils::currentDay(),
                "unixtime" => Time.new.to_i,
                "timespan" => timeInSeconds
            }
            BTreeSets::set(nil, "entry-uuid-to-timing-set-uuids:qw213ew:#{uuid}", SecureRandom.uuid, timingEntry)
            return
        end
    end
end

