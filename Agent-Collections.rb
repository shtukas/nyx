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
# AgentCollections::projectsPositionalCoefficientSequence()

class AgentCollections

    def self.agentuuid()
        "e4477960-691d-4016-884c-8694db68cbfb"
    end

    def self.objectHoursDone(uuid)
        GenericTimeTracking::adaptedTimespanInSeconds(uuid).to_f/3600
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
            "metric"             => self.metric(uuid, isRunning),
            "announce"           => announce,
            "commands"           => [],
            "default-expression" => "dive"
        }
        object["item-data"] = {}
        object["item-data"]["folderpath"] = folderpath
        object["item-data"]["timings"] = GenericTimeTracking::timings(uuid).map{|pair| [ Time.at(pair[0]).to_s, pair[1].to_f/3600 ] }
        object
    end

    def self.interface()
    end    

    def self.projectsPositionalCoefficientSequence()
        LucilleCore::integerEnumerator().lazy.map{|n| 1.to_f/(2 ** n) }
    end

    def self.generalFlockUpgrade()
        FlockOperator::removeObjectsFromAgent(self.agentuuid())
        objects = CollectionsOperator::collectionsFolderpaths()
            .map{|folderpath| AgentCollections::makeCatalystObjectOrNull(folderpath) }
            .compact
        FlockOperator::addOrUpdateObjects(objects)
    end

    def self.processObjectAndCommandFromCli(object, command)
        if command=="dive" then
            CollectionsOperator::ui_CollectionDive(object["uuid"])
        end
    end
end
