
# encoding: UTF-8

# require "/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/Nyx/Gluons.rb"

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

class Gluons

    # Gluons::issueLink(object1, object2)
    def self.issueLink(object1, object2)
        raise "94b0523e" if (object1["uuid"] == object2["uuid"]) # Prevent an object to link to itself
        raise "d3e06d2f" if (object1["nyxType"] != "quark-6af2c9d7-67b5-4d16-8913-c5980b0453f2" or object2["nyxType"] != "quark-6af2c9d7-67b5-4d16-8913-c5980b0453f2")

        link = Gluons::linked?(object1, object2)
        return link if link

        # Any quark linked to object1 is linked to object2
        Gluons::getLinkedQuarks(object1).each{|q|
            l = {
                "uuid"             => SecureRandom.uuid,
                "nyxType"          => "gluon-f3b14b34-cccc-442e-a7e9-f73fb37bc597",
                "creationUnixtime" => Time.new.to_f,
                "uuid1"            => q["uuid"],
                "uuid2"            => object2["uuid"]
            }
            NyxIO::commitToDisk(l)
        }

        # Any quark linked to object2 is linked to object1
        Gluons::getLinkedQuarks(object2).each{|q|
            l = {
                "uuid"             => SecureRandom.uuid,
                "nyxType"          => "gluon-f3b14b34-cccc-442e-a7e9-f73fb37bc597",
                "creationUnixtime" => Time.new.to_f,
                "uuid1"            => object1["uuid"],
                "uuid2"            => q["uuid"]
            }
            NyxIO::commitToDisk(l)
        }

        link = {
            "uuid"             => SecureRandom.uuid,
            "nyxType"          => "gluon-f3b14b34-cccc-442e-a7e9-f73fb37bc597",
            "creationUnixtime" => Time.new.to_f,
            "uuid1"            => object1["uuid"],
            "uuid2"            => object2["uuid"]
        }
        NyxIO::commitToDisk(link)

        link
    end

    # Gluons::linked?(object1, object2)
    def self.linked?(object1, object2)
        Gluons::links()
            .select{|link|
                b1 = (link["uuid1"] == object1["uuid"] and link["uuid2"] == object2["uuid"])
                b2 = (link["uuid1"] == object2["uuid"] and link["uuid2"] == object1["uuid"])
                b1 or b2
            }
            .first
    end

    # Gluons::linkToString(link)
    def self.linkToString(link)
        "[gluon] #{link["uuid1"]} <-> #{link["uuid2"]}"
    end

    # Gluons::getLinkedQuarks(focus)
    def self.getLinkedQuarks(focus)
        obj1s = NyxIO::objects("gluon-f3b14b34-cccc-442e-a7e9-f73fb37bc597")
                    .select{|link| link["uuid1"] == focus["uuid"] }
                    .map{|link| NyxDataCarriers::getObjectOrNull(link["uuid2"]) }
                    .compact
        obj2s = NyxIO::objects("gluon-f3b14b34-cccc-442e-a7e9-f73fb37bc597")
                    .select{|link| link["uuid2"] == focus["uuid"] }
                    .map{|link| NyxDataCarriers::getObjectOrNull(link["uuid1"]) }
                    .compact
        obj1s + obj2s
    end

    # Gluons::links()
    def self.links()
        NyxIO::objects("gluon-f3b14b34-cccc-442e-a7e9-f73fb37bc597")
            .sort{|n1, n2| n1["creationUnixtime"] <=> n2["creationUnixtime"] }
    end

    # Gluons::unlink(object1, object2)
    def self.unlink(object1, object2)
        trace = [object1["uuid"], object2["uuid"]].sort.join(":")
        Gluons::links()
            .select{|link| 
                xtrace = [link["uuid1"], link["uuid2"]].sort.join(":")
                xtrace == trace
            }
            .each{|link|
                if LucilleCore::askQuestionAnswerAsBoolean("Destroy '#{link}' ?") then
                    NyxIO::destroy(link["uuid"])
                end
            }
    end
end
