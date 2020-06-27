
# encoding: UTF-8

# require "/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/Nyx/NyxDataCarriers.rb"

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

require "/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/Nyx/Cubes.rb"
require "/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/Nyx/Quarks.rb"
require "/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/Nyx/Cliques.rb"
require "/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/Nyx/Tags.rb"
require "/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/Nyx/Bosons.rb"

# -----------------------------------------------------------------

class NyxDataCarriers

    # NyxDataCarriers::getObjectOrNull(uuid)
    def self.getObjectOrNull(uuid)
        objects = NyxIO::dataCarriersNyxTypes()
                    .map{|nyxtype|
                        NyxIO::getOrNullAtType(uuid, nyxtype)
                    }
                    .compact
        raise "7577a7d3-2dfa-40d4-a6a3-3885eaa54631" if objects.size >= 2
        objects.first
    end

    # NyxDataCarriers::objectToString(object)
    def self.objectToString(object)
        if object["nyxType"] == "cube-933c2260-92d1-4578-9aaf-cd6557c664c6"  then
            return object["description"]
        end
        if object["nyxType"] == "clique-8826cbad-e54e-4e78-bf7d-28c9c5019721" then
            return Cliques::cliqueToString(object)
        end
        if object["nyxType"] == "tag-57c7eced-24a8-466d-a6fe-588142afd53b" then
            return Tags::tagToString(object)
        end
        if object["nyxType"] == "quark-6af2c9d7-67b5-4d16-8913-c5980b0453f2" then
            return Quarks::quarkToString(object)
        end
        puts object
        raise "Error: 056686f0"
    end

    # NyxDataCarriers::objectDive(object)
    def self.objectDive(object)
        if object["nyxType"] == "cube-933c2260-92d1-4578-9aaf-cd6557c664c6"  then
            Cubes::diveCube(object)
            return
        end
        if object["nyxType"] == "clique-8826cbad-e54e-4e78-bf7d-28c9c5019721"  then
            Cliques::cliqueDive(object)
            return
        end
        if object["nyxType"] == "tag-57c7eced-24a8-466d-a6fe-588142afd53b" then
            Tags::tagDive(tag)
            return
        end
        if object["nyxType"] == "quark-6af2c9d7-67b5-4d16-8913-c5980b0453f2" then
            Quarks::quarkDive(object)
            return
        end
        puts object
        raise "Error: cf25ea33"
    end

    # NyxDataCarriers::objectLastActivityUnixtime(object)
    def self.objectLastActivityUnixtime(object)
        if object["nyxType"] == "cube-933c2260-92d1-4578-9aaf-cd6557c664c6"  then
            return object["quarks"].map{|quark| quark["creationUnixtime"] }.max
        end
        if object["nyxType"] == "clique-8826cbad-e54e-4e78-bf7d-28c9c5019721"  then
            return Cliques::getLastActivityUnixtime(object)
        end
        if object["nyxType"] == "tag-57c7eced-24a8-466d-a6fe-588142afd53b" then
            return object["creationUnixtime"]
        end
        if object["nyxType"] == "quark-6af2c9d7-67b5-4d16-8913-c5980b0453f2" then
            return object["creationUnixtime"]
        end
        puts object
        raise "Error: d66bdffa"
    end

    # NyxDataCarriers::applyQuarkToCubeUpgradeIfRelevant(object)
    def self.applyQuarkToCubeUpgradeIfRelevant(object)
        if object["nyxType"] == "quark-6af2c9d7-67b5-4d16-8913-c5980b0453f2" then
            object = Cubes::upgradeQuarkToCubeIfRelevant(object)
        end
        object
    end
end
