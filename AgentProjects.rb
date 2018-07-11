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
        "object-command-processor" => lambda{ |object, command| AgentProjects::processObjectAndCommand(object, command) },
        "interface"       => lambda{ AgentProjects::interface() }
    }
)

# AgentProjects::metric

class AgentProjects

    def self.agentuuid()
        "e4477960-691d-4016-884c-8694db68cbfb"
    end

    def self.interface()
    end

    def self.generalFlockUpgrade()
        TheFlock::removeObjectsFromAgent(self.agentuuid())
        ProjectsCore::projectsUUIDs()
            .select{|projectuuid| FKVStore::getOrNull("60407375-7e5d-4cfe-98fb-ecd34c0f2247:#{projectuuid}:#{Time.new.to_s[0, 13]}").nil? }
            .map{|projectuuid| 
                timestructure = ProjectsCore::getTimeStructureAskIfAbsent(projectuuid)
                timedoneInHours, timetodoInHours, ratio = TimeStructuresOperator::doneMetricsForTimeStructure(projectuuid, timestructure)
                object              = {}
                object["uuid"]      = projectuuid
                object["agent-uid"] = self.agentuuid()
                object["metric"]    = MetricsOfTimeStructures::metric2(projectuuid, 0.1, 0.2, 0.6, timestructure) + CommonsUtils::traceToMetricShift(projectuuid)
                object["announce"]  = "project: #{ProjectsCore::ui_projectToString(projectuuid)} ( #{100*ratio.round(2)} % of #{timetodoInHours.round(2)} hours [today] )"
                object["commands"]  = Chronos::isRunning(projectuuid) ? ["stop", "dive"] : ["start", "dive"]
                object["default-expression"] = Chronos::isRunning(projectuuid) ? "stop" : "start"
                object["is-running"] = Chronos::isRunning(projectuuid)
                object["item-data"] = {}
                object["item-data"]["timings"] = Chronos::timings(projectuuid).map{|pair| [ Time.at(pair[0]).to_s, pair[1].to_f/3600 ] }
                object            
            }
            .each{|object| TheFlock::addOrUpdateObject(object) }
    end

    def self.processObjectAndCommand(object, command)
        if command=="dive" then
            ProjectsCore::ui_projectDive(object["uuid"])
        end
        if command=="start" then
            Chronos::start(object["uuid"])
        end
        if command=="stop" then
            timespanInSeconds = Chronos::stop(object["uuid"])
            ProjectsCore::updateTodayCommonTimeBySeconds(timespanInSeconds)
        end
    end
end
