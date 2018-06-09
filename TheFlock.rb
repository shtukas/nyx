
# encoding: UTF-8

require 'json'

require 'date'

require 'colorize'

require 'securerandom'
# SecureRandom.hex    #=> "eb693ec8252cd630102fd0d0fb7c3485"
# SecureRandom.hex(4) #=> "eb693123"
# SecureRandom.uuid   #=> "2d931510-d99f-494a-8c67-87feb05e1594"

require 'fileutils'
# FileUtils.mkpath '/a/b/c'
# FileUtils.cp(src, dst)
# FileUtils.mv 'oldname', 'newname'
# FileUtils.rm(path_to_image)
# FileUtils.rm_rf('dir/to/remove')
require 'digest/sha1'
# Digest::SHA1.hexdigest 'foo'
# Digest::SHA1.file(myFile).hexdigest
require 'find'

require 'digest/sha1'
# Digest::SHA1.hexdigest 'foo'
# Digest::SHA1.file(myFile).hexdigest

require 'drb/drb'
require 'thread'

require_relative "Events.rb"

# ----------------------------------------------------------------

require "/Galaxy/local-resources/Ruby-Libraries/LucilleCore.rb"
require "/Galaxy/LucilleOS/Librarian/Librarian-Exported-Functions.rb"

require_relative "Wave-Emails.rb"
require_relative "Constants.rb"
require_relative "Events.rb"
require_relative "Events.rb"
require_relative "MiniFIFOQ.rb"
require_relative "Config.rb"
require_relative "GenericTimeTracking.rb"
require_relative "CatalystDevOps.rb"
require_relative "FolderProbe.rb"
require_relative "CommonsUtils"
require_relative "TodayOrNotToday.rb"
require_relative "RequirementsOperator.rb"
require_relative "CollectionsCore.rb"
require_relative "NotGuardian.rb"
require_relative "CommonsUtils.rb"
require_relative "AgentsManager.rb"

require_relative "Agent-Collections.rb"
require_relative "Agent-DailyTimeAttribution.rb"
require_relative "Agent-Ninja.rb"
require_relative "Agent-Stream.rb"
require_relative "Agent-TimeCommitments.rb"
require_relative "Agent-Today.rb"
require_relative "Agent-Vienna.rb"
require_relative "Agent-Wave.rb"

# ----------------------------------------------------------------

# FlockOperator::flockObjects()
# FlockOperator::flockObjectsAsMap()
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
    
    def self.flockObjectsAsMap()
        map = {}
        FlockOperator::flockObjects().each{|object|
            map[object["uuid"]] = object
        }
        map
    end

    def self.removeObjectIdentifiedByUUID(uuid)
        $flock["objects"] = $flock["objects"].reject{|o| o["uuid"]==uuid }
    end

    def self.removeObjectsFromAgent(agentuuid)
        $flock["objects"] = $flock["objects"].reject{|o| o["agent-uid"]==agentuuid }
    end

    def self.addOrUpdateObject(object)
        FlockOperator::removeObjectIdentifiedByUUID(object["uuid"])
        $flock["objects"] =  $flock["objects"] + [ object ]
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

# ------------------------------------------------------------------------

# FKVStore::getOrNull(key): value
# FKVStore::getOrDefaultValue(key, defaultValue): value
# FKVStore::set(key, value)

class FKVStore
    def self.getOrNull(key)
        $flock["kvstore"][key]
    end

    def self.getOrDefaultValue(key, defaultValue)
        value = FKVStore::getOrNull(key)
        if value.nil? then
            value = defaultValue
        end
        value
    end

    def self.set(key, value)
        $flock["kvstore"][key] = value
        EventsManager::commitEventToTimeline(EventsMaker::fKeyValueStoreSet(key, value))
    end
end

# ------------------------------------------------------------------------

# FlockDiskIO::loadFromEventsTimeline()

class FlockDiskIO
    def self.loadFromEventsTimeline()
        flock = {}
        flock["objects"] = []
        flock["do-not-show-until-datetime-distribution"] = {}
        flock["kvstore"] = {}
        EventsManager::eventsEnumerator() 
            .sort{|e1,e2| e1["event-time"]<=>e2["event-time"] }
            .each{|event| 
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

# ------------------------------------------------------------------------

class FlockService
    def self.topObjects(count)
        # The first upgrade should come first as it makes objects building, metric updates etc.
        # All the others send metric to zero when relevant and they are all commutative.
        AgentsManager::generalFlockUpgrade()
        TodayOrNotToday::transform()
        RequirementsOperator::transform()
        CommonsUtils::fDoNotShowUntilDateTimeTransform()
        CollectionsCore::transform()
        NotGuardian::transform()
        FlockOperator::flockObjects()
            .select{|object| object["metric"] >= 0.2 }
            .sort{|o1,o2| o1['metric']<=>o2['metric'] }
            .reverse
            .take(count)
    end
end
# ----------------------------------------------------------------

