
require_relative "Events.rb"

# ----------------------------------------------------------------

$flock = nil

# ----------------------------------------------------------------

# FlockOperator::flockObjects()
# FlockOperator::removeObjectIdentifiedByUUID(uuid)
# FlockOperator::removeObjectsFromAgent(agentuuid)
# FlockOperator::addOrUpdateObject(object)
# FlockOperator::addOrUpdateObjects(objects)
# FlockOperator::getDoNotShowUntilDateTimeDistribution()
# FlockOperator::setDoNotShowUntilDateTime(uuid, datetime)

class FlockOperator
    def self.flockObjects()
        $flock["objects"].clone
    end
    
    def self.removeObjectIdentifiedByUUID(uuid)
        $flock["objects"].reject!{|o| o["uuid"]==uuid }
    end

    def self.removeObjectsFromAgent(agentuuid)
        $flock["objects"].reject!{|o| o["agent-uid"]==agentuuid }
    end

    def self.addOrUpdateObject(object)
        FlockOperator::removeObjectIdentifiedByUUID(object["uuid"])
        $flock["objects"] << object
    end

    def self.addOrUpdateObjects(objects)
        objects.each{|object|
            FlockOperator::addOrUpdateObject(object)
        }
    end    
    
    def self.getDoNotShowUntilDateTimeDistribution()
        $flock["do-not-show-until-datetime-distribution"]
    end

    def self.setDoNotShowUntilDateTime(uuid, datetime)
        $flock["do-not-show-until-datetime-distribution"][uuid] = datetime
    end
end

# FlockDiskIO::loadFromEventsTimeline()

class FlockDiskIO
    def self.loadFromEventsTimeline()
        flock = {}
        flock["objects"] = []
        flock["do-not-show-until-datetime-distribution"] = {}
        flock["kvstore"] = {}
        EventsManager::eventsEnumerator().each{|event| # for the moment we rely on the fact that they are loaded in the right order
            if event["event-type"] == "Catalyst:Catalyst-Object:1" then
                object = event["object"]
                flock["objects"].reject!{|o| o["uuid"]==object["uuid"] }
                flock["objects"] << object
                next
            end
            if event["event-type"] == "Catalyst:Destroy-Catalyst-Object:1" then
                objectuuid = event["object-uuid"]
                flock["objects"].reject!{|o| o["uuid"]==objectuuid }
                next
            end
            if event["event-type"] == "Catalyst:Metadata:DoNotShowUntilDateTime:1" then
                flock["do-not-show-until-datetime-distribution"][event["object-uuid"]] = event["datetime"]
                next
            end
            if event["event-type"] == "Flock:KeyValueStore:Set:1" then
                flock["kvstore"][event["key"]] = event["value"]
                next
            end
            raise "Don't know how to interpret event: \n#{JSON.pretty_generate(event)}"
        }
        $flock = flock
    end
end
