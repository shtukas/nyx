#!/usr/bin/ruby

# encoding: UTF-8
require "/Users/pascal/Galaxy/Software/Misc-Common/Ruby-Libraries/LucilleCore.rb"
require 'securerandom'
# SecureRandom.hex    #=> "eb693ec8252cd630102fd0d0fb7c3485"
# SecureRandom.hex(4) #=> "eb693123"
# SecureRandom.uuid   #=> "2d931510-d99f-494a-8c67-87feb05e1594"
require "time"

# -------------------------------------------------------------------------------------

GUARDIAN_WORK_RUNNER_UID = "15af10e1-7063-41c0-9bd6-a7cc9b963ee6:#{NSXMiscUtils::currentDay()}"
GUARDIAN_WORK_RUN_TIMES_UID = "af26380b-c69b-4484-ba5e-13ecc580b2a9:#{NSXMiscUtils::currentDay()}"
GUARDIAN_WORK_OBJECT_UUID = "6dfe4e38-415a-43d7-af27-b1ae6d069030"

class NSXAgentDailyGuardianWork

    # NSXAgentDailyGuardianWork::shouldShowObject()
    def self.shouldShowObject()
        return false if [0,6].include?(Time.new.wday)
        return false if Time.new.hour < 8
        return false if KeyValueStore::flagIsTrue(nil, "33319c02-f1cd-4296-a772-43bb5b6ba07f:#{NSXMiscUtils::currentDay()}")
        true
    end

    # NSXAgentDailyGuardianWork::timeAlreadyDoneTodayInSeconds(shouldDisplayLiveMeasurement)
    def self.timeAlreadyDoneTodayInSeconds(shouldDisplayLiveMeasurement)
        x1 = shouldDisplayLiveMeasurement ? (NSXRunner::runningTimeOrNull(GUARDIAN_WORK_RUNNER_UID) || 0) : 0
        x2 = NSXRunTimes::getPoints(GUARDIAN_WORK_RUN_TIMES_UID).map{|point| point["algebraicTimespanInSeconds"] }.inject(0, :+)
        x1+x2
    end

    # NSXAgentDailyGuardianWork::start()
    def self.start()
        return if NSXRunner::isRunning?(GUARDIAN_WORK_RUNNER_UID)
        NSXRunner::start(GUARDIAN_WORK_RUNNER_UID)
    end

    # NSXAgentDailyGuardianWork::stop()
    def self.stop()
        return if !NSXRunner::isRunning?(GUARDIAN_WORK_RUNNER_UID)
        timeInSeconds = NSXRunner::stop(GUARDIAN_WORK_RUNNER_UID)
        NSXAgentDailyGuardianWork::addTimeInSeconds(timeInSeconds)
    end

    # NSXAgentDailyGuardianWork::addTimeInSeconds(timeInSeconds)
    def self.addTimeInSeconds(timeInSeconds)
        NSXRunTimes::addPoint(GUARDIAN_WORK_RUN_TIMES_UID, Time.new.to_i, timeInSeconds)
        NSXEventsLog::issueEvent(NSXMiscUtils::instanceName(), "NSXRunTimes/addPoint",
            {
                "collectionuid" => GUARDIAN_WORK_RUN_TIMES_UID,
                "unixtime" => Time.new.to_i,
                "algebraicTimespanInSeconds" => timeInSeconds
            }
        )
    end

    # NSXAgentDailyGuardianWork::proportionDoneToday(shouldDisplayLiveMeasurement)
    def self.proportionDoneToday(shouldDisplayLiveMeasurement)
        NSXAgentDailyGuardianWork::timeAlreadyDoneTodayInSeconds(shouldDisplayLiveMeasurement).to_f/(3600*6)
    end

    # NSXAgentDailyGuardianWork::metric()
    def self.metric()
        0.80 - NSXAgentDailyGuardianWork::proportionDoneToday(false)*0.5
    end

    # NSXAgentDailyGuardianWork::agentuid()
    def self.agentuid()
        "a6d554fd-44bf-4937-8dc6-5c9f1dcdaeba"
    end

    # NSXAgentDailyGuardianWork::getObjects()
    def self.getObjects()
        NSXAgentDailyGuardianWork::getAllObjects()
    end

    # NSXAgentDailyGuardianWork::getAllObjects()
    def self.getAllObjects()
        return [] if !NSXAgentDailyGuardianWork::shouldShowObject()
        announce = "Daily Guardian Work (#{(NSXAgentDailyGuardianWork::proportionDoneToday(true)*100).round(5)}%)"
        contentItem = {
            "type" => "line",
            "line" => announce
        }
        object = {}
        object["uuid"]           = GUARDIAN_WORK_OBJECT_UUID
        object["agentuid"]       = "a6d554fd-44bf-4937-8dc6-5c9f1dcdaeba"
        object["contentItem"]    = contentItem
        object["metric"]         = NSXAgentDailyGuardianWork::metric()
        object["commands"]       = ["start", "stop", "time:"]
        object["defaultCommand"] = NSXRunner::isRunning?(GUARDIAN_WORK_RUNNER_UID) ? "stop" : "start"
        object["isRunning"]      = NSXRunner::isRunning?(GUARDIAN_WORK_RUNNER_UID)
        [object]
    end

    # NSXAgentDailyGuardianWork::processObjectAndCommand(objectuuid, command)
    def self.processObjectAndCommand(objectuuid, command)
        if command == "start" then
            NSXAgentDailyGuardianWork::start()
            return
        end
        if command == "stop" then
            NSXAgentDailyGuardianWork::stop()
            return
        end
        if command == "time:" then
            timeInHours = LucilleCore::askQuestionAnswerAsString("Timespan in hour: ").to_f
            NSXAgentDailyGuardianWork::addTimeInSeconds(timeInHours*3600)
            return
        end
    end
end

begin
    NSXBob::registerAgent(
        {
            "agent-name"  => "NSXAgentDailyGuardianWork",
            "agentuid"    => NSXAgentDailyGuardianWork::agentuid(),
        }
    )
rescue
end

