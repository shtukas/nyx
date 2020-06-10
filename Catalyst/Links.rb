# encoding: UTF-8

# require "/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/Catalyst/Cliques.rb"

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

require "/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/Catalyst/KnowledgeObjects.rb"

require "/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/Catalyst/Nyx.rb"

# -----------------------------------------------------------------

class Links

    # Links::issue(object1, object2)
    def self.issue(object1, object2)
        raise "6df08321" if [object1, object2].any?{|object| !["cube-933c2260-92d1-4578-9aaf-cd6557c664c6", "clique-8826cbad-e54e-4e78-bf7d-28c9c5019721"].include?(object["nyxType"]) }
        link = {
            "nyxType"          => "link-b38137c1-fd43-4035-9f2c-af0fddb18c80",
            "creationUnixtime" => Time.new.to_f,
            "uuid"             => SecureRandom.uuid,
            "uuid1"            => object1["uuid"],
            "uuid2"            => object2["uuid"]
        }
        Nyx::commitToDisk(link)
        link
    end

    # Links::linkToString(link)
    def self.linkToString(link)
        "[link] #{link["uuid1"]} <-> #{link["uuid2"]}"
    end

    # Links::getLinkedObjects(object)
    def self.getLinkedObjects(object)
        obj1s = Nyx::objects("link-b38137c1-fd43-4035-9f2c-af0fddb18c80")
                    .select{|link| link["uuid1"] == object["uuid"] }
                    .map{|link| KnowledgeObjects::getObjectOrNull(link["uuid2"]) }
                    .compact
        obj2s = Nyx::objects("link-b38137c1-fd43-4035-9f2c-af0fddb18c80")
                    .select{|link| link["uuid2"] == object["uuid"] }
                    .map{|link| KnowledgeObjects::getObjectOrNull(link["uuid1"]) }
                    .compact
        obj1s + obj2s
    end

    # Links::links()
    def self.links()
        Nyx::objects("link-b38137c1-fd43-4035-9f2c-af0fddb18c80")
            .sort{|n1, n2| n1["creationUnixtime"] <=> n2["creationUnixtime"] }
    end
end

