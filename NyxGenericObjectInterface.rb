
# encoding: UTF-8

# require_relative "NyxGenericObjectInterface.rb"

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

require_relative "Cubes.rb"
require_relative "Quarks.rb"
require_relative "Cliques.rb"
require_relative "QuarkTags.rb"
require_relative "Bosons.rb"

# -----------------------------------------------------------------

class NyxGenericObjectInterface

    # NyxGenericObjectInterface::objectToString(object)
    def self.objectToString(object)
        if object["nyxNxSet"] == "34F19BF8-0B21-4B9F-9E33-F56E897810C9" then
            return object["description"]
        end
        if object["nyxNxSet"] == "4ebd0da9-6fe4-442e-81b9-eda8343fc1e5" then
            return Cliques::cliqueToString(object)
        end
        if object["nyxNxSet"] == "a00b82aa-c047-4497-82bf-16c7206913e4" then
            return QuarkTags::tagToString(object)
        end
        if object["nyxNxSet"] == "6b240037-8f5f-4f52-841d-12106658171f" then
            return Quarks::quarkToString(object)
        end
        puts object
        raise "Error: 056686f0"
    end

    # NyxGenericObjectInterface::objectDive(object)
    def self.objectDive(object)
        if object["nyxNxSet"] == "34F19BF8-0B21-4B9F-9E33-F56E897810C9" then
            Cubes::diveCube(object)
            return
        end
        if object["nyxNxSet"] == "4ebd0da9-6fe4-442e-81b9-eda8343fc1e5" then
            Cliques::cliqueDive(object)
            return
        end
        if object["nyxNxSet"] == "a00b82aa-c047-4497-82bf-16c7206913e4" then
            QuarkTags::tagDive(tag)
            return
        end
        if object["nyxNxSet"] == "6b240037-8f5f-4f52-841d-12106658171f" then
            Quarks::quarkDive(object)
            return
        end
        puts object
        raise "Error: cf25ea33"
    end

    # NyxGenericObjectInterface::objectLastActivityUnixtime(object)
    def self.objectLastActivityUnixtime(object)
        if object["nyxNxSet"] == "cube-933c2260-92d1-4578-9aaf-cd6557c664c6" then
            return object["quarks"].map{|quark| quark["creationUnixtime"] }.max
        end
        if object["nyxNxSet"] == "4ebd0da9-6fe4-442e-81b9-eda8343fc1e5" then
            return Cliques::getLastActivityUnixtime(object)
        end
        if object["nyxNxSet"] == "a00b82aa-c047-4497-82bf-16c7206913e4" then
            return object["creationUnixtime"]
        end
        if object["nyxNxSet"] == "6b240037-8f5f-4f52-841d-12106658171f" then
            return object["creationUnixtime"]
        end
        puts object
        raise "Error: d66bdffa"
    end

    # NyxGenericObjectInterface::applyQuarkToCubeUpgradeIfRelevant(object)
    def self.applyQuarkToCubeUpgradeIfRelevant(object)
        if object["nyxNxSet"] == "6b240037-8f5f-4f52-841d-12106658171f" then
            object = Cubes::upgradeQuarkToCubeIfRelevant(object)
        end
        object
    end
end
