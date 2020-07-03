# encoding: UTF-8

# require "/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/Nyx.v2/NyxSets.rb"

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

require "/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/Catalyst/Ping.rb"
=begin 
    Ping::put(uuid, weight)
    Ping::totalOverTimespan(uuid, timespanInSeconds)
    Ping::totalToday(uuid)
=end

require "/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/Catalyst/Mercury.rb"
=begin
    Mercury::postValue(channel, value)
    Mercury::getFirstValueOrNull(channel)
    Mercury::deleteFirstValue(channel)

    Mercury::discardFirstElementsToEnforeQueueSize(channel, size)
    Mercury::discardFirstElementsToEnforceTimeHorizon(channel, unixtime)

    Mercury::getQueueSize(channel)
    Mercury::getAllValues(channel)
=end

require "/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/Catalyst/SectionsType0141.rb"
# SectionsType0141::contentToSections(text)
# SectionsType0141::applyNextTransformationToContent(content)

require "/Users/pascal/Galaxy/LucilleOS/Libraries/Ruby-Libraries/BTreeSets.rb"
=begin
    BTreeSets::values(repositorylocation or nil, setuuid: String): Array[Value]
    BTreeSets::set(repositorylocation or nil, setuuid: String, valueuuid: String, value)
    BTreeSets::getOrNull(repositorylocation or nil, setuuid: String, valueuuid: String): nil | Value
    BTreeSets::destroy(repositorylocation, setuuid: String, valueuuid: String)
=end

require "/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/Nyx/Quarks.rb"
require "/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/Nyx/Cubes.rb"
require "/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/Nyx/Cliques.rb"
require "/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/Nyx/NyxGarbageCollection.rb"
require "/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/Nyx/Quarks.rb"

require "/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/Asteroids/Asteroids.rb"
require "/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/VideoStream/VideoStream.rb"
require "/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/Catalyst/Drives.rb"

# ------------------------------------------------------------------------

class NyxSets

    # NyxSets::nyxNxSets()
    def self.nyxNxSets()
        # Duplicated in NyxCoreStoreObjects
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
        BTreeSets::set("/Users/pascal/Galaxy/DataBank/Catalyst/Nyx-Sets", object["nyxNxSet"], object["uuid"], object)
        object
    end

    # NyxSets::getObjectFromSetOrNull(setid, uuid)
    def self.getObjectFromSetOrNull(setid, uuid)
        BTreeSets::getOrNull("/Users/pascal/Galaxy/DataBank/Catalyst/Nyx-Sets", setid, uuid)
    end

    # NyxSets::getObjectOrNull(uuid)
    def self.getObjectOrNull(uuid)
        NyxSets::nyxNxSets()
            .map{|setid| NyxSets::getObjectFromSetOrNull(setid, uuid) }
            .compact
            .first
    end

    # NyxSets::objects(setid)
    def self.objects(setid)
        BTreeSets::values("/Users/pascal/Galaxy/DataBank/Catalyst/Nyx-Sets", setid)
    end

    # NyxSets::destroy(uuid)
    def self.destroy(uuid)
        NyxSets::nyxNxSets()
            .each{|setid| BTreeSets::destroy("/Users/pascal/Galaxy/DataBank/Catalyst/Nyx-Sets", setid, uuid) }
    end
end


