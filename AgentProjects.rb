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
        "agent-name"      => "Projects",
        "agent-uid"       => "e4477960-691d-4016-884c-8694db68cbfb",
        "general-upgrade" => lambda { AgentProjects::generalFlockUpgrade() },
        "object-command-processor" => lambda{ |object, command| AgentProjects::processObjectAndCommandFromCli(object, command) },
        "interface"       => lambda{ AgentProjects::interface() }
    }
)

# AgentProjects::metric

class AgentProjects

    def self.agentuuid()
        "e4477960-691d-4016-884c-8694db68cbfb"
    end

    def self.makeCatalystObjectOrNull(projectuuid)
        timestructure = ProjectsCore::getTimeStructureAskIfAbsent(projectuuid)
        object              = {}
        object["uuid"]      = projectuuid
        object["agent-uid"] = self.agentuuid()
        object["metric"]    = MetricsOfTimeStructures::metric2(projectuuid, 0.1, 0.2, 0.6, timestructure) + CommonsUtils::traceToMetricShift(projectuuid)
        object["announce"]  = "project: #{ProjectsCore::projectToString(projectuuid)}"
        object["commands"]  = Chronos::isRunning(projectuuid) ? ["stop", "dive"] : ["start", "dive"]
        object["default-expression"] = Chronos::isRunning(projectuuid) ? "stop" : "start"
        object["is-running"] = Chronos::isRunning(projectuuid)
        object["item-data"] = {}
        object["item-data"]["timings"] = Chronos::timings(projectuuid).map{|pair| [ Time.at(pair[0]).to_s, pair[1].to_f/3600 ] }
        object
    end

    def self.interface()
    end

    def self.generalFlockUpgrade()
        TheFlock::removeObjectsFromAgent(self.agentuuid())
        ProjectsCore::updateLocalTimeStructures()
        ProjectsCore::projectsUUIDs()
            .select{|projectuuid| FKVStore::getOrNull("60407375-7e5d-4cfe-98fb-ecd34c0f2247:#{projectuuid}:#{Time.new.to_s[0, 13]}").nil? }
            .map{|projectuuid| AgentProjects::makeCatalystObjectOrNull(projectuuid) }
            .each{|object| TheFlock::addOrUpdateObject(object) }
        ProjectsCore::localTimeStructuresDataFiles().each{|data|
            projectuuid = data["projectuuid"]
            referenceTimeStructure = data["reference-time-structure"]
            data["local-commitments"]
                .map{|item|
                    timestructure = {}
                    timestructure["time-unit-in-days"] = referenceTimeStructure["time-unit-in-days"]
                    timestructure["time-commitment-in-hours"] = referenceTimeStructure["time-commitment-in-hours"] * item["timeshare"]
                    object              = {}
                    object["uuid"]      = item["uuid"]
                    object["agent-uid"] = self.agentuuid()
                    object["metric"]    = MetricsOfTimeStructures::metric2(item["uuid"], 0.1, 0.5, 0.80, timestructure) + CommonsUtils::traceToMetricShift(item["uuid"])
                    object["announce"]  = "project: #{ProjectsCore::projectUUID2NameOrNull(projectuuid)} / sub: #{item["description"]}"
                    object["commands"]  = Chronos::isRunning(item["uuid"]) ? ["stop-secondary"] : ["start-secondary"]
                    object["default-expression"] = Chronos::isRunning(item["uuid"]) ? "stop-secondary" : "start-secondary"
                    object["is-running"] = Chronos::isRunning(item["uuid"])
                    object["item-data"] = {}
                    object["item-data"]["data"] = data
                    object                
                }
                .each{|object| TheFlock::addOrUpdateObject(object) }
        }
    end

    def self.processObjectAndCommandFromCli(object, command)
        if command=="dive" then
            ProjectsCore::ui_projectDive(object["uuid"])
        end
        if command=="start" then
            Chronos::start(object["uuid"])
        end
        if command=="stop" then
            Chronos::stop(object["uuid"])
        end
        if command=="start-secondary" then
            Chronos::start(object["uuid"])
            Chronos::start(object["item-data"]["data"]["projectuuid"])
        end
        if command=="stop-secondary" then
            Chronos::stop(object["uuid"])
            Chronos::stop(object["item-data"]["data"]["projectuuid"])
        end
    end
end
