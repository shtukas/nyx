# encoding: UTF-8

# require_relative "NyxSets.rb"

require 'digest/sha1'
# Digest::SHA1.hexdigest 'foo'
# Digest::SHA1.file(myFile).hexdigest

require 'securerandom'
# SecureRandom.hex    #=> "eb693ec8252cd630102fd0d0fb7c3485"
# SecureRandom.hex(4) #=> "eb693123"
# SecureRandom.uuid   #=> "2d931510-d99f-494a-8c67-87feb05e1594"

require "/Users/pascal/Galaxy/LucilleOS/Libraries/Ruby-Libraries/KeyValueStore.rb"
=begin
    KeyValueStore::setFlagTrue(repositorylocation or nil, key)
    KeyValueStore::setFlagFalse(repositorylocation or nil, key)
    KeyValueStore::flagIsTrue(repositorylocation or nil, key)

    KeyValueStore::set(repositorylocation or nil, key, value)
    KeyValueStore::getOrNull(repositorylocation or nil, key)
    KeyValueStore::getOrDefaultValue(repositorylocation or nil, key, defaultValue)
    KeyValueStore::destroy(repositorylocation or nil, key)
=end

require "/Users/pascal/Galaxy/LucilleOS/Libraries/Ruby-Libraries/BTreeSets.rb"
=begin
    BTreeSets::values(repositorylocation or nil, setuuid: String): Array[Value]
    BTreeSets::set(repositorylocation or nil, setuuid: String, valueuuid: String, value)
    BTreeSets::getOrNull(repositorylocation or nil, setuuid: String, valueuuid: String): nil | Value
    BTreeSets::destroy(repositorylocation, setuuid: String, valueuuid: String)
=end

require_relative "Ping.rb"
=begin 
    Ping::put(uuid, weight)
    Ping::totalOverTimespan(uuid, timespanInSeconds)
    Ping::totalToday(uuid)
=end

require_relative "Mercury.rb"
=begin
    Mercury::postValue(channel, value)
    Mercury::getFirstValueOrNull(channel)
    Mercury::deleteFirstValue(channel)

    Mercury::discardFirstElementsToEnforeQueueSize(channel, size)
    Mercury::discardFirstElementsToEnforceTimeHorizon(channel, unixtime)

    Mercury::getQueueSize(channel)
    Mercury::getAllValues(channel)
=end

require_relative "SectionsType0141.rb"
# SectionsType0141::contentToSections(text)
# SectionsType0141::applyNextTransformationToContent(content)

require_relative "Quarks.rb"
require_relative "Cubes.rb"
require_relative "Cliques.rb"
require_relative "NyxGarbageCollection.rb"
require_relative "Quarks.rb"

require_relative "Asteroids.rb"
require_relative "VideoStream.rb"
require_relative "Drives.rb"

# ------------------------------------------------------------------------

class NyxSets

    # NyxSets::nyxNxSets()
    def self.nyxNxSets()
        # Duplicated in NyxObjects
        [
            "b66318f4-2662-4621-a991-a6b966fb4398", # Asteroids
            "7deb0315-98b5-4e4d-9ad2-d83c2f62e6d4", # Waves
            "4ebd0da9-6fe4-442e-81b9-eda8343fc1e5", # Cliques
            "6b240037-8f5f-4f52-841d-12106658171f", # Quarks
            "a00b82aa-c047-4497-82bf-16c7206913e4", # QuarkTags
            "13f3499d-fa9c-44bb-91d3-8a3ccffecefb", # Bosons
        ]
    end

    # NyxSets::putObject(object)
    def self.putObject(object)
        if object["uuid"].nil? then
            raise "[NyxSets::putObject 03fa74db] #{object}"
        end
        if object["nyxNxSet"].nil? then
            raise "[NyxSets::putObject 383a2ed4] #{object}"
        end
        if !NyxSets::nyxNxSets().include?(object["nyxNxSet"]) then
            raise "[NyxSets::putObject 5b203f53] #{object}"
        end
        object["nyxNxStoreTimestamp"] = Time.new.to_f
        
        # Storing on disk
        BTreeSets::set("#{CatalystCommon::catalystDataCenterFolderpath()}/Nyx-Sets", object["nyxNxSet"], object["uuid"], object)

        # Operator
        $X9176ffbef04a.putObject(object)

        object
    end

    # NyxSets::getObjectFromSetOrNull(setid, uuid)
    def self.getObjectFromSetOrNull(setid, uuid)
        # Slow version
        # BTreeSets::getOrNull("#{CatalystCommon::catalystDataCenterFolderpath()}/Nyx-Sets", setid, uuid)

        # Faster version
        $X9176ffbef04a.getObjectFromSetOrNull(setid, uuid)
    end

    # NyxSets::getObjectOrNull(uuid)
    def self.getObjectOrNull(uuid)

        # Slow version
        # NyxSets::nyxNxSets()
        #    .map{|setid| NyxSets::getObjectFromSetOrNull(setid, uuid) }
        #    .compact
        #    .first

        # Faster version
        $X9176ffbef04a.getObjectFromSetOrNull(nil, uuid)
    end

    # NyxSets::objects(setid)
    def self.objects(setid)

        # Slow version
        # BTreeSets::values("#{CatalystCommon::catalystDataCenterFolderpath()}/Nyx-Sets", setid)

        # Faster version
        $X9176ffbef04a.objects(setid)
    end

    # NyxSets::destroyObject(uuid)
    def self.destroyObject(uuid)
        NyxSets::nyxNxSets()
            .each{|setid| BTreeSets::destroy("#{CatalystCommon::catalystDataCenterFolderpath()}/Nyx-Sets", setid, uuid) }

        $X9176ffbef04a.destroyObject(uuid)
    end
end

class NyxSetsOperator

    # @allObjectsInMemory = {}

    def initialize()
        @allObjectsInMemory = {}
        NyxSets::nyxNxSets().each{|setid|
            BTreeSets::values("#{CatalystCommon::catalystDataCenterFolderpath()}/Nyx-Sets", setid).each{|object|
                @allObjectsInMemory[object["uuid"]] = object.clone
            }
        }
    end

    def putObject(object)
        @allObjectsInMemory[object["uuid"]] = object.clone
    end

    def getObjectFromSetOrNull(setid, uuid)
        @allObjectsInMemory
            .values
            .select{|object| object["uuid"] == uuid }
            .map{|object| object.clone }
            .first
    end

    def objects(setid)
        @allObjectsInMemory
            .values
            .select{|object| object["nyxNxSet"] == setid }
            .map{|object| object.clone }
    end

    def destroyObject(uuid)
        @allObjectsInMemory.delete(uuid)
    end
end

if !defined?($X9176ffbef04a) then
    $X9176ffbef04a = NyxSetsOperator.new()
end
