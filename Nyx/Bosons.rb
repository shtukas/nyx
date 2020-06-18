
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

# -----------------------------------------------------------------

class Bosons

    # Bosons::issueLink(object1, object2)
    def self.issueLink(object1, object2)
        raise "b9b7810e" if !NyxIO::dataCarriersNyxTypes().include?(object1["nyxType"])
        raise "ff00b177" if !NyxIO::dataCarriersNyxTypes().include?(object2["nyxType"])
        raise "14d9af33" if (object1["uuid"] == object2["uuid"]) # Prevent an object to link to itself

        # We now enforce the meaning of Boson and prevent the linking of two quarks
        raise "d3e06d2f" if (object1["nyxType"] == "quark-6af2c9d7-67b5-4d16-8913-c5980b0453f2" and object2["nyxType"] == "quark-6af2c9d7-67b5-4d16-8913-c5980b0453f2")


        link = Bosons::linked?(object1, object2)
        return link if link

        link = {
            "uuid"             => SecureRandom.uuid,
            "nyxType"          => "boson-b38137c1-fd43-4035-9f2c-af0fddb18c80",
            "creationUnixtime" => Time.new.to_f,
            "uuid1"            => object1["uuid"],
            "uuid2"            => object2["uuid"]
        }
        NyxIO::commitToDisk(link)

        Bosons::recacheLinkedObjectsFromTheForce(object1)
        Bosons::recacheLinkedObjectsFromTheForce(object2)

        link
    end

    # Bosons::linked?(object1, object2)
    def self.linked?(object1, object2)
        Bosons::links()
            .select{|link|
                b1 = (link["uuid1"] == object1["uuid"] and link["uuid2"] == object2["uuid"])
                b2 = (link["uuid1"] == object2["uuid"] and link["uuid2"] == object1["uuid"])
                b1 or b2
            }
            .first
    end

    # Bosons::linkToString(link)
    def self.linkToString(link)
        "[link] #{link["uuid1"]} <-> #{link["uuid2"]}"
    end

    # Bosons::getLinkedObjectUseTheForce(focus)
    def self.getLinkedObjectUseTheForce(focus)
        # Use the Force
        obj1s = NyxIO::objects("boson-b38137c1-fd43-4035-9f2c-af0fddb18c80")
                    .select{|link| link["uuid1"] == focus["uuid"] }
                    .map{|link| NyxDataCarriers::getObjectOrNull(link["uuid2"]) }
                    .compact
        obj2s = NyxIO::objects("boson-b38137c1-fd43-4035-9f2c-af0fddb18c80")
                    .select{|link| link["uuid2"] == focus["uuid"] }
                    .map{|link| NyxDataCarriers::getObjectOrNull(link["uuid1"]) }
                    .compact
        objects = obj1s + obj2s
        objects
    end

    # Bosons::recacheLinkedObjectsFromTheForce(focus)
    def self.recacheLinkedObjectsFromTheForce(focus)
        derivationFolderpath = "/Users/pascal/Galaxy/DataBank/Catalyst/Nxy-Repository/cache/derivation-bosons-0DBD30F5-887D-4258-8E4F-6343B9214206"
        cacheKey = "df982ac4-544f-4df8-b7e8-f48bbde09ed8:#{focus["uuid"]}"
        objects = Bosons::getLinkedObjectUseTheForce(focus)
        objectsuuids = objects.map{|object| object["uuid"] }
        KeyValueStore::set(derivationFolderpath, cacheKey, JSON.generate(objectsuuids))
    end

    # Bosons::getLinkedObjects(focus)
    def self.getLinkedObjects(focus)
        derivationFolderpath = "/Users/pascal/Galaxy/DataBank/Catalyst/Nxy-Repository/cache/derivation-bosons-0DBD30F5-887D-4258-8E4F-6343B9214206"
        cacheKey = "df982ac4-544f-4df8-b7e8-f48bbde09ed8:#{focus["uuid"]}"

        # Querying the cache
        objectsuuids = KeyValueStore::getOrNull(derivationFolderpath, cacheKey)
        if objectsuuids then
            objectsuuids = JSON.parse(objectsuuids)
            return objectsuuids.map{|uuid| NyxDataCarriers::getObjectOrNull(uuid) }.compact
        end

        objects = Bosons::getLinkedObjectUseTheForce(focus)

        # Setting the cache
        Bosons::recacheLinkedObjectsFromTheForce(focus)

        objects
    end

    # Bosons::getLinkedObjectsOfGivenNyxType(focus, nyxType)
    def self.getLinkedObjectsOfGivenNyxType(focus, nyxType)
        Bosons::getLinkedObjects(focus)
            .select{|object| object["nyxType"] == nyxType }
    end

    # Bosons::links()
    def self.links()
        NyxIO::objects("boson-b38137c1-fd43-4035-9f2c-af0fddb18c80")
            .sort{|n1, n2| n1["creationUnixtime"] <=> n2["creationUnixtime"] }
    end

    # Bosons::unlink(object1, object2)
    def self.unlink(object1, object2)
        trace = [object1["uuid"], object2["uuid"]].sort.join(":")
        Bosons::links()
            .select{|link| 
                xtrace = [link["uuid1"], link["uuid2"]].sort.join(":")
                xtrace == trace
            }
            .each{|link|
                NyxIO::destroy(link["uuid"])
            }
    end
end
