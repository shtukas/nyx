#!/usr/bin/ruby

# encoding: UTF-8

require 'digest/sha1'
# Digest::SHA1.hexdigest 'foo'
# Digest::SHA1.file(myFile).hexdigest

require "/Galaxy/local-resources/Ruby-Libraries/LucilleCore.rb"

require_relative "Constants.rb"
require_relative "Events.rb"
require_relative "MiniFIFOQ.rb"
require_relative "Config.rb"
require_relative "GenericTimeTracking.rb"
require_relative "CatalystDevOps.rb"
require_relative "CollectionsOperator.rb"
require_relative "NotGuardian"
require_relative "FolderProbe.rb"
require_relative "CommonsUtils"

# -------------------------------------------------------------------------------------

# AgentCollections::objectMetricAsFloat
# AgentCollections::objectMetrics(uuid)
# AgentCollections::getObjectTimeCommitmentInHours(uuid)

class AgentCollections

    def self.agentuuid()
        "e4477960-691d-4016-884c-8694db68cbfb"
    end

    def self.agentAdaptedHours()
        GenericTimeTracking::adaptedTimespanInSeconds(CATALYST_COMMON_AGENTCOLLECTIONS_METRIC_GENERIC_TIME_TRACKING_KEY).to_f/3600
    end

    def self.getObjectTimeCommitmentInHours(uuid)
        folderpath = CollectionsOperator::collectionUUID2FolderpathOrNull(uuid)
        if folderpath.nil? then
            raise "error e95e2fda: Could not find fodler path for uuid: #{uuid}" 
        end
        if File.exists?("#{folderpath}/collection-time-commitment-override") then
            return IO.read("#{folderpath}/collection-time-commitment-override").to_f
        end
        if File.exists?("#{folderpath}/collection-time-positional-coefficient") then
            return IO.read("#{folderpath}/collection-time-positional-coefficient").to_f * CollectionsOperator::dailyCommitmentInHours()
        end
        0
    end

    def self.objectMetricRelativelyToItsCoefficientCommitment(uuid)
        time = self.getObjectTimeCommitmentInHours(uuid)
        if time==0 then
            0
        else
            if self.objectAdaptedHours(uuid) > time then
                0
            else
                0.2 + Math.atan(time).to_f/100 + 0.6*Math.exp(-self.objectAdaptedHours(uuid).to_f/time)
            end
        end
    end

    def self.objectLowMetricRelativelyToItsAdaptedHours(uuid)
        0.1 + 0.2*Math.exp(-self.objectAdaptedHours(uuid))
    end

    def self.objectAdaptedHours(uuid)
        GenericTimeTracking::adaptedTimespanInSeconds(uuid).to_f/3600
    end

    def self.objectMetrics(uuid)
        style = CollectionsOperator::getCollectionStyle(uuid)
        if style=="PROJECT" then
            return [self.getObjectTimeCommitmentInHours(uuid), self.objectAdaptedHours(uuid), self.objectMetricRelativelyToItsCoefficientCommitment(uuid), self.objectLowMetricRelativelyToItsAdaptedHours(uuid)]
        end
        if style=="THREAD" then
            return [0,                                         self.objectAdaptedHours(uuid), 0,                                                           self.objectLowMetricRelativelyToItsAdaptedHours(uuid)]
        end
    end

    def self.objectMetricAsFloat(uuid)
        self.objectMetrics(uuid)[2, 3].max
    end

    def self.objectMetricsAsString(uuid)
        dx = lambda {|x| x == "0.000" ? "     " : x }
        AgentCollections::objectMetrics(uuid).map{|value| "%.3f" % value }.map{|str| dx.call(str) }.join(", ")
    end

    def self.commands(style, isRunning)
        if style=="PROJECT" then
            return ( isRunning ? ["stop"] : ["start"] ) + ["completed", "add-hours", "file", "folder", "objects"]
        end
        if style=="THREAD" then
            return ["completed", "file", "folder"]
        end
        raise "1DA65B35-278D-4620-95E0-2009A6FE2C8C"    
    end

    def self.defaultExpression(style, isRunning)
        if style=="PROJECT" then
            return isRunning ? "stop" : "start"
        end
        if style=="THREAD" then
            return ""
        end
        raise "7EB12414-1471-4C2B-9631-8F75EE428632"
    end

    def self.metric(uuid, style, isRunning)
        if style=="PROJECT" then
            metric = AgentCollections::objectMetricAsFloat(uuid)
            return isRunning ? 2 - CommonsUtils::traceToMetricShift(uuid) : metric + CommonsUtils::traceToMetricShift(uuid)
        end
        if style=="THREAD" then
            return 0.3 + CommonsUtils::traceToMetricShift(uuid)
        end
        raise "BE024B93-F68B-47CC-B252-AF81FFDD8867"    
    end

    def self.hasText(folderpath)
        IO.read("#{folderpath}/collection-text.txt").size>0
    end

    def self.hasDocuments(folderpath)
        Dir.entries("#{folderpath}/documents").select{|filename| filename[0,1]!="." }.size>0
    end

    def self.makeCatalystObjectOrNull(folderpath)
        uuid = CollectionsOperator::folderPath2CollectionUUIDOrNull(folderpath)
        return nil if uuid.nil?
        description = CollectionsOperator::folderPath2CollectionName(folderpath)
        style = CollectionsOperator::getCollectionStyle(uuid)
        announce = "collection (#{style.downcase}): #{description}"
        if self.hasText(folderpath) then
            announce = announce + " [TEXT]"
        end
        if self.hasDocuments(folderpath) then
            announce = announce + " [DOCUMENTS]"
        end
        if CollectionsOperator::collectionCatalystObjectUUIDsThatAreAlive(uuid).size>0 then
            announce = announce + " [OBJECTS]"
        end
        announce = announce + " (#{ "%.2f" % (GenericTimeTracking::adaptedTimespanInSeconds(uuid).to_f/3600) } hours)"
        status = GenericTimeTracking::status(uuid)
        isRunning = status[0]
        object = {
            "uuid"               => uuid,
            "agent-uid"          => self.agentuuid(),
            "metric"             => self.metric(uuid, style, isRunning),
            "announce"           => "(metrics: #{AgentCollections::objectMetricsAsString(uuid)}) #{announce}",
            "commands"           => self.commands(style, isRunning),
            "default-expression" => self.defaultExpression(style, isRunning)
        }
        object["item-data"] = {}
        object["item-data"]["folderpath"] = folderpath
        object["item-data"]["timings"] = GenericTimeTracking::timings(uuid).map{|pair| [ Time.at(pair[0]).to_s, pair[1].to_f/3600 ] }
        object
    end

    def self.interfaceFromCli()
    end    

    def self.generalUpgradeFromFlockServer()
        halves = [0.5, 0.25, 0.125, 0.0625, 0.03125, 0.015625]
        CollectionsOperator::collectionsFolderpaths()
            .select{|folderpath| IO.read("#{folderpath}/collection-style")=="PROJECT" }
            .first(6)
            .zip(halves)
            .each{|pair|
                folderpath = pair[0]
                hours = pair[1]
                File.open("#{folderpath}/collection-time-positional-coefficient", "w"){|f| f.write(hours)}
            }
        objects = CollectionsOperator::collectionsFolderpaths()
            .map{|folderpath| AgentCollections::makeCatalystObjectOrNull(folderpath) }
            .compact
        FlockOperator::removeObjectsFromAgent(self.agentuuid())
        FlockOperator::addOrUpdateObjects(objects)
    end

    def self.processObjectAndCommandFromCli(object, command)
        if command=='start' then
            folderpath = object["item-data"]["folderpath"]
            #system("open '#{folderpath}'")
            GenericTimeTracking::start(object["uuid"])
            GenericTimeTracking::start(CATALYST_COMMON_AGENTCOLLECTIONS_METRIC_GENERIC_TIME_TRACKING_KEY)
        end
        if command=='stop' then
            GenericTimeTracking::stop(object["uuid"])
            GenericTimeTracking::stop(CATALYST_COMMON_AGENTCOLLECTIONS_METRIC_GENERIC_TIME_TRACKING_KEY)
        end
        if command=="completed" then
            folderpath = object["item-data"]["folderpath"]
            if self.hasText(folderpath) then
                puts "You cannot complete this item because it has text"
                LucilleCore::pressEnterToContinue()
                return
            end
            if self.hasDocuments(folderpath) then
                puts "You cannot complete this item because it has documents"
                LucilleCore::pressEnterToContinue()
                return
            end
            if CollectionsOperator::collectionCatalystObjectUUIDsThatAreAlive(object["uuid"]).size>0 then
                puts "You cannot complete this item because it has objects"
                LucilleCore::pressEnterToContinue()
                return
            end
            GenericTimeTracking::stop(object["uuid"])
            GenericTimeTracking::stop(CATALYST_COMMON_AGENTCOLLECTIONS_METRIC_GENERIC_TIME_TRACKING_KEY)
            CollectionsOperator::sendCollectionToBinTimeline(object["uuid"])
        end
        if command == "add-hours" then
            uuid = object["uuid"]
            timespan = 3600*LucilleCore::askQuestionAnswerAsString("hours: ").to_f
            GenericTimeTracking::addTimeInSeconds(uuid, timespan)
        end
        if command=='file' then
            folderpath = object["item-data"]["folderpath"]
            filepath = "#{folderpath}/collection-text.txt"
            system("open '#{filepath}'")
        end
        if command=="folder" then
            system("open '#{object["item-data"]["folderpath"]}'")
        end
        if command=='objects' then
            collectionuuid = object["uuid"]
            CollectionsOperator::ui_loopDiveCollectionObjects(collectionuuid)
        end
    end
end
