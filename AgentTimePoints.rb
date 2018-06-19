#!/usr/bin/ruby

# encoding: UTF-8
require 'json'
require 'date'
require 'digest/sha1'
# Digest::SHA1.hexdigest 'foo'
# Digest::SHA1.file(myFile).hexdigest
require 'securerandom'
# SecureRandom.hex    #=> "eb693ec8252cd630102fd0d0fb7c3485"
# SecureRandom.hex(4) #=> "eb693123"
# SecureRandom.uuid   #=> "2d931510-d99f-494a-8c67-87feb05e1594"
require 'fileutils'
# FileUtils.mkpath '/a/b/c'
# FileUtils.cp(src, dst)
# FileUtils.mv('oldname', 'newname')
# FileUtils.rm(path_to_image)
# FileUtils.rm_rf('dir/to/remove')
require 'find'
require 'colorize'
require 'digest/sha1'
# Digest::SHA1.hexdigest 'foo'
# Digest::SHA1.file(myFile).hexdigest
require "/Galaxy/local-resources/Ruby-Libraries/SetsOperator.rb"
require "/Galaxy/local-resources/Ruby-Libraries/LucilleCore.rb"
require_relative "Bob.rb"
# -------------------------------------------------------------------------------------


# -------------------------------------------------------------------------------------

Bob::registerAgent(
    {
        "agent-name"      => "TimePoints",
        "agent-uid"       => "03a8bff4-a2a4-4a2b-a36f-635714070d1d",
        "general-upgrade" => lambda { AgentTimePoints::generalFlockUpgrade() },
        "object-command-processor" => lambda{ |object, command| AgentTimePoints::processObjectAndCommandFromCli(object, command) },
        "interface"       => lambda{ AgentTimePoints::interface() }
    }
)

# AgentTimePoints::generalFlockUpgrade()
# AgentTimePoints::processObjectAndCommandFromCli(object, command)

class AgentTimePoints

    def self.agentuuid()
        "03a8bff4-a2a4-4a2b-a36f-635714070d1d"
    end

    def self.interface()

    end

    def self.timepointToCatalystObjectOrNull(timepoint)
        uuid = timepoint['uuid']
        announce = "time commitment: #{timepoint['description']} (#{ "%.2f" % (100*TimePointsCore::timePointToRatioDoneUpToDate(timepoint)) } % of #{"%.2f" % timepoint["commitment-in-hours"]} hours done)"
        commands = timepoint["is-running"] ? ["stop", "destroy"] : ["start", "reset", "destroy"]
        defaultExpression = timepoint["is-running"] ? "stop" : "start"
        object  = {}
        object["uuid"]      = uuid
        object["agent-uid"] = self.agentuuid()
        object["metric"]    = TimePointsCore::timePointToMetric(timepoint)
        object["announce"]  = announce
        object["commands"]  = commands
        object["default-expression"] = defaultExpression
        object["is-running"]         = timepoint["is-running"]
        object["metadata"]           = {}
        object["metadata"]["is-running"] = timepoint["is-running"]
        object["metadata"]["time-commitment-timepoint"] = timepoint
        object
    end

    def self.generalFlockUpgrade()
        TimePointsCore::garbageCollection()
        TheFlock::removeObjectsFromAgent(self.agentuuid())
        objects = TimePointsCore::getTimePoints()
            .map{|timepoint| AgentTimePoints::timepointToCatalystObjectOrNull(timepoint) }
            .compact
        TheFlock::addOrUpdateObjects(objects)
    end

    def self.processObjectAndCommandFromCli(object, command)
        uuid = object['uuid']
        if command == "start" then
            TimePointsCore::saveTimePoint(TimePointsCore::startTimePoint(TimePointsCore::getTimePointByUUID(uuid)))
        end
        if command == "stop" then
            TimePointsCore::saveTimePoint(TimePointsCore::stopTimePoint(TimePointsCore::getTimePointByUUID(uuid)))
        end
        if command == "reset" then
            timepoint = TimePointsCore::getTimePointByUUID(uuid)
            timepoint["commitment-in-hours"] = timepoint["commitment-in-hours"] - timepoint["timespans"].inject(0, :+).to_f/3600
            timepoint["timespans"] = []
            timepoint["metric"] = TimePointsCore::timePointToMetric(timepoint)
            TimePointsCore::saveTimePoint(timepoint)
        end
        if command == "destroy" then
            TimePointsCore::destroyTimePoint(TimePointsCore::getTimePointByUUID(uuid))
        end
    end
end

