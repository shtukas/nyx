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

    # NyxObjects::uuidToObjectFilepath(uuid)
    def self.uuidToObjectFilepath(uuid)
        hash1 = Digest::SHA256.hexdigest(uuid)
        fragment1 = hash1[0, 2]
        fragment2 = hash1[2, 2]
        filepath = "#{CatalystCommon::catalystDataCenterFolderpath()}/Nyx-Objects/#{fragment1}/#{fragment2}/#{hash1}.json"
        if !File.exists?(File.dirname(filepath)) then
            FileUtils.mkpath(File.dirname(filepath))
        end
        return filepath
    end

    # NyxObjects::put(object)
    def self.put(object)
        if object["uuid"].nil? then
            raise "[NyxObjects::put 8d58ee87] #{object}"
        end
        if object["nyxNxSet"].nil? then
            raise "[NyxObjects::put d781f18f] #{object}"
        end
        if !NyxObjects::nyxNxSets().include?(object["nyxNxSet"]) then
            raise "[NyxObjects::nyxNxSets 50229c3e] #{object}"
        end
        filepath = NyxObjects::uuidToObjectFilepath(object["uuid"])
        if File.exists?(filepath) then
            raise "[error (3303a3ca): objects are immutable, do not change once written]"
        end
        File.open(filepath, "w") {|f| f.puts(JSON.pretty_generate(object)) }
        nil
    end

    # NyxObjects::objectsEnumerator()
    def self.objectsEnumerator()
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
        NyxObjects::objectsEnumerator().to_a
    end

    # NyxObjects::getOrNull(uuid)
    def self.getOrNull(uuid)
        filepath = NyxObjects::uuidToObjectFilepath(uuid)
        return nil if !File.exists?(filepath)
        JSON.parse(IO.read(filepath))
    end

    # NyxObjects::getSet(setid)
    def self.getSet(setid)
        NyxObjects::objectsEnumerator()
            .select{|object| object["nyxNxSet"] == setid }
    end

    # NyxObjects::destroy(uuid)
    def self.destroy(uuid)
        filepath = NyxObjects::uuidToObjectFilepath(uuid)
        return nil if !File.exists?(filepath)
        FileUtils.rm(filepath)
    end
end
