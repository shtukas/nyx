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
        metric = 0.2 + 0.2*Math.exp(-self.objectHoursDone(uuid))
        isRunning ? 3 + CommonsUtils::traceToMetricShift(uuid) : metric + CommonsUtils::traceToMetricShift(uuid)
    end

    def self.hasText(folderpath)
        IO.read("#{folderpath}/collection-text.txt").size>0
    end

    def self.hasDocuments(folderpath)
        Dir.entries("#{folderpath}/documents").select{|filename| filename[0,1]!="." }.size>0
    end

    def self.makeCatalystObjectOrNull(folderpath)
        uuid = ProjectsCore::folderPath2ProjectUUIDOrNull(folderpath)
        return nil if uuid.nil?
        description = ProjectsCore::folderPath2CollectionName(folderpath)
        announce = "project: #{description}"
        if self.hasText(folderpath) then
            announce = announce + " [TEXT]"
        end
        if self.hasDocuments(folderpath) then
            announce = announce + " [DOCUMENTS]"
        end
        if ProjectsCore::projectCatalystObjectUUIDsThatAreAlive(uuid).size>0 then
            announce = announce + " [OBJECTS]"
        end
        announce = announce + " (#{ "%.2f" % (Chronos::adaptedTimespanInSeconds(uuid).to_f/3600) } hours)"
        status = Chronos::status(uuid)
        isRunning = status[0]
        object = {
            "uuid"               => uuid,
            "agent-uid"          => self.agentuuid(),
            "metric"             => self.metric(uuid, isRunning),
            "announce"           => announce,
            "commands"           => [],
            "default-expression" => "dive"
        }
        object["item-data"] = {}
        object["item-data"]["folderpath"] = folderpath
        object["item-data"]["timings"] = Chronos::timings(uuid).map{|pair| [ Time.at(pair[0]).to_s, pair[1].to_f/3600 ] }
        object
    end

    def self.interface()
    end

    def self.generalFlockUpgrade()
        TheFlock::removeObjectsFromAgent(self.agentuuid())
        return if (Time.new.hour>=23 or Time.new.hour < 7)
        objects = ProjectsCore::projectsFolderpaths()
            .map{|folderpath| AgentProjects::makeCatalystObjectOrNull(folderpath) }
            .compact
        TheFlock::addOrUpdateObjects(objects)
    end

    def self.processObjectAndCommandFromCli(object, command)
        if command=="dive" then
            ProjectsCore::ui_ProjectDive(object["uuid"])
        end
    end
end
