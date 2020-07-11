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
    BTreeSets::destroy(repositorylocation or nil, setuuid: String, valueuuid: String)
=end

require_relative "Miscellaneous.rb"

# ------------------------------------------------------------------------

class Miscellaneous
    # Miscellaneous::catalystDataCenterFolderpath()
    def self.catalystDataCenterFolderpath()
        "/Users/pascal/Galaxy/DataBank/Catalyst"
    end
end

class NyxPrimaryObjects

    # NyxPrimaryObjects::nyxNxSets()
    def self.nyxNxSets()
        # Duplicated in NyxSets
        [
            "b66318f4-2662-4621-a991-a6b966fb4398", # Asteroids
            "7deb0315-98b5-4e4d-9ad2-d83c2f62e6d4", # Waves
            "4ebd0da9-6fe4-442e-81b9-eda8343fc1e5", # Cliques
            "6b240037-8f5f-4f52-841d-12106658171f", # Quarks
            "4643abd2-fec6-4184-a9ad-5ad3df3257d6", # Tags
            "13f3499d-fa9c-44bb-91d3-8a3ccffecefb", # Bosons
            "c6fad718-1306-49cf-a361-76ce85e909ca", # Notes
            "4f5ae9bc-9b2a-46ff-9f8b-49bfcabc5a9f", # DescriptionZ
            "1bc9b712-09be-44da-9551-f22d70a3f15d", # DateTimeZ,
            "0f555c97-3843-4dfe-80c8-714d837eba69", # Spin
            "7e99bb92-098d-4f84-a680-f158126aa3bf", # Comment
        ]
    end

    # NyxPrimaryObjects::uuidToObjectFilepath(uuid)
    def self.uuidToObjectFilepath(uuid)
        hash1 = Digest::SHA256.hexdigest(uuid)
        fragment1 = hash1[0, 2]
        fragment2 = hash1[2, 2]
        filepath = "#{Miscellaneous::catalystDataCenterFolderpath()}/Nyx-Objects/#{fragment1}/#{fragment2}/#{hash1}.json"
        if !File.exists?(File.dirname(filepath)) then
            FileUtils.mkpath(File.dirname(filepath))
        end
        return filepath
    end

    # NyxPrimaryObjects::put(object)
    def self.put(object)
        if object["uuid"].nil? then
            raise "[NyxPrimaryObjects::put 8d58ee87] #{object}"
        end
        if object["nyxNxSet"].nil? then
            raise "[NyxPrimaryObjects::put d781f18f] #{object}"
        end
        if !NyxPrimaryObjects::nyxNxSets().include?(object["nyxNxSet"]) then
            raise "[NyxPrimaryObjects::nyxNxSets 50229c3e] #{object}"
        end
        filepath = NyxPrimaryObjects::uuidToObjectFilepath(object["uuid"])
        if File.exists?(filepath) then
            raise "[NyxPrimaryObjects::nyxNxSets 5e710d51] objects on disk are immutable"
        end
        File.open(filepath, "w") {|f| f.puts(JSON.pretty_generate(object)) }
        object
    end

    # NyxPrimaryObjects::objectsEnumerator()
    def self.objectsEnumerator()
        Enumerator.new do |objects|
            Find.find("#{Miscellaneous::catalystDataCenterFolderpath()}/Nyx-Objects") do |path|
                next if !File.file?(path)
                next if path[-5, 5] != ".json"
                object = JSON.parse(IO.read(path))
                object["nyxFilepath"] = path
                objects << object
            end
        end
    end

    # NyxPrimaryObjects::objects()
    def self.objects()
        NyxPrimaryObjects::objectsEnumerator().to_a
    end

    # NyxPrimaryObjects::getOrNull(uuid)
    def self.getOrNull(uuid)
        filepath = NyxPrimaryObjects::uuidToObjectFilepath(uuid)
        return nil if !File.exists?(filepath)
        JSON.parse(IO.read(filepath))
    end

    # NyxPrimaryObjects::destroy(uuid)
    def self.destroy(uuid)
        filepath = NyxPrimaryObjects::uuidToObjectFilepath(uuid)
        return nil if !File.exists?(filepath)
        FileUtils.rm(filepath)
    end
end

# ------------------------------------------------------------------------------
# The rest of Catalyst should not know anything of what happens before this line
# ------------------------------------------------------------------------------

class NyxObjects

    @@objects = {}
    @@sets = {}

    # NyxObjects::init()
    def self.init()
        puts "NyxObjects::init()"
        NyxPrimaryObjects::objects().each{|object|
            @@objects[object["uuid"]] = object
        }
        NyxPrimaryObjects::nyxNxSets().each{|setid|
            @@sets[setid] = {}
        }
        @@objects.values.each{|object|
            @@sets[object["nyxNxSet"]][object["uuid"]] = object
        }
    end

    # NyxObjects::put(object)
    def self.put(object)
        NyxPrimaryObjects::put(object)
        @@objects[object["uuid"]] = object
        @@sets[object["nyxNxSet"]][object["uuid"]] = object
    end

    # NyxObjects::objects()
    def self.objects()
        # NyxPrimaryObjects::objects()
        @@objects.values
    end

    # NyxObjects::getOrNull(uuid)
    def self.getOrNull(uuid)
        # NyxPrimaryObjects::getOrNull(uuid)
        @@objects[uuid]
    end

    # NyxObjects::getSet(setid)
    def self.getSet(setid)
        #NyxObjects::objects().select{|object| object["nyxNxSet"] == setid }
        @@sets[setid].values
    end

    # NyxObjects::destroy(uuid)
    def self.destroy(uuid)
        NyxPrimaryObjects::destroy(uuid)
        @@objects.delete(uuid)
        NyxPrimaryObjects::nyxNxSets().each{|setid|
            @@sets[setid].delete(uuid)
        }
    end
end

NyxObjects::init()

$GlobalInMemoryHash = {}


