# encoding: UTF-8

require 'digest/sha1'
# Digest::SHA1.hexdigest 'foo'
# Digest::SHA1.file(myFile).hexdigest

require 'fileutils'
# FileUtils.mkpath '/a/b/c'
# FileUtils.cp(src, dst)
# FileUtils.mv 'oldname', 'newname'
# FileUtils.rm(path_to_image)
# FileUtils.rm_rf('dir/to/remove')

require 'find'

require 'securerandom'
# SecureRandom.hex    #=> "eb693ec8252cd630102fd0d0fb7c3485"
# SecureRandom.hex(4) #=> "eb693123"
# SecureRandom.uuid   #=> "2d931510-d99f-494a-8c67-87feb05e1594"

require_relative "KeyValueStore.rb"
=begin
    KeyValueStore::setFlagTrue(repositorylocation or nil, key)
    KeyValueStore::setFlagFalse(repositorylocation or nil, key)
    KeyValueStore::flagIsTrue(repositorylocation or nil, key)

    KeyValueStore::set(repositorylocation or nil, key, value)
    KeyValueStore::getOrNull(repositorylocation or nil, key)
    KeyValueStore::getOrDefaultValue(repositorylocation or nil, key, defaultValue)
    KeyValueStore::destroy(repositorylocation or nil, key)
=end

require_relative "BTreeSets.rb"
=begin
    BTreeSets::values(repositorylocation or nil, setuuid: String): Array[Value]
    BTreeSets::set(repositorylocation or nil, setuuid: String, valueuuid: String, value)
    BTreeSets::getOrNull(repositorylocation or nil, setuuid: String, valueuuid: String): nil | Value
    BTreeSets::destroy(repositorylocation, setuuid: String, valueuuid: String)
=end

# ------------------------------------------------------------------------

class NyxObjects

    # Private Utils

    # NyxObjects::nyxNxSets()
    def self.nyxNxSets()
        # Duplicated in NyxSets
        [
            "b66318f4-2662-4621-a991-a6b966fb4398", # Asteroids
            "7deb0315-98b5-4e4d-9ad2-d83c2f62e6d4", # Waves
            "4ebd0da9-6fe4-442e-81b9-eda8343fc1e5", # Cliques
            "6b240037-8f5f-4f52-841d-12106658171f", # Quarks
        ]
    end

    # NyxObjects::namedHashToObjectsFilepath(namedhash)
    def self.namedHashToObjectsFilepath(namedhash)
        if namedhash.start_with?("SHA256-") then
            fragment1 = namedhash[7, 2]
            fragment2 = namedhash[9, 2]
            fragment3 = namedhash[11, 2]
            filepath = "#{CatalystCommon::catalystDataCenterFolderpath()}/Nyx-Objects/#{fragment1}/#{fragment2}/#{fragment3}/#{namedhash}.json"
            if !File.exists?(File.dirname(filepath)) then
                FileUtils.mkpath(File.dirname(filepath))
            end
            return filepath
        end
        raise "[NyxPrimaryStoreUtils: a10f1670-b694-4937-b155-cbfa695b784a]"
    end

    # NyxObjects::primaryStoreObjectsEnumerator()
    def self.primaryStoreObjectsEnumerator()
        Enumerator.new do |objects|
            Find.find("#{CatalystCommon::catalystDataCenterFolderpath()}/Nyx-Objects") do |path|
                next if !File.file?(path)
                next if path[-5, 5] != ".json"
                objects << JSON.parse(IO.read(path))
            end
        end
    end

    # NyxObjects::objects()
    def self.objects()
        mapping = {}
        NyxObjects::primaryStoreObjectsEnumerator()
            .each{|object|
                if mapping[object["uuid"]].nil? then
                    mapping[object["uuid"]] = object
                else
                    if mapping[object["uuid"]]["nyxNxStoreTimestamp"] < object["nyxNxStoreTimestamp"] then
                        mapping[object["uuid"]] = object
                    end
                end
            }
        mapping
            .values
            .select{|object| !object["nyxNxSet"].nil? } # removing the ones that have been deleted
            .select{|object| NyxObjects::nyxNxSets().include?(object["nyxNxSet"]) } # only select the one from alive sets
    end

    # Public Interface

    # NyxObjects::put(object) # namedhash
    def self.put(object)
        if object["uuid"].nil? then
            raise "[NyxObjects::put b45f7d8a] #{object}"
        end
        if object["nyxNxSet"].nil? then
            raise "[NyxObjects::put fd215c77] #{object}"
        end
        if !NyxObjects::nyxNxSets().include?(object["nyxNxSet"]) then
            raise "[NyxObjects::nyxNxSets c883b1e7] #{object}"
        end
        object["nyxNxStoreTimestamp"] = Time.new.to_f
        blob = JSON.pretty_generate(object)
        namedhash = "SHA256-#{Digest::SHA256.hexdigest(blob)}"
        filepath = NyxObjects::namedHashToObjectsFilepath(namedhash)
        File.open(filepath, "w") {|f| f.write(blob) }
        NyxObjectsCacheOperator::put(object)
    end

    # NyxObjects::getOrNull(uuid)
    def self.getOrNull(uuid)
        NyxObjectsCacheOperator::getOrNull(uuid)
    end

    # NyxObjects::getSet(setid)
    def self.getSet(setid)
        NyxObjectsCacheOperator::objects(setid)
    end

    # NyxObjects::destroy(uuid)
    def self.destroy(uuid)
        object = {}
        object["uuid"] = uuid
        object["nyxNxSet"] = nil
        object["nyxNxStoreTimestamp"] = Time.new.to_f
        blob = JSON.pretty_generate(object)
        namedhash = "SHA256-#{Digest::SHA256.hexdigest(blob)}"
        filepath = NyxObjects::namedHashToObjectsFilepath(namedhash)
        File.open(filepath, "w") {|f| f.write(blob) }
        NyxObjectsCacheOperator::destroy(uuid)
    end
end

if !defined?($InMemoryObjectsCache6DB420D8) then
    $InMemoryObjectsCache6DB420D8 = {} # Map[uuid: String, Object]
end

if !defined?($InMemorySetsCache2917988) then
    $InMemorySetsCache2917988 = {} # Map[set: String, Map[uuid: String, Object] ]
end 

class NyxObjectsCacheOperator

    # NyxObjectsCacheOperator::put(object)
    def self.put(object)
        # This is called everytime an object mutates, this is the entry point of the caching system

        # We update the in memory cache
        $InMemoryObjectsCache6DB420D8[object["uuid"]] = object

        # We update the in memory set cache
        # If the in memory set has been initialised
        if $InMemorySetsCache2917988[object["nyxNxSet"]] then
            $InMemorySetsCache2917988[object["nyxNxSet"]][object["uuid"]] = object
        end

        # We update the on disk cache
        KeyValueStore::set(nil, "9a470ad8-ab23-4a51-b94d-195de9912da7:#{object["uuid"]}", JSON.generate(object))

        # We update the set objects
        BTreeSets::set(nil, "d9d54faa-d3e4-41e1-a9e0-317ba20e3884:#{object["nyxNxSet"]}", object["uuid"], object)
    end

    # NyxObjectsCacheOperator::getOrNull(uuid)
    def self.getOrNull(uuid)
        if $InMemoryObjectsCache6DB420D8[uuid] then
            return $InMemoryObjectsCache6DB420D8[uuid].clone
        end

        object = KeyValueStore::getOrNull(nil, "9a470ad8-ab23-4a51-b94d-195de9912da7:#{uuid}")
        if object then
            object = JSON.parse(object)
            $InMemoryObjectsCache6DB420D8[object["uuid"]] = object
            return object
        end

        nil
    end

    # NyxObjectsCacheOperator::objects(setid)
    def self.objects(setid)
        if $InMemorySetsCache2917988[setid].nil? then
            $InMemorySetsCache2917988[setid] = {}
            BTreeSets::values(nil, "d9d54faa-d3e4-41e1-a9e0-317ba20e3884:#{setid}")
                .each{|object|
                    $InMemorySetsCache2917988[setid][object["uuid"]] = object
                }
        end
        $InMemorySetsCache2917988[setid].values.map{|object| object.clone }
    end

    # NyxObjectsCacheOperator::destroy(uuid)
    def self.destroy(uuid)
        $InMemoryObjectsCache6DB420D8.delete(uuid)
        NyxObjects::nyxNxSets().each{|setid|
            next if $InMemorySetsCache2917988[setid].nil?
            $InMemorySetsCache2917988[setid].delete(uuid)
        }
        KeyValueStore::destroy(nil, "9a470ad8-ab23-4a51-b94d-195de9912da7:#{uuid}")
        NyxObjects::nyxNxSets().each{|setid|
            BTreeSets::destroy(nil, "d9d54faa-d3e4-41e1-a9e0-317ba20e3884:#{setid}", uuid)
        }
    end

    # NyxObjectsCacheOperator::reCacheAll()
    def self.reCacheAll()
        NyxObjects::objects().each{|object|
            puts JSON.pretty_generate(object)
            KeyValueStore::set(nil, "9a470ad8-ab23-4a51-b94d-195de9912da7:#{object["uuid"]}", JSON.generate(object))
            BTreeSets::set(nil, "d9d54faa-d3e4-41e1-a9e0-317ba20e3884:#{object["nyxNxSet"]}", object["uuid"], object)
        }
    end

end
