
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

require "/Galaxy/local-resources/Ruby-Libraries/SetsOperator.rb"
=begin
    # setuuids are used as namespace, therefore the same uuid in different sets are different values.
    SetsOperator::insert(repositorylocation or nil, setuuid, valueuuid, value)
    SetsOperator::getOrNull(repositorylocation or nil, setuuid, valueuuid)
    SetsOperator::delete(repositorylocation or nil, setuuid, valueuuid)
    SetsOperator::values(repositorylocation or nil, setuuid)
=end

# ----------------------------------------------------------------


# TheFlock::removeObjectIdentifiedByUUID(uuid)
# TheFlock::removeObjectsFromAgent(agentuuid)
# TheFlock::addOrUpdateObjects(objects)
# TheFlock::setDoNotShowUntilDateTime(uuid, datetime)
# TheFlock::getObjectByUUIDOrNull(uuid)

class TheFlock

    # TheFlock::flockObjects()
    def self.flockObjects()
        SetsOperator::values(CATALYST_COMMON_PATH_TO_KV_REPOSITORY, "7c4296f8-092b-4e4e-ba08-f867ab871bab")
    end

    # TheFlock::removeObjectIdentifiedByUUID(uuid)
    def self.removeObjectIdentifiedByUUID(uuid)
        SetsOperator::delete(CATALYST_COMMON_PATH_TO_KV_REPOSITORY, "7c4296f8-092b-4e4e-ba08-f867ab871bab", uuid)
    end

    # TheFlock::removeObjectsFromAgent(agentuuid)
    def self.removeObjectsFromAgent(agentuuid)
        TheFlock::flockObjects()
            .select{|object| object["agent-uid"]==agentuuid }
            .each{|object| TheFlock::removeObjectIdentifiedByUUID(object["uuid"]) }
    end

    # TheFlock::addOrUpdateObject(object)
    def self.addOrUpdateObject(object)
        SetsOperator::insert(CATALYST_COMMON_PATH_TO_KV_REPOSITORY, "7c4296f8-092b-4e4e-ba08-f867ab871bab", object["uuid"], object)
    end

    # TheFlock::addOrUpdateObjects(objects)
    def self.addOrUpdateObjects(objects)
        objects.each{|object|
            TheFlock::addOrUpdateObject(object)
        }
    end    
    
    def self.setDoNotShowUntilDateTime(uuid, datetime)
        DoNotShowUntilDatetime::setDatetime(uuid, datetime)
    end

    def self.getObjectByUUIDOrNull(uuid)
        SetsOperator::getOrNull(CATALYST_COMMON_PATH_TO_KV_REPOSITORY, "7c4296f8-092b-4e4e-ba08-f867ab871bab", uuid)
    end

end

# ------------------------------------------------------------------------


