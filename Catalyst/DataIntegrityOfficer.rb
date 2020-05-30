# encoding: UTF-8

# require "/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/Catalyst/DataIntegrityOfficer.rb"

# This variable contains the objects of the current display.
# We use it to speed up display after some operations

require 'digest/sha1'
# Digest::SHA1.hexdigest 'foo'
# Digest::SHA1.file(myFile).hexdigest

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

require "/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/Catalyst/A10495.rb"
require "/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/Catalyst/Cliques.rb"
require "/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/Catalyst/GlobalNavigationNetwork.rb"

# ------------------------------------------------------------------------

class DataIntegrityOfficer

    # DataIntegrityOfficer::survey()
    def self.survey()

        # Ensure that each node not the root has a parent
        GlobalNavigationNetworkNodes::nodes()
            .each{|node|
                next if node["uuid"] == "3b5b7dbe-442b-4b5b-b681-f61ab598fd63" # root node
                next if !GlobalNavigationNetworkPaths::getParents(node).empty?
                loop {
                    puts "[DataIntegrityOfficer] Global Navigation Network Node '#{node["name"]}' doesn't have a parent, please make and/or select one"
                    puts JSON.pretty_generate(node)
                    parent = GlobalNavigationNetworkMakeAndOrSelectNodeQuest::makeAndOrSelectNodeOrNull()
                    next if parent.nil?
                    next if node["uuid"] == parent["uuid"]
                    object = GlobalNavigationNetworkPaths::issuePathFromFirstNodeToSecondNodeOrNull(parent, node)
                    next if object.nil?
                    puts JSON.pretty_generate(object)
                    break
                }
            }

        # Make sure that every Clique is on a node
    end
end


