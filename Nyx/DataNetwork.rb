
# encoding: UTF-8

# require "/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/Nyx/DataNetwork.rb"

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

require "/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/Nyx/Quark.rb"

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

class DataNetworkCoreFunctions

    # DataNetworkCoreFunctions::pathToRepository()
    def self.pathToRepository()
        "/Users/pascal/Galaxy/DataBank/Catalyst/Nxy-Repository/objects"
    end

    # DataNetworkCoreFunctions::getOrNullAtType(uuid, nyxtype)
    def self.getOrNullAtType(uuid, nyxtype)
        filepath = "#{DataNetworkCoreFunctions::pathToRepository()}/#{nyxtype}/#{uuid}.json"
        return nil if !File.exists?(filepath)
        JSON.parse(IO.read(filepath))
    end

    # DataNetworkCoreFunctions::getDataNetworkTypes()
    def self.getDataNetworkTypes()
        Dir.entries(DataNetworkCoreFunctions::pathToRepository())
            .select{|filename| filename[0, 1] != "." }
    end

    # DataNetworkCoreFunctions::destroyAtType(uuid, nyxtype)
    def self.destroyAtType(uuid, nyxtype)
        filepath = "#{DataNetworkCoreFunctions::pathToRepository()}/#{nyxtype}/#{uuid}.json"
        return if !File.exists?(filepath)
        FileUtils.rm(filepath)
    end

    # -----------------------------------------------------------------------------------

    # DataNetworkCoreFunctions::objects(nyxtype)
    def self.objects(nyxtype)
        folderpath = "#{DataNetworkCoreFunctions::pathToRepository()}/#{nyxtype}"
        Dir.entries(folderpath)
            .select{|filename| filename[-5, 5] == ".json" }
            .map{|filename| "#{folderpath}/#{filename}" }
            .map{|filepath| JSON.parse(IO.read(filepath)) }
            .sort{|i1, i2| i1["creationUnixtime"] <=> i2["creationUnixtime"] }
    end

    # DataNetworkCoreFunctions::getOrNull(uuid)
    def self.getOrNull(uuid)
        DataNetworkCoreFunctions::getDataNetworkTypes()
            .map{|nyxtype| DataNetworkCoreFunctions::getOrNullAtType(uuid, nyxtype) }
            .compact
            .first
    end

    # DataNetworkCoreFunctions::commitToDisk(object)
    def self.commitToDisk(object)
        raise "[02986280]" if object["nyxType"].nil?
        raise "[222C74D4]" if object["uuid"].nil?
        filepath = "#{DataNetworkCoreFunctions::pathToRepository()}/#{object["nyxType"]}/#{object["uuid"]}.json"
        if !File.exists?(File.dirname(filepath)) then
            FileUtils.mkdir(File.dirname(filepath))
        end
        File.open(filepath, "w") {|f| f.puts(JSON.pretty_generate(object)) }
    end

    # DataNetworkCoreFunctions::destroy(uuid)
    def self.destroy(uuid)
        DataNetworkCoreFunctions::getDataNetworkTypes()
            .map{|nyxtype| DataNetworkCoreFunctions::destroyAtType(uuid, nyxtype) }
    end

    # -----------------------------------------------------------------------------------

    # DataNetworkCoreFunctions::dataNetworkNyxTypes()
    def self.dataNetworkNyxTypes()
        [
            "quark-6af2c9d7-67b5-4d16-8913-c5980b0453f2",
            "cube-933c2260-92d1-4578-9aaf-cd6557c664c6",
            "clique-8826cbad-e54e-4e78-bf7d-28c9c5019721",
            "tag-57c7eced-24a8-466d-a6fe-588142afd53b"
        ]
    end

end

class DataNetworkDataObjects

    # DataNetworkDataObjects::getObjectOrNull(uuid)
    def self.getObjectOrNull(uuid)
        objects = DataNetworkCoreFunctions::dataNetworkNyxTypes()
                    .map{|nyxtype|
                        DataNetworkCoreFunctions::getOrNullAtType(uuid, nyxtype)
                    }
                    .compact
        raise "7577a7d3-2dfa-40d4-a6a3-3885eaa54631" if objects.size >= 2
        objects.first
    end

    # DataNetworkDataObjects::objectToString(object)
    def self.objectToString(object)
        if object["nyxType"] == "cube-933c2260-92d1-4578-9aaf-cd6557c664c6"  then
            return Cubes::cubeToString(object)
        end
        if object["nyxType"] == "clique-8826cbad-e54e-4e78-bf7d-28c9c5019721"  then
            return Cliques::cliqueToString(object)
        end
        raise "Error: 056686f0"
    end

    # DataNetworkDataObjects::openObject(object)
    def self.openObject(object)
        if object["nyxType"] == "cube-933c2260-92d1-4578-9aaf-cd6557c664c6"  then
            cube = object
            Cubes::openCube(cube)
            return
        end
        if object["nyxType"] == "clique-8826cbad-e54e-4e78-bf7d-28c9c5019721"  then
           clique = object
           Cliques::cliqueDive(clique)
           return
        end
        raise "Error: 2f28f27d"
    end

    # DataNetworkDataObjects::objectDive(object)
    def self.objectDive(object)
        if object["nyxType"] == "cube-933c2260-92d1-4578-9aaf-cd6557c664c6"  then
            Cubes::cubeDive(object)
            return
        end
        if object["nyxType"] == "clique-8826cbad-e54e-4e78-bf7d-28c9c5019721"  then
            Cliques::cliqueDive(object)
            return
        end
        raise "Error: cf25ea33"
    end

    # DataNetworkDataObjects::objectLastActivityUnixtime(object)
    def self.objectLastActivityUnixtime(object)
        if object["nyxType"] == "cube-933c2260-92d1-4578-9aaf-cd6557c664c6"  then
            Cubes::getLastActivityUnixtime(object)
            return
        end
        if object["nyxType"] == "clique-8826cbad-e54e-4e78-bf7d-28c9c5019721"  then
            Cliques::getLastActivityUnixtime(object)
            return
        end
        raise "Error: d66bdffa"
    end
end

class Links

    # Links::issue(object1, object2)
    def self.issue(object1, object2)
        raise "b9b7810e" if !DataNetworkCoreFunctions::dataNetworkNyxTypes().include?(object1["nyxType"])
        raise "ff00b177" if !DataNetworkCoreFunctions::dataNetworkNyxTypes().include?(object2["nyxType"])
        raise "14d9af33" if (object1["uuid"] == object2["uuid"]) # Prevent an object to link to itself
        link = {
            "nyxType"          => "link-b38137c1-fd43-4035-9f2c-af0fddb18c80",
            "creationUnixtime" => Time.new.to_f,
            "uuid"             => SecureRandom.uuid,
            "uuid1"            => object1["uuid"],
            "uuid2"            => object2["uuid"]
        }
        DataNetworkCoreFunctions::commitToDisk(link)
        link
    end

    # Links::linkToString(link)
    def self.linkToString(link)
        "[link] #{link["uuid1"]} <-> #{link["uuid2"]}"
    end

    # Links::getLinkedObjects(object)
    def self.getLinkedObjects(object)
        obj1s = DataNetworkCoreFunctions::objects("link-b38137c1-fd43-4035-9f2c-af0fddb18c80")
                    .select{|link| link["uuid1"] == object["uuid"] }
                    .map{|link| DataNetworkDataObjects::getObjectOrNull(link["uuid2"]) }
                    .compact
        obj2s = DataNetworkCoreFunctions::objects("link-b38137c1-fd43-4035-9f2c-af0fddb18c80")
                    .select{|link| link["uuid2"] == object["uuid"] }
                    .map{|link| DataNetworkDataObjects::getObjectOrNull(link["uuid1"]) }
                    .compact
        obj1s + obj2s
    end

    # Links::links()
    def self.links()
        DataNetworkCoreFunctions::objects("link-b38137c1-fd43-4035-9f2c-af0fddb18c80")
            .sort{|n1, n2| n1["creationUnixtime"] <=> n2["creationUnixtime"] }
    end
end
