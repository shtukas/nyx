
# encoding: UTF-8

# require "/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/Nyx/Bosons.rb"

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

require 'colorize'

require "/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/Nyx/Quarks.rb"

require "/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/Nyx/Cliques.rb"

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

# -----------------------------------------------------------------


class Bosons2

    # Bosons2::pathToDataStore()
    def self.pathToDataStore()
        "/Users/pascal/Galaxy/DataBank/Catalyst/Nxy-Network/Bosons"
    end

    # Bosons2::setDirectedLink(uuid1, uuid2)
    def self.setDirectedLink(uuid1, uuid2)
        # The set uuid1 contains the list of uuids connected to uuid1
        BTreeSets::set(Bosons2::pathToDataStore(), uuid1, uuid2, uuid2)
    end

    # Bosons2::link(object1, object2)
    def self.link(object1, object2)
        # Since links are directed, we need to issue both directed
        Bosons2::setDirectedLink(object1["uuid"], object2["uuid"])
        Bosons2::setDirectedLink(object2["uuid"], object1["uuid"])
    end

    # Bosons2::linked?(object1, object2)
    def self.linked?(object1, object2)
        # We only need to check one direction, since we always set and unset both
        BTreeSets::values(Bosons2::pathToDataStore(), object1["uuid"]).include?(object2["uuid"])
    end

    # Bosons2::getLinkedObjects(object)
    def self.getLinkedObjects(object)
        BTreeSets::values(Bosons2::pathToDataStore(), object["uuid"])
            .map{|uuid| NyxDataCarriers::getObjectOrNull(uuid) ||  NyxSets::getObjectOrNull(uuid) }
            .compact
    end

    # Bosons2::getLinkedObjectsOfGivenNyxType(focus, nyxType)
    def self.getLinkedObjectsOfGivenNyxType(focus, nyxType)
        Bosons2::getLinkedObjects(focus)
            .select{|object| object["nyxType"] == nyxType }
    end

    # Bosons2::unsetDirectedLink(uuid1, uuid2)
    def self.unsetDirectedLink(uuid1, uuid2)
        BTreeSets::destroy(Bosons2::pathToDataStore(), uuid1, uuid2)
    end

    # Bosons2::unlink(object1, object2)
    def self.unlink(object1, object2)
        Bosons2::unsetDirectedLink(object1["uuid"], object2["uuid"])
        Bosons2::unsetDirectedLink(object2["uuid"], object1["uuid"])
    end

end
