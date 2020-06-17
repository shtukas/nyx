
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
require "/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/Nyx/NyxDataCarriers.rb"
require "/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/Nyx/NyxIO.rb"
require "/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/Nyx/NyxRoles.rb"
require "/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/Nyx/Gluons.rb"

require "/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/OpenCycles/OpenCycles.rb"

# -----------------------------------------------------------------

class Cubes
    # Cubes::upgradeQuarkToCubeIfRelevant(quark)
    def self.upgradeQuarkToCubeIfRelevant(quark)
        return quark if Gluons::getLinkedQuarks(quark).empty?
        quarks = [quark] + Gluons::getLinkedQuarks(quark)
        {
            "nyxType"     => "cube-933c2260-92d1-4578-9aaf-cd6557c664c6",
            "description" => "[cube] (#{quarks.size}) #{Quarks::quarkToString(quark)}",
            "quarks"      => quarks
        }
    end

    # Cubes::diveCube(cube)
    def self.diveCube(cube)
        loop {
            items = cube["quarks"].map{|quark|
                [ NyxDataCarriers::objectToString(quark), lambda { NyxDataCarriers::objectDive(quark) } ]
            }
            status = LucilleCore::menuItemsWithLambdas(items) # Boolean # Indicates whether an item was chosen
            break if !status
        }
    end

end
