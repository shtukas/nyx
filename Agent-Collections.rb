#!/usr/bin/ruby

# encoding: UTF-8

# -------------------------------------------------------------------------------------

class AgentCollections

    def self.agentuuid()
        "e4477960-691d-4016-884c-8694db68cbfb"
    end

    def self.agentMetric()
        0.8 - 0.6*( GenericTimeTracking::adaptedTimespanInSeconds(CATALYST_COMMON_AGENTCOLLECTIONS_METRIC_GENERIC_TIME_TRACKING_KEY).to_f/3600 ).to_f/3
    end

    def self.objectMetric(uuid)
        Math.exp(-GenericTimeTracking::adaptedTimespanInSeconds(uuid).to_f/3600).to_f/100
    end

    def self.commands(style, isRunning)
        if style=="PROJECT" then
            return ( isRunning ? ["stop"] : ["start"] ) + ["completed", "file", "folder"]
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
            return isRunning ? 2 - CommonsUtils::traceToMetricShift(uuid) : self.agentMetric() + self.objectMetric(uuid) + CommonsUtils::traceToMetricShift(uuid)
        end
        if style=="THREAD" then
            return 0.3 + CommonsUtils::traceToMetricShift(uuid)
        end
        raise "BE024B93-F68B-47CC-B252-AF81FFDD8867"    
    end

    def self.makeCatalystObjectOrNull(folderpath)
        uuid = OperatorCollections::folderPath2CollectionUUIDOrNull(folderpath)
        return nil if uuid.nil?
        description = OperatorCollections::folderPath2CollectionName(folderpath)
        style = OperatorCollections::getCollectionStyle(uuid)
        announce = "collection (#{style.downcase}): #{description}"
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

    def self.interface()

    end    

    def self.generalUpgrade()
        objects = OperatorCollections::collectionsFolderpaths()
            .map{|folderpath| AgentCollections::makeCatalystObjectOrNull(folderpath) }
            .compact
        FlockTransformations::removeObjectsFromAgent(self.agentuuid())
        FlockTransformations::addOrUpdateObjects(objects)
    end

    def self.processObjectAndCommand(object, command)
        if command=='file' then
            folderpath = object["item-data"]["folderpath"]
            filepath = "#{folderpath}/collection-text.txt"
            system("open '#{filepath}'")
        end
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
            GenericTimeTracking::stop(object["uuid"])
            GenericTimeTracking::stop(CATALYST_COMMON_AGENTCOLLECTIONS_METRIC_GENERIC_TIME_TRACKING_KEY)
            OperatorCollections::sendCollectionToBinTimeline(object["uuid"])
        end
        if command=="folder" then
            system("open '#{object["item-data"]["folderpath"]}'")
        end
    end
end
