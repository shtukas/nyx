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

require "/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/Catalyst/DataPoint.rb"
require "/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/Catalyst/Cliques.rb"
require "/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/Catalyst/Starlight.rb"

# ------------------------------------------------------------------------

class DataIntegrityOfficer

    # DataIntegrityOfficer::startSurvey()
    def self.startSurvey()
        # Ensure that each node not the root has a parent
        Nyx::objects("starlight-node-8826cbad-e54e-4e78-bf7d-28c9c5019721")
            .each{|node|
                next if node["uuid"] == "3b5b7dbe-442b-4b5b-b681-f61ab598fd63" # root node
                next if !StarlightPaths::getParents(node).empty?
                puts "[DataIntegrityOfficer] Starlight Node '#{node["name"]}' doesn't have a parent, please make and/or select one".green
                puts JSON.pretty_generate(node)
                parent = StarlightMakeAndOrSelectNodeQuest::makeAndOrSelectNodeOrNull()
                next if parent.nil?
                next if node["uuid"] == parent["uuid"]
                object = StarlightPaths::issuePathFromFirstNodeToSecondNodeOrNull(parent, node)
                next if object.nil?
                puts JSON.pretty_generate(object)
            }
    end

    # DataIntegrityOfficer::interfaceLoopOperations()
    def self.interfaceLoopOperations()
        # Make sure that every Clique is on a node
        Nyx::objects("clique-933c2260-92d1-4578-9aaf-cd6557c664c6")
            .each{|clique|
                next if !StarlightContents::getNodesForEntity(clique).empty?

                system("clear")
                puts "[DataIntegrityOfficer] Clique '#{clique["description"]}' doesn't have a Starlight parent, please make and/or select one".green

                if clique["tags"].include?("Pascal Address Book Archives") then
                    node = Nyx::getOrNull("2ec5eda3-7d52-4b5f-8622-df3494280fd9") # Pascal Address Book Archives
                    if node.nil? then
                        puts "error: a6301551"
                        exit
                    end
                    StarlightContents::issueClaimGivenNodeAndEntity(node, clique)
                    return
                end

                if clique["tags"].include?("Talks") then
                    node = Nyx::getOrNull("7c9172cb-f672-4cd9-aeb0-e00e0a2ba620") # Talks
                    if node.nil? then
                        puts "error: a6301551"
                        exit
                    end
                    StarlightContents::issueClaimGivenNodeAndEntity(node, clique)
                    return
                end

                if clique["tags"].include?("Guardian Digital") then
                    node = Nyx::getOrNull("469556a9-6458-43a4-90a8-75a985466124") # Digital
                    if node.nil? then
                        puts "error: a6301551"
                        exit
                    end
                    StarlightContents::issueClaimGivenNodeAndEntity(node, clique)
                    return
                end

                if clique["tags"].include?("Software Engineering") then
                    node = Nyx::getOrNull("6c2744ac-52c7-4b64-9382-0d2d262387d7") # Software Engineering
                    if node.nil? then
                        puts "error: a6301551"
                        exit
                    end
                    StarlightContents::issueClaimGivenNodeAndEntity(node, clique)
                    return
                end


                puts "First I am going to show it to you and then you will add it to a node"

                Cliques::cliqueDive(clique)

                # By now it could have been destroyed
                next if Nyx::getOrNull(clique["uuid"]).nil?
                # By now it also can have a parent node (since we dove)
                next if !StarlightContents::getNodesForEntity(clique).empty?

                node = StarlightMakeAndOrSelectNodeQuest::makeAndOrSelectNodeOrNull()
                next if node.nil?
                StarlightContents::issueClaimGivenNodeAndEntity(node, clique)
                return
            }
    end
end


