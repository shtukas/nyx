
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
require "/Galaxy/local-resources/Ruby-Libraries/LucilleCore.rb"
require_relative "Events.rb"

require "/Galaxy/local-resources/Ruby-Libraries/KeyValueStore.rb"
=begin
    KeyValueStore::set(repositorylocation or nil, key, value)
    KeyValueStore::getOrNull(repositorylocation or nil, key)
    KeyValueStore::getOrDefaultValue(repositorylocation or nil, key, defaultValue)
    KeyValueStore::destroy(repositorylocation or nil, key)
=end

# ----------------------------------------------------------------
$flock = nil
# ------------------------------------------------------------------------
# FlockDiskIO::loadFromEventsTimeline()

class FlockDiskIO
    def self.loadFromEventsTimeline()
        flock = {}
        flock["objects"] = []
        EventsManager::eventsAsTimeOrderedArray()
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
                    DoNotShowUntilDatetime::setDatetime(event["object-uuid"], event["datetime"])
                    next
                end
                if event["event-type"] == "Flock:KeyValueStore:Set:1" then    
                    next
                end
                if event["event-type"] == "Flock:KeyValueStore:Delete:1" then
                    next
                end
                raise "Don't know how to interpret event: \n#{JSON.pretty_generate(event)}"
            }
        $flock = flock
    end
end

# ----------------------------------------------------------------

# TheFlock::flockObjects()
# TheFlock::removeObjectIdentifiedByUUID(uuid)
# TheFlock::removeObjectsFromAgent(agentuuid)
# TheFlock::addOrUpdateObjects(objects)
# TheFlock::setDoNotShowUntilDateTime(uuid, datetime)
# TheFlock::getObjectByUUIDOrNull(uuid)

class TheFlock
    def self.flockObjects()
        $flock["objects"].clone
    end

    def self.removeObjectIdentifiedByUUID(uuid)
        $flock["objects"] = $flock["objects"].reject{|o| o["uuid"]==uuid }
    end

    def self.removeObjectsFromAgent(agentuuid)
        $flock["objects"] = $flock["objects"].reject{|o| o["agent-uid"]==agentuuid }
    end

    # TheFlock::addOrUpdateObject(object)
    def self.addOrUpdateObject(object)
        TheFlock::removeObjectIdentifiedByUUID(object["uuid"])
        $flock["objects"] =  $flock["objects"] + [ object ]
    end

    def self.addOrUpdateObjects(objects)
        objects.each{|object|
            TheFlock::addOrUpdateObject(object)
        }
    end    
    
    def self.setDoNotShowUntilDateTime(uuid, datetime)
        DoNotShowUntilDatetime::setDatetime(uuid, datetime)
    end

    def self.getObjectByUUIDOrNull(uuid)
        TheFlock::flockObjects().select{|object| object["uuid"]==uuid }.first
    end

end

# ------------------------------------------------------------------------


