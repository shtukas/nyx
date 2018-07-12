#!/usr/bin/ruby

# encoding: UTF-8
require 'digest/sha1'
# Digest::SHA1.hexdigest 'foo'
# Digest::SHA1.file(myFile).hexdigest
require "/Galaxy/local-resources/Ruby-Libraries/LucilleCore.rb"
require_relative "Bob.rb"
# -------------------------------------------------------------------------------------

Bob::registerAgent(
    {
        "agent-name"      => "SubProjects",
        "agent-uid"       => "10f0ad1e-ff0e-4a8a-8c90-fe09de2342ab",
        "general-upgrade" => lambda { AgentSubProjects::generalFlockUpgrade() },
        "object-command-processor" => lambda{ |object, command| AgentSubProjects::processObjectAndCommand(object, command) },
        "interface"       => lambda{ AgentSubProjects::interface() }
    }
)

# AgentSubProjects::metric

class AgentSubProjects

    def self.agentuuid()
        "10f0ad1e-ff0e-4a8a-8c90-fe09de2342ab"
    end

    def self.interface()
    end

    def self.generalFlockUpgrade()
        TheFlock::removeObjectsFromAgent(self.agentuuid())
        ProjectsCore::updateLocalTimeStructures()
        ProjectsCore::localTimeStructuresDataFiles().each{|data|
            projectuuid = data["projectuuid"]
            referenceTimeStructure = data["reference-time-structure"]
            data["local-commitments"]
                .map{|item|
                    timestructure = {}
                    timestructure["time-unit-in-days"] = referenceTimeStructure["time-unit-in-days"]
                    timestructure["time-commitment-in-hours"] = referenceTimeStructure["time-commitment-in-hours"] * item["timeshare"]
                    timedoneInHours, timetodoInHours, ratio = TimeStructuresOperator::doneMetricsForTimeStructure(item["uuid"], timestructure)
                    object              = {}
                    object["uuid"]      = item["uuid"]
                    object["agent-uid"] = self.agentuuid()
                    object["metric"]    = MetricsOfTimeStructures::metric2(item["uuid"], 0.1, 0.5, 0.6, timestructure) + CommonsUtils::traceToMetricShift(item["uuid"])
                    object["announce"]  = "sub-project: #{item["description"]} ( #{ProjectsCore::projectUUID2NameOrNull(projectuuid)} ) ( #{100*ratio.round(2)} % of #{timetodoInHours.round(2)} hours [today] )"
                    object["commands"]  = Chronos::isRunning(item["uuid"]) ? ["stop"] : ["start"]
                    object["default-expression"] = Chronos::isRunning(item["uuid"]) ? "stop" : "start"
                    object["is-running"] = Chronos::isRunning(item["uuid"])
                    object["item-data"] = {}
                    object["item-data"]["data"] = data
                    object                
                }
                .each{|object| TheFlock::addOrUpdateObject(object) }
        }
    end

    def self.processObjectAndCommand(object, command)
        if command=="start" then
            Chronos::start(object["uuid"])
            timespanInSeconds = Chronos::start(object["item-data"]["data"]["projectuuid"])
            ProjectsCore::updateTodayCommonTimeBySeconds(timespanInSeconds)
        end
        if command=="stop" then
            Chronos::stop(object["uuid"])
            timespanInSeconds = Chronos::stop(object["item-data"]["data"]["projectuuid"])
            ProjectsCore::updateTodayCommonTimeBySeconds(timespanInSeconds)
        end
    end
end
