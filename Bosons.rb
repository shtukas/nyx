
# encoding: UTF-8

# require_relative "Bosons.rb"

require 'fileutils'
# FileUtils.mkpath '/a/b/c'
# FileUtils.cp(src, dst)
# FileUtils.mv 'oldname', 'newname'
# FileUtils.rm(path_to_image)
# FileUtils.rm_rf('dir/to/remove')

require 'securerandom'
# SecureRandom.hex    #=> "eb693ec8252cd630102fd0d0fb7c3485"
# SecureRandom.hex(4) #=> "eb693123"
# SecureRandom.uuid   #=> "2d931510-d99f-494a-8c67-87feb05e1594"

require 'digest/sha1'
# Digest::SHA1.hexdigest 'foo'
# Digest::SHA1.file(myFile).hexdigest

require_relative "Quarks.rb"

require_relative "Cliques.rb"

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

# -----------------------------------------------------------------


class Bosons

    # Bosons::link(object1, object2)
    def self.link(object1, object2)
        if object1["linkedTo"].nil? then
            object1["linkedTo"] = []
        end
        object1["linkedTo"] << object2["uuid"]
        object1["linkedTo"] = object1["linkedTo"].uniq
        NyxObjects::put(object1)

        if object2["linkedTo"].nil? then
            object2["linkedTo"] = []
        end
        object2["linkedTo"] << object1["uuid"]
        object2["linkedTo"] = object2["linkedTo"].uniq
        NyxObjects::put(object2)
    end

    # Bosons::getLinkedObjects(object)
    def self.getLinkedObjects(object)
        return [] if object["linkedTo"].nil?
        object["linkedTo"]
            .map{|uuid| NyxObjects::getOrNull(uuid) }
            .compact
    end

    # Bosons::getLinkedObjectsOfGivenNyxNxSet(focus, setid)
    def self.getLinkedObjectsOfGivenNyxNxSet(focus, setid)
        return [] if focus["linkedTo"].nil?
        focus["linkedTo"]
            .map{|uuid| NyxObjects::getOrNull(uuid) }
            .compact
            .select{|object| object["nyxNxSet"] == setid }
    end

    # Bosons::unlink(object1, object2)
    def self.unlink(object1, object2)
        if object1["linkedTo"].nil? then
            object1["linkedTo"] = []
        end
        object1["linkedTo"].delete(object2["uuid"])
        object1["linkedTo"] = object1["linkedTo"].uniq
        NyxObjects::put(object1)

        if object2["linkedTo"].nil? then
            object2["linkedTo"] = []
        end
        object2["linkedTo"].delete(object1["uuid"])
        object2["linkedTo"] = object2["linkedTo"].uniq
        NyxObjects::put(object2)
    end

end
