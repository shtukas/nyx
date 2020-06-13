
# encoding: UTF-8

# require "/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/Nyx/Links.rb"

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

class Links

    # Links::issueLink(object1, object2)
    def self.issueLink(object1, object2)
        raise "b9b7810e" if !NyxIO::dataNetworkNyxTypes().include?(object1["nyxType"])
        raise "ff00b177" if !NyxIO::dataNetworkNyxTypes().include?(object2["nyxType"])
        raise "14d9af33" if (object1["uuid"] == object2["uuid"]) # Prevent an object to link to itself
        link = {
            "uuid"             => SecureRandom.uuid,
            "nyxType"          => "link-b38137c1-fd43-4035-9f2c-af0fddb18c80",
            "creationUnixtime" => Time.new.to_f,
            "uuid1"            => object1["uuid"],
            "uuid2"            => object2["uuid"]
        }
        NyxIO::commitToDisk(link)
        link
    end

    # Links::linkToString(link)
    def self.linkToString(link)
        "[link] #{link["uuid1"]} <-> #{link["uuid2"]}"
    end

    # Links::getLinkedObjects(focus)
    def self.getLinkedObjects(focus)
        obj1s = NyxIO::objects("link-b38137c1-fd43-4035-9f2c-af0fddb18c80")
                    .select{|link| link["uuid1"] == focus["uuid"] }
                    .map{|link| NyxDataCarriers::getObjectOrNull(link["uuid2"]) }
                    .compact
        obj2s = NyxIO::objects("link-b38137c1-fd43-4035-9f2c-af0fddb18c80")
                    .select{|link| link["uuid2"] == focus["uuid"] }
                    .map{|link| NyxDataCarriers::getObjectOrNull(link["uuid1"]) }
                    .compact
        obj1s + obj2s
    end

    # Links::getLinkedObjectsOfGivenNyxType(focus, nyxType)
    def self.getLinkedObjectsOfGivenNyxType(focus, nyxType)
        Links::getLinkedObjects(focus)
            .select{|object| object["nyxType"] == nyxType }
    end

    # Links::links()
    def self.links()
        NyxIO::objects("link-b38137c1-fd43-4035-9f2c-af0fddb18c80")
            .sort{|n1, n2| n1["creationUnixtime"] <=> n2["creationUnixtime"] }
    end

    # Links::destroyLink(object1, object2)
    def self.destroyLink(object1, object2)
        trace = [object1["uuid"], object2["uuid"]].sort.join(":")
        Links::links()
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
