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

# AgentCollections::metric

class AgentCollections

    def self.agentuuid()
        "e4477960-691d-4016-884c-8694db68cbfb"
    end

    def self.objectHoursDone(uuid)
        GenericTimeTracking::adaptedTimespanInSeconds(uuid).to_f/3600
    end

    def self.projectMetric(uuid)
        time = CollectionsOperator::getObjectTimeCommitmentInHours(uuid)
        return 0 if time == 0
        0.2 + 0.4*Math.exp(-self.objectHoursDone(uuid).to_f/time)
    end

    def self.threadMetric(uuid)
        0.2 + 0.2*Math.exp(-self.objectHoursDone(uuid))
    end

    def self.metric(uuid, style, isRunning)
        metric = ( CollectionsOperator::getCollectionStyle(uuid) == "PROJECT" ) ? self.projectMetric(uuid) : self.threadMetric(uuid)
        isRunning ? 2 - CommonsUtils::traceToMetricShift(uuid) : metric
    end

    def self.commands(style, isRunning)
        ( isRunning ? ["stop"] : ["start"] ) + ["completed", "add-hours", "file", "folder", "objects", "dive"]    
    end

    def self.defaultExpression(style, isRunning)
        isRunning ? "stop" : "start"
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
        announce = "collection: #{style.downcase}: #{description}"
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
            "announce"           => announce,
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
        FlockOperator::removeObjectsFromAgent(self.agentuuid())
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
        if command=="dive" then
            collectionuuid = object["uuid"]
            CollectionsOperator::ui_mainDiveIntoCollection_v2(collectionuuid)
        end
    end
end
