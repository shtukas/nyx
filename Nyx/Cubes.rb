
# encoding: UTF-8

# require "/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/Nyx/Cubes.rb"

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

require "/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/Nyx/Quarks.rb"
require "/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/Nyx/Cliques.rb"
require "/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/Nyx/Bosons.rb"
require "/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/Nyx/NyxGenericObjectInterface.rb"
require "/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/Nyx/NyxRoles.rb"

# -----------------------------------------------------------------

class Cubes
    # Cubes::upgradeQuarkToCubeIfRelevant(quark)
    def self.upgradeQuarkToCubeIfRelevant(quark)
        objects = Bosons::getLinkedObjectsOfGivenNyxNxSet(quark, "6b240037-8f5f-4f52-841d-12106658171f")
        return quark if objects.empty?
        quarks = [quark] + objects
        {
            "nyxNxSet"    => "34F19BF8-0B21-4B9F-9E33-F56E897810C9",
            "description" => "[cube] #{Quarks::quarkToString(quark)}",
            "quarks"      => quarks
        }
    end

    # Cubes::diveCube(cube)
    def self.diveCube(cube)
        loop {
            ms = LCoreMenuItemsNX1.new()
            items = cube["quarks"].map{|quark|
                ms.item(
                    NyxGenericObjectInterface::objectToString(quark), 
                    lambda { NyxGenericObjectInterface::objectDive(quark) } 
                )
            }
            status = ms.prompt()
            break if !status
        }
    end

end
