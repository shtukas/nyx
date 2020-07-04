# encoding: UTF-8

require 'digest/sha1'
# Digest::SHA1.hexdigest 'foo'
# Digest::SHA1.file(myFile).hexdigest

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

require 'find'

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

require "/Users/pascal/Galaxy/LucilleOS/Libraries/Ruby-Libraries/BTreeSets.rb"
=begin
    BTreeSets::values(repositorylocation or nil, setuuid: String): Array[Value]
    BTreeSets::set(repositorylocation or nil, setuuid: String, valueuuid: String, value)
    BTreeSets::getOrNull(repositorylocation or nil, setuuid: String, valueuuid: String): nil | Value
    BTreeSets::destroy(repositorylocation, setuuid: String, valueuuid: String)
=end

require_relative "Quarks.rb"
require_relative "Cubes.rb"
require_relative "Cliques.rb"
require_relative "NyxGarbageCollection.rb"
require_relative "Quarks.rb"

require_relative "Asteroids.rb"
require_relative "VideoStream.rb"
require_relative "Drives.rb"

# ------------------------------------------------------------------------

class NyxPrimaryStoreBlobs

    # NyxPrimaryStoreBlobs::namedhashToBlobsFilepath(namedhash)
    def self.namedhashToBlobsFilepath(namedhash)
        if namedhash.start_with?("SHA256-") then
            fragment1 = namedhash[7, 2]
            fragment2 = namedhash[9, 2]
            fragment3 = namedhash[11, 2]
            filepath = "/Users/pascal/Galaxy/DataBank/Catalyst/Nyx-Primary-Store/blobs/#{fragment1}/#{fragment2}/#{fragment3}/#{namedhash}.data"
            if !File.exists?(File.dirname(filepath)) then
                FileUtils.mkpath(File.dirname(filepath))
            end
            return filepath
        end
        raise "[NyxPrimaryStoreUtils: a9c49293-497f-4371-98a5-6d71a7f1ba80]"
    end

    # NyxPrimaryStoreBlobs::put(blob) # namedhash
    def self.put(blob)
        namedhash = "SHA256-#{Digest::SHA256.hexdigest(blob)}"
        filepath = NyxPrimaryStoreBlobs::namedhashToBlobsFilepath(namedhash)
        File.open(filepath, "w") {|f| f.write(blob) }
        namedhash
    end

    # NyxPrimaryStoreBlobs::getBlobOrNull(namedhash)
    def self.getBlobOrNull(namedhash)
        filepath = NyxPrimaryStoreBlobs::namedhashToBlobsFilepath(namedhash)
        return nil if !File.exists?(filepath)
        IO.read(filepath)
    end
end

class NyxPrimaryStoreObjects

    # NyxPrimaryStoreObjects::nyxNxSets()
    def self.nyxNxSets()
        # Duplicated in NyxSets
        [
            "b66318f4-2662-4621-a991-a6b966fb4398", # Asteroids
            "7deb0315-98b5-4e4d-9ad2-d83c2f62e6d4", # Waves
            "4ebd0da9-6fe4-442e-81b9-eda8343fc1e5", # Cliques
            "6b240037-8f5f-4f52-841d-12106658171f", # Quarks
            "a00b82aa-c047-4497-82bf-16c7206913e4", # QuarkTags
            "13f3499d-fa9c-44bb-91d3-8a3ccffecefb", # Bosons
        ]
    end

    # NyxPrimaryStoreObjects::namedhashToObjectsFilepath(namedhash)
    def self.namedhashToObjectsFilepath(namedhash)
        if namedhash.start_with?("SHA256-") then
            fragment1 = namedhash[7, 2]
            fragment2 = namedhash[9, 2]
            fragment3 = namedhash[11, 2]
            filepath = "/Users/pascal/Galaxy/DataBank/Catalyst/Nyx-Primary-Store/objects/#{fragment1}/#{fragment2}/#{fragment3}/#{namedhash}.json"
            if !File.exists?(File.dirname(filepath)) then
                FileUtils.mkpath(File.dirname(filepath))
            end
            return filepath
        end
        raise "[NyxPrimaryStoreUtils: a10f1670-b694-4937-b155-cbfa695b784a]"
    end

    # NyxPrimaryStoreObjects::put(object) # namedhash
    def self.put(object)
        if object["uuid"].nil? then
            raise "[NyxPrimaryStoreObjects::put b45f7d8a] #{object}"
        end
        if object["nyxNxSet"].nil? then
            raise "[NyxPrimaryStoreObjects::put fd215c77] #{object}"
        end
        if !NyxPrimaryStoreObjects::nyxNxSets().include?(object["nyxNxSet"]) then
            raise "[NyxPrimaryStoreObjects::nyxNxSets c883b1e7] #{object}"
        end
        object["nyxNxStoreTimestamp"] = Time.new.to_f
        blob = JSON.generate(object)
        namedhash = "SHA256-#{Digest::SHA256.hexdigest(blob)}"
        filepath = NyxPrimaryStoreObjects::namedhashToObjectsFilepath(namedhash)
        File.open(filepath, "w") {|f| f.write(blob) }
        namedhash
    end

    # NyxPrimaryStoreObjects::objectsEnumerator()
    def self.objectsEnumerator()
        Enumerator.new do |objects|
            Find.find("/Users/pascal/Galaxy/DataBank/Catalyst/Nyx-Primary-Store/objects") do |path|
                next if !File.file?(path)
                next if path[-5, 5] != ".json"
                objects << JSON.parse(IO.read(path))
            end
        end
    end
end

