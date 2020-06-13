
# encoding: UTF-8

# require "/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/Nyx/NyxRoles.rb"

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

require "/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/Waves/Waves.rb"
require "/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/Asteroids/Asteroids.rb"
require "/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/Spaceships/Spaceships.rb"
require "/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/OpenCycles/OpenCycles.rb"

# -----------------------------------------------------------------

class NyxRoles

    # NyxRoles::getObjectOrNull(uuid)
    def self.getObjectOrNull(uuid)
        objects = NyxIO::rolesNyxTypes()
                    .map{|nyxtype| NyxIO::getOrNullAtType(uuid, nyxtype) }
                    .compact
        raise "e9b4533c-d2d6-4f87-8120-9ed6942777d0" if objects.size >= 2
        objects.first
    end

    # NyxRoles::objectToString(object)
    def self.objectToString(object)
        if object["nyxType"] == "wave-12ed27da-b5e4-4e6e-940f-2c84071cca58" then
            return Waves::waveToString(object)
        end
        if object["nyxType"] == "asteroid-cc6d8717-98cf-4a7c-b14d-2261f0955b37" then
            return Asteroids::asteroidToString(object)
        end
        if object["nyxType"] == "spaceship-99a06996-dcad-49f5-a0ce-02365629e4fc" then
            return Spaceships::spaceshipToString(object)
        end
        if object["nyxType"] == "open-cycle-9fa96e3c-d140-4f82-a7f0-581c918e9e6f" then
            return OpenCycles::opencycleToString(object)
        end
        puts object
        raise "Error: 056686f0"
    end

    # NyxRoles::objectDive(object)
    def self.objectDive(object)
        if object["nyxType"] == "wave-12ed27da-b5e4-4e6e-940f-2c84071cca58" then
            puts "There isn't currently a dive function for Waves"
            return
        end
        if object["nyxType"] == "asteroid-cc6d8717-98cf-4a7c-b14d-2261f0955b37" then
            Asteroids::asteroidDive(object)
            return
        end
        if object["nyxType"] == "spaceship-99a06996-dcad-49f5-a0ce-02365629e4fc" then
            Spaceships::spaceshipDive(object)
            return
        end
        if object["nyxType"] == "open-cycle-9fa96e3c-d140-4f82-a7f0-581c918e9e6f" then
            OpenCycles::opencycleDive(object)
            return
        end
        puts object
        raise "Error: cf25ea33"
    end

    # NyxRoles::getRolesForTarget(targetuuid)
    def self.getRolesForTarget(targetuuid)
        [
            # We are not doing the Waves as they have no target
            Asteroids::getAsteroidsByTargetUUID(targetuuid),
            Spaceships::getSpaceshipsByTargetUUID(targetuuid),
            OpenCycles::getOpenCyclesByTargetUUID(targetuuid)
        ].flatten
    end
end
