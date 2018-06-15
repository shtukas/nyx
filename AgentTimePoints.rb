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

TIMEPOINTS_ITEMS_SETUUID = "64cba051-9761-4445-8cd5-8cf49c105ba1" unless defined? TIMEPOINTS_ITEMS_SETUUID
TIMEPOINTS_ITEMS_REPOSITORY_PATH = "#{CATALYST_COMMON_DATABANK_FOLDERPATH}/Agents-Data/time-points/timepoints" unless defined? TIMEPOINTS_ITEMS_REPOSITORY_PATH

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

# AgentTimePoints::getTimePoints()
# AgentTimePoints::getTimePointByUUID(uuid)
# AgentTimePoints::saveTimePoint(timepoint)
# AgentTimePoints::startTimePoint(timepoint)
# AgentTimePoints::stopTimePoint(timepoint)
# AgentTimePoints::destroyTimePoint(timepoint)
# AgentTimePoints::timepointToLiveTimespan(timepoint)
# AgentTimePoints::garbageCollectionItems(timepoints)
# AgentTimePoints::garbageCollectionGlobal()
# AgentTimePoints::getUniqueDomains(timepoints)
# AgentTimePoints::generalFlockUpgrade()
# AgentTimePoints::processObjectAndCommandFromCli(object, command)

class AgentTimePoints

    def self.agentuuid()
        "03a8bff4-a2a4-4a2b-a36f-635714070d1d"
    end

    def self.getTimePoints()
        SetsOperator::values(TIMEPOINTS_ITEMS_REPOSITORY_PATH, TIMEPOINTS_ITEMS_SETUUID)
            .compact
    end

    def self.getTimePointByUUID(uuid)
        SetsOperator::getOrNull(TIMEPOINTS_ITEMS_REPOSITORY_PATH, TIMEPOINTS_ITEMS_SETUUID, uuid)
    end

    def self.saveTimePoint(timepoint)
        SetsOperator::insert(TIMEPOINTS_ITEMS_REPOSITORY_PATH, TIMEPOINTS_ITEMS_SETUUID, timepoint["uuid"], timepoint)
    end

    def self.startTimePoint(timepoint)
        return timepoint if timepoint["is-running"]
        timepoint["is-running"] = true
        timepoint["last-start-unixtime"] = Time.new.to_i
        timepoint
    end

    def self.stopTimePoint(timepoint)
        if timepoint["is-running"] then
            timepoint["is-running"] = false
            timespanInSeconds = Time.new.to_i - timepoint["last-start-unixtime"]
            timepoint["timespans"] << timespanInSeconds
            if timepoint["0e69d463:GuardianSupport"] then
                timepoint = {
                    "uuid"                => SecureRandom.hex(4),
                    "creation-unixtime"   => Time.new.to_i,
                    "domain"              => "6596d75b-a2e0-4577-b537-a2d31b156e74",
                    "description"         => "Guardian",
                    "commitment-in-hours" => -timespanInSeconds,
                    "timespans"           => [],
                    "last-start-unixtime" => 0
                }
                AgentTimePoints::saveTimePoint(timepoint)
            end
        end
        timepoint
    end

    def self.destroyTimePoint(timepoint)
        self.stopTimePoint(timepoint)
        SetsOperator::delete(TIMEPOINTS_ITEMS_REPOSITORY_PATH, TIMEPOINTS_ITEMS_SETUUID, timepoint["uuid"])
    end

    def self.timepointToLiveTimespan(timepoint)
        timepoint["timespans"].inject(0,:+) + ( timepoint["is-running"] ? Time.new.to_i - timepoint["last-start-unixtime"] : 0 )
    end

    def self.garbageCollectionItems(timepoints)
        return if timepoints.size < 2 
        return if timepoints.any?{|timepoint| timepoint["is-running"] }
        timepoint1 = timepoints[0]
        timepoint2 = timepoints[1]
        timepoint3 = {}
        timepoint3["uuid"]        = SecureRandom.hex(4)
        timepoint3["domain"]      = timepoint1["domain"]
        timepoint3["description"] = timepoint1["description"]
        timepoint3["commitment-in-hours"] = ( timepoint1["commitment-in-hours"] + timepoint2["commitment-in-hours"] ) - ( timepoint1["timespans"] + timepoint2["timespans"] ).inject(0, :+).to_f/3600
        timepoint3["timespans"]   = []
        AgentTimePoints::saveTimePoint(timepoint3)
        AgentTimePoints::destroyTimePoint(timepoint1)
        AgentTimePoints::destroyTimePoint(timepoint2)
    end

    def self.garbageCollectionGlobal()
        timepoints = AgentTimePoints::getTimePoints()
        domains = AgentTimePoints::getUniqueDomains(timepoints)
        domains.each{|domain|
            domainItems = timepoints.select{|timepoint| timepoint["domain"]==domain }
            AgentTimePoints::garbageCollectionItems(domainItems)
        }
    end

    def self.getUniqueDomains(timepoints)
        timepoints.map{|timepoint| timepoint["domain"] }.uniq
    end

    def self.interface()
        puts "Welcome to TimeCommitments interface"
        if LucilleCore::interactivelyAskAYesNoQuestionResultAsBoolean("Would you like to add a time commitment ? ") then
            timepoint = {
                "uuid"                => SecureRandom.hex(4),
                "domain"              => SecureRandom.hex(8),
                "description"         => LucilleCore::askQuestionAnswerAsString("description: "),
                "commitment-in-hours" => LucilleCore::askQuestionAnswerAsString("hours: ").to_f,
                "timespans"           => [],
                "last-start-unixtime" => 0
            }
            puts JSON.pretty_generate(timepoint)
            LucilleCore::pressEnterToContinue()
            AgentTimePoints::saveTimePoint(timepoint)
        end
    end

    def self.timepointToCatalystObjectOrNull(timepoint)
        uuid = timepoint['uuid']
        ratioDone = (AgentTimePoints::timepointToLiveTimespan(timepoint).to_f/3600)/timepoint["commitment-in-hours"]
        metric = nil
        if timepoint["is-running"] then
            metric = 2 - CommonsUtils::traceToMetricShift(uuid)
            if ratioDone>1 then
                message = "#{timepoint['description']} is done"
                system("terminal-notifier -title Catalyst -message '#{message}'")
                sleep 2
            end
        else
            metric =
                if timepoint['metric'] then
                    timepoint['metric']
                else
                    0.2 + 0.4*Math.atan(timepoint["commitment-in-hours"]) + 0.1*Math.exp(-ratioDone*3) + CommonsUtils::traceToMetricShift(uuid)
                end
        end
        announce = "time commitment: #{timepoint['description']} (#{ "%.2f" % (100*ratioDone) } % of #{timepoint["commitment-in-hours"]} hours done)"
        commands = ( timepoint["is-running"] ? ["stop"] : ["start"] ) + ["destroy"]
        defaultExpression = timepoint["is-running"] ? "stop" : "start"
        object  = {}
        object["uuid"]      = uuid
        object["agent-uid"] = self.agentuuid()
        object["metric"]    = metric
        object["announce"]  = announce
        object["commands"]  = commands
        object["default-expression"]     = defaultExpression
        object["metadata"]               = {}
        object["metadata"]["is-running"] = timepoint["is-running"]
        object["metadata"]["time-commitment-timepoint"] = timepoint
        object
    end

    def self.generalFlockUpgrade()
        AgentTimePoints::garbageCollectionGlobal()
        TheFlock::removeObjectsFromAgent(self.agentuuid())
        objects = AgentTimePoints::getTimePoints()
            .select{|timepoint| timepoint["commitment-in-hours"] > 0 }
            .map{|timepoint| AgentTimePoints::timepointToCatalystObjectOrNull(timepoint) }
            .compact
        objects = 
            if objects.select{|object| object["metric"]>1 }.size>0 then
                objects.select{|object| object["metric"]>1 }
            else
                objects
            end
        TheFlock::addOrUpdateObjects(objects)
    end

    def self.processObjectAndCommandFromCli(object, command)
        uuid = object['uuid']
        if command == "start" then
            AgentTimePoints::saveTimePoint(AgentTimePoints::startTimePoint(AgentTimePoints::getTimePointByUUID(uuid)))
        end
        if command == "stop" then
            AgentTimePoints::saveTimePoint(AgentTimePoints::stopTimePoint(AgentTimePoints::getTimePointByUUID(uuid)))
        end
        if command == "destroy" then
            AgentTimePoints::destroyTimePoint(AgentTimePoints::getTimePointByUUID(uuid))
        end
    end
end

