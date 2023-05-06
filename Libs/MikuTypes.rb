# encoding: utf-8

=begin
MikuTypes
    MikuTypes::bladesEnumerator()
    MikuTypes::mikuTypedBladesEnumerator()
    MikuTypes::mikuTypeEnumerator(mikuType)
    MikuTypes::scan()
    MikuTypes::mikuTypeFilepaths(mikuType)
=end

# MikuTypes is a blade management library.
# It can be used to manage collections of blades with a "mikuType" attribute. We also expect a "uuid" attribute.
# Was introduced when we decided to commit to blades for Catalyst and Nyx.
# It also handle reconciliations and mergings

=begin

The main data type is MTx01: Map[uuid:String, filepath:String]
This is just a map from uuids to the blade filepaths. That map is stored in XCache.

We then have such a map per miku type. Given a miku type we maintain that map and store it in XCache.

Calling for a mikuType will return the blades that are known and haven't moved since the last time
the collection was indexed. If the client wants a proper enumeration of all the blade, they should use
the scanner.

=end

require 'fileutils'
# FileUtils.mkpath '/a/b/c'
# FileUtils.cp(src, dst)
# FileUtils.rm(path_to_image)
# FileUtils.rm_rf(dir)

require 'digest/sha1'
# Digest::SHA1.hexdigest 'foo'
# Digest::SHA1.file(myFile).hexdigest
# Digest::SHA256.hexdigest 'message'  
# Digest::SHA256.file(myFile).hexdigest

require 'json'

require 'securerandom'
# SecureRandom.hex    #=> "eb693ec8252cd630102fd0d0fb7c3485"
# SecureRandom.hex(4) #=> "eb693"
# SecureRandom.uuid   #=> "2d931510-d99f-494a-8c67-87feb05e1594"

require 'find'

require_relative "Blades.rb"

=begin
Blades
    Blades::decideInitLocation(uuid)
    Blades::locateBlade(token)

    Blades::init(uuid)
    Blades::setAttribute(uuid, attribute_name, value)
    Blades::getAttributeOrNull(uuid, attribute_name)
    Blades::addToSet(uuid, set_id, element_id, value)
    Blades::removeFromSet(uuid, set_id, element_id)
    Blades::putDatablob(uuid, key, datablob)
    Blades::getDatablobOrNull(uuid, key)
=end

require_relative "XCache.rb"

# -----------------------------------------------------------------------------------

class MikuTypes

    # MikuTypes::bladesEnumerator()
    def self.bladesEnumerator()
        root = "#{ENV["HOME"]}/Galaxy/DataHub/Blades"
        Enumerator.new do |filepaths|
           begin
                Find.find(root) do |path|
                    next if !File.file?(path)
                    filepath = path
                    if filepath[-6, 6] == ".blade" then
                        filepaths << path
                    end
                end
            rescue
            end
        end
    end

    # MikuTypes::mikuTypeEnumerator(mikuType)
    def self.mikuTypeEnumerator(mikuType)
        Enumerator.new do |filepaths|
            MikuTypes::bladesEnumerator().each{|filepath|
                if Blades::getMandatoryAttribute(filepath, "mikuType") == mikuType then
                    filepaths << filepath
                end
            }
        end
    end

    # MikuTypes::registerFilepath(filepath1)
    def self.registerFilepath(filepath1)
        mikuType = Blades::getMandatoryAttribute(filepath1, "mikuType")
        uuid = Blades::getMandatoryAttribute(filepath1, "uuid")
        mtx01 = XCache::getOrNull("blades:mikutype->MTx01:mapping:42da489f9ef7:#{mikuType}")
        if mtx01.nil? then
            mtx01 = {}
        else
            mtx01 = JSON.parse(mtx01)
        end

        filepath0 = mtx01[uuid]

        if filepath0 and File.exist?(filepath0) and filepath1 != filepath0 then
            # We have two blades with the same uuid. We might want to merge them.
            puts "We have two blades with the same uuid. We might want to merge them."
            puts "filepath0: #{filepath0}"
            puts "filepath1: #{filepath1}"
            puts "MikuTypes doesn't yet know how to do that"
            raise "method not implemented"
            # We need to preserve filepath1 because that's the one we are going to register
        end

        mtx01[uuid] = filepath1
        XCache::set("blades:uuid->filepath:mapping:7239cf3f7b6d:#{uuid}", filepath1)
        XCache::set("blades:mikutype->MTx01:mapping:42da489f9ef7:#{mikuType}", JSON.generate(mtx01))
    end

    # MikuTypes::unregisterFilepath(mikuType, filepath)
    def self.unregisterFilepath(mikuType, filepath)
        mtx01 = XCache::getOrNull("blades:mikutype->MTx01:mapping:42da489f9ef7:#{mikuType}")
        if mtx01.nil? then
            mtx01 = {}
        else
            mtx01 = JSON.parse(mtx01)
        end
        mtx01 = mtx01.to_a.reject{|pair| pair[1] == filepath }.to_h
        XCache::set("blades:mikutype->MTx01:mapping:42da489f9ef7:#{mikuType}", JSON.generate(mtx01))
    end

    # MikuTypes::scan()
    def self.scan()
        # scans the file system in search of .blade files and update the cache
        MikuTypes::bladesEnumerator().each{|filepath|
            MikuTypes::registerFilepath(filepath)
        }
    end

    # MikuTypes::mikuTypeFilepaths(mikuType) # Array[filepath]
    def self.mikuTypeFilepaths(mikuType)
        mtx01 = XCache::getOrNull("blades:mikutype->MTx01:mapping:42da489f9ef7:#{mikuType}")
        if mtx01.nil? then
            mtx01 = {}
        else
            mtx01 = JSON.parse(mtx01)
        end
        mtx01
            .values
            .map{|filepath|
                if File.exist?(filepath) then
                    filepath
                else
                    # The file no longer exists at this location, we need to garbage collect it from the mtx01
                    MikuTypes::unregisterFilepath(mikuType, filepath)
                    nil
                end
            }
            .compact
            .sort
    end
end
