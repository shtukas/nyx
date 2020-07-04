
# encoding: UTF-8

# require_relative "NyxRoles.rb"

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

require_relative "Waves.rb"
require_relative "Asteroids.rb"

# -----------------------------------------------------------------

class NyxRoles

    # NyxRoles::objectToString(object)
    def self.objectToString(object)
        if object["nyxNxSet"] == "7deb0315-98b5-4e4d-9ad2-d83c2f62e6d4" then
            return Waves::waveToString(object)
        end
        if object["nyxNxSet"] == "b66318f4-2662-4621-a991-a6b966fb4398" then
            return Asteroids::asteroidToString(object)
        end
        puts object
        raise "Error: 056686f0"
    end

    # NyxRoles::objectDive(object)
    def self.objectDive(object)
        if object["nyxNxSet"] == "7deb0315-98b5-4e4d-9ad2-d83c2f62e6d4" then
            puts "There isn't currently a dive function for Waves"
            return
        end
        if object["nyxNxSet"] == "b66318f4-2662-4621-a991-a6b966fb4398" then
            Asteroids::asteroidDive(object)
            return
        end
        puts object
        raise "Error: cf25ea33"
    end

    # NyxRoles::getRolesForTarget(targetuuid)
    def self.getRolesForTarget(targetuuid)
        [
            # We are not doing the Waves as they have no target
            Asteroids::getAsteroidsTypeQuarkByQuarkUUID(targetuuid)
        ].flatten
    end
end
