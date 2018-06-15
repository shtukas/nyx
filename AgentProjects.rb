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

    def self.objectHoursDone(uuid)
        Chronos::adaptedTimespanInSeconds(uuid).to_f/3600
    end

    def self.metric(uuid, isRunning)
        0.2 + 0.2*Math.exp(-self.objectHoursDone(uuid))
    end

    def self.makeCatalystObjectOrNull(uuid)
        description = ProjectsCore::projectUUID2NameOrNull(uuid)
        announce = "project: #{description}"
        if ProjectsCore::projectCatalystObjectUUIDsThatAreAlive(uuid).size>0 then
            announce = announce + " [OBJECTS]"
        end
        announce = announce + " (#{ "%.2f" % (Chronos::adaptedTimespanInSeconds(uuid).to_f/3600) } hours)"
        status = Chronos::status(uuid)
        isRunning = status[0]
        object              = {}
        object["uuid"]      = uuid
        object["agent-uid"] = self.agentuuid()
        object["metric"]    = self.metric(uuid, isRunning)
        object["announce"]  = announce
        object["commands"]  = []
        object["default-expression"] = "dive"
        object["isRunning"] = isRunning
        object["item-data"] = {}
        object["item-data"]["timings"] = Chronos::timings(uuid).map{|pair| [ Time.at(pair[0]).to_s, pair[1].to_f/3600 ] }
        object
    end

    def self.interface()
    end

    def self.generalFlockUpgrade()
        TheFlock::removeObjectsFromAgent(self.agentuuid())
        #return if (Time.new.hour>=23 or Time.new.hour < 7)
        objects = ProjectsCore::projectsUUIDs()
            .map{|uuid| AgentProjects::makeCatalystObjectOrNull(uuid) }
            .compact
        TheFlock::addOrUpdateObjects(objects)
    end

    def self.processObjectAndCommandFromCli(object, command)
        if command=="dive" then
            ProjectsCore::ui_projectDive(object["uuid"])
        end
    end
end
