
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

require 'digest/sha1'
# Digest::SHA1.hexdigest 'foo'
# Digest::SHA1.file(myFile).hexdigest

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


class Bosons

    # Bosons::link(object1, object2)
    def self.link(object1, object2)
        link = {
            "uuid"      => SecureRandom.uuid,
            "nyxNxSet"  => "13f3499d-fa9c-44bb-91d3-8a3ccffecefb",
            "uuid1"     => object1["uuid"],
            "uuid2"     => object2["uuid"]
        }
        NyxSets::putObject(link)
        link
    end

    # Bosons::getLinks()
    def self.getLinks()
        NyxSets::objects("13f3499d-fa9c-44bb-91d3-8a3ccffecefb")
    end

    # Bosons::linked?(object1, object2)
    def self.linked?(object1, object2)
        Bosons::getLinks()
            .any?{|link| 
                b1 = ((link["uuid1"] == object1["uuid"]) and (link["uuid2"] == object2["uuid"]))
                b2 = ((link["uuid1"] == object2["uuid"]) and (link["uuid2"] == object1["uuid"]))
                b1 or b2
            }
    end

    # Bosons::getLinkedObjects(object)
    def self.getLinkedObjects(object)
        objects1 = Bosons::getLinks()
                    .select{|link| link["uuid1"] == object["uuid"] }
                    .map{|link| NyxSets::getObjectOrNull(link["uuid2"]) }
                    .compact

        objects2 = Bosons::getLinks()
                    .select{|link| link["uuid2"] == object["uuid"] }
                    .map{|link| NyxSets::getObjectOrNull(link["uuid1"]) }
                    .compact

        objects1 + objects2
    end

    # Bosons::getLinkedObjectsOfGivenNyxNxSet(focus, setid)
    def self.getLinkedObjectsOfGivenNyxNxSet(focus, setid)
        Bosons::getLinkedObjects(focus)
            .select{|object| object["nyxNxSet"] == setid }
    end

    # Bosons::unlink(object1, object2)
    def self.unlink(object1, object2)
        Bosons::getLinks()
            .select{|link| 
                b1 = ((link["uuid1"] == object1["uuid"]) and (link["uuid2"] == object2["uuid"]))
                b2 = ((link["uuid1"] == object2["uuid"]) and (link["uuid2"] == object1["uuid"]))
                b1 or b2
            }
            .each{|link|
                NyxSets::destroyObject(link["uuid"])
            }
    end

end
