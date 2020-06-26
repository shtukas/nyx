# encoding: UTF-8

# This variable contains the objects of the current display.
# We use it to speed up display after some operations

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

class NyxCoreStoreBlobs

    # NyxCoreStoreBlobs::namedhashToBlobsFilepath(namedhash)
    def self.namedhashToBlobsFilepath(namedhash)
        if namedhash.start_with?("SHA256-") then
            fragment1 = namedhash[7, 2]
            fragment2 = namedhash[9, 2]
            fragment3 = namedhash[11, 2]
            filepath = "/Users/pascal/Galaxy/DataBank/Catalyst/Nyx-Core-Store/blobs/#{fragment1}/#{fragment2}/#{fragment3}/#{namedhash}.data"
            if !File.exists?(File.dirname(filepath)) then
                FileUtils.mkpath(File.dirname(filepath))
            end
            return filepath
        end
        raise "[NyxCoreStoreUtils: a9c49293-497f-4371-98a5-6d71a7f1ba80]"
    end

    # NyxCoreStoreBlobs::put(blob) # namedhash
    def self.put(blob)
        namedhash = "SHA256-#{Digest::SHA256.hexdigest(blob)}"
        filepath = NyxCoreStoreBlobs::namedhashToBlobsFilepath(namedhash)
        File.open(filepath, "w") {|f| f.write(blob) }
        namedhash
    end

    # NyxCoreStoreBlobs::getBlobOrNull(namedhash)
    def self.getBlobOrNull(namedhash)
        filepath = NyxCoreStoreBlobs::namedhashToBlobsFilepath(namedhash)
        return nil if !File.exists?(filepath)
        IO.read(filepath)
    end
end

class NyxCoreStoreObjects

    # NyxCoreStoreObjects::nyxNxSets()
    def self.nyxNxSets()
        # Duplicated in NyxSets
        [
            "1aaa9485-2c07-4b14-a5c3-ed1d6772ca19" # Interface Floats
        ]
    end

    # NyxCoreStoreObjects::namedhashToObjectsFilepath(namedhash)
    def self.namedhashToObjectsFilepath(namedhash)
        if namedhash.start_with?("SHA256-") then
            fragment1 = namedhash[7, 2]
            fragment2 = namedhash[9, 2]
            fragment3 = namedhash[11, 2]
            filepath = "/Users/pascal/Galaxy/DataBank/Catalyst/Nyx-Core-Store/objects/#{fragment1}/#{fragment2}/#{fragment3}/#{namedhash}.json"
            if !File.exists?(File.dirname(filepath)) then
                FileUtils.mkpath(File.dirname(filepath))
            end
            return filepath
        end
        raise "[NyxCoreStoreUtils: a10f1670-b694-4937-b155-cbfa695b784a]"
    end

    # NyxCoreStoreObjects::put(object) # namedhash
    def self.put(object)
        if object["uuid"].nil? then
            raise "[NyxCoreStoreObjects::put b45f7d8a] #{object}"
        end
        if object["nyxNxSet"].nil? then
            raise "[NyxCoreStoreObjects::put fd215c77] #{object}"
        end
        if !NyxCoreStoreObjects::nyxNxSets().include?(object["nyxNxSet"]) then
            raise "[NyxCoreStoreObjects::nyxNxSets c883b1e7] #{object}"
        end
        object["nyxNxStoreTimestamp"] = Time.new.to_f
        blob = JSON.generate(object)
        namedhash = "SHA256-#{Digest::SHA256.hexdigest(blob)}"
        filepath = NyxCoreStoreObjects::namedhashToObjectsFilepath(namedhash)
        File.open(filepath, "w") {|f| f.write(blob) }
        namedhash
    end

    # NyxCoreStoreObjects::objectsEnumerator()
    def self.objectsEnumerator()
        Enumerator.new do |objects|
            Find.find("/Users/pascal/Galaxy/DataBank/Catalyst/Nyx-Core-Store/objects") do |path|
                next if !File.file?(path)
                next if path[-5, 5] != ".json"
                objects << JSON.parse(IO.read(path))
            end
        end
    end
end

