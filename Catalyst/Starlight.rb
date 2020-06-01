# encoding: UTF-8

# require "/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/Catalyst/Starlight.rb"

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

require "/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/Catalyst/PrimaryNetwork.rb"

require "/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/Catalyst/Nyx/Nyx.rb"

# -----------------------------------------------------------------

class StarlightNodes

    # StarlightNodes::makeNodeInteractivelyOrNull()
    def self.makeNodeInteractivelyOrNull()
        puts "Making a new Starlight node..."
        node = {
            "uuid"             => SecureRandom.uuid,
            "nyxType"          => "starlight-node-8826cbad-e54e-4e78-bf7d-28c9c5019721",
            "creationUnixtime" => Time.new.to_f,

            "name" => LucilleCore::askQuestionAnswerAsString("nodename: ")
        }
        NyxObjects::commitToDisk(node)
        puts JSON.pretty_generate(node)
        node
    end

    # StarlightNodes::nodeToString(node)
    def self.nodeToString(node)
        "[node] #{node["name"]} (#{node["uuid"][0, 4]})"
    end
end

class StarlightPaths

    # StarlightPaths::issuePathInteractivelyOrNull()
    def self.issuePathInteractivelyOrNull()
        path = {
            "nyxType"           => "startlight-path-3d68c8f4-57ba-4678-a85b-9de995f8667e",
            "creationTimestamp" => Time.new.to_f,
            "uuid"              => SecureRandom.uuid,

            "sourceuuid" => LucilleCore::askQuestionAnswerAsString("sourceuuid: "),
            "targetuuid" => LucilleCore::askQuestionAnswerAsString("targetuuid: ")
        }
        NyxObjects::commitToDisk(path)
        path
    end

    # StarlightPaths::issuePathFromFirstNodeToSecondNodeOrNull(node1, node2)
    def self.issuePathFromFirstNodeToSecondNodeOrNull(node1, node2)
        return nil if node1["uuid"] == node2["uuid"]
        path = {
            "nyxType"           => "startlight-path-3d68c8f4-57ba-4678-a85b-9de995f8667e",
            "creationTimestamp" => Time.new.to_f,
            "uuid"              => SecureRandom.uuid,
            "sourceuuid" => node1["uuid"],
            "targetuuid" => node2["uuid"]
        }
        NyxObjects::commitToDisk(path)
        path
    end

    # StarlightPaths::getPathsWithGivenTarget(targetuuid)
    def self.getPathsWithGivenTarget(targetuuid)
        NyxObjects::objects("startlight-path-3d68c8f4-57ba-4678-a85b-9de995f8667e")
            .select{|path| path["targetuuid"] == targetuuid }
    end

    # StarlightPaths::getPathsWithGivenSource(sourceuuid)
    def self.getPathsWithGivenSource(sourceuuid)
        NyxObjects::objects("startlight-path-3d68c8f4-57ba-4678-a85b-9de995f8667e")
            .select{|path| path["sourceuuid"] == sourceuuid }
    end

    # StarlightPaths::pathToString(path)
    def self.pathToString(path)
        "[stargate] #{path["sourceuuid"]} -> #{path["targetuuid"]}"
    end

    # StarlightPaths::getParents(node)
    def self.getParents(node)
        StarlightPaths::getPathsWithGivenTarget(node["uuid"])
            .map{|path| NyxObjects::getOrNull(path["sourceuuid"]) }
            .compact
    end

    # StarlightPaths::getChildren(node)
    def self.getChildren(node)
        StarlightPaths::getPathsWithGivenSource(node["uuid"])
            .map{|path| NyxObjects::getOrNull(path["targetuuid"]) }
            .compact
    end
end

class StarlightContents

    # StarlightContents::issueClaimGivenNodeAndEntity(node, something)
    def self.issueClaimGivenNodeAndEntity(node, something)
        claim = {
            "nyxType"          => "starlight-content-claim-b38137c1-fd43-4035-9f2c-af0fddb18c80",
            "creationUnixtime" => Time.new.to_f,
            "uuid"             => SecureRandom.uuid,

            "nodeuuid"   => node["uuid"],
            "targetuuid" => something["uuid"]
        }
        NyxObjects::commitToDisk(claim)
        claim
    end

    # StarlightContents::claimToString(dataclaim)
    def self.claimToString(dataclaim)
        "[starlight ownership claim] #{dataclaim["nodeuuid"]} -> #{dataclaim["targetuuid"]}"
    end

    # StarlightContents::getNodeEntities(node)
    def self.getNodeEntities(node)
        NyxObjects::objects("starlight-content-claim-b38137c1-fd43-4035-9f2c-af0fddb18c80")
            .select{|claim| claim["nodeuuid"] == node["uuid"] }
            .map{|claim| PrimaryNetwork::getSomethingByUuidOrNull(claim["targetuuid"]) }
            .compact
    end

    # StarlightContents::getNodesForEntity(clique)
    def self.getNodesForEntity(clique)
        NyxObjects::objects("starlight-content-claim-b38137c1-fd43-4035-9f2c-af0fddb18c80")
            .select{|claim| claim["targetuuid"] == clique["uuid"] }
            .map{|claim| NyxObjects::getOrNull(claim["nodeuuid"]) }
            .compact
    end
end

class StarlightUserInterface

    # StarlightUserInterface::selectNodeFromExistingNodes()
    def self.selectNodeFromExistingNodes()
        nodestrings = NyxObjects::objects("starlight-node-8826cbad-e54e-4e78-bf7d-28c9c5019721").map{|node| StarlightNodes::nodeToString(node) }
        nodestring = CatalystCommon::chooseALinePecoStyle("node:", [""]+nodestrings)
        node = NyxObjects::objects("starlight-node-8826cbad-e54e-4e78-bf7d-28c9c5019721")
                .select{|node| StarlightNodes::nodeToString(node) == nodestring }
                .first
    end

    # StarlightUserInterface::selectNodeFromExistingOrCreateOneOrNull()
    def self.selectNodeFromExistingOrCreateOneOrNull()
        puts "-> You are selecting a node (possibly will create one)"
        LucilleCore::pressEnterToContinue()
        node = StarlightUserInterface::selectNodeFromExistingNodes()
        return node if node
        if LucilleCore::askQuestionAnswerAsBoolean("Multiverse: You are being selecting a node but did not select any of the existing ones. Would you like to make a new node and return it ? ") then
            return StarlightNodes::makeNodeInteractivelyOrNull()
        end
        nil
    end

    # StarlightUserInterface::nodeDive(node)
    def self.nodeDive(node)
        loop {
            puts ""
            puts JSON.pretty_generate(node)
            puts "uuid: #{node["uuid"]}"
            puts StarlightNodes::nodeToString(node).green
            items = []
            items << ["rename", lambda{ 
                node["name"] = CatalystCommon::editTextUsingTextmate(node["name"]).strip
                NyxObjects::commitToDisk(node)
            }]

            StarlightPaths::getParents(node)
                .sort{|n1, n2| n1["name"] <=> n2["name"] }
                .each{|n| items << ["[network parent] #{StarlightNodes::nodeToString(n)}", lambda{ StarlightUserInterface::nodeDive(n) }] }

            StarlightContents::getNodeEntities(node)
                .sort{|p1, p2| p1["creationTimestamp"] <=> p2["creationTimestamp"] } # "creationTimestamp" is a common attribute of all data entities
                .each{|something| items << ["[something] #{PrimaryNetwork::somethingToString(something)}", lambda{ PrimaryNetworkNavigation::visit(something) }] }

            StarlightPaths::getChildren(node)
                .sort{|n1, n2| n1["name"] <=> n2["name"] }
                .each{|n| items << ["[network child] #{StarlightNodes::nodeToString(n)}", lambda{ StarlightUserInterface::nodeDive(n) }] }

            items << ["add parent node", lambda{ 
                node0 = StarlightMakeAndOrSelectNodeQuest::makeAndOrSelectNodeOrNull()
                path = StarlightPaths::issuePathFromFirstNodeToSecondNodeOrNull(node0, node)
                puts JSON.pretty_generate(path)
                NyxObjects::commitToDisk(path)
            }]

            items << ["add child node", lambda{ 
                node2 = StarlightMakeAndOrSelectNodeQuest::makeAndOrSelectNodeOrNull()
                path = StarlightPaths::issuePathFromFirstNodeToSecondNodeOrNull(node, node2)
                puts JSON.pretty_generate(path)
                NyxObjects::commitToDisk(path)
            }]

            status = LucilleCore::menuItemsWithLambdas(items) # Boolean # Indicates whether an item was chosen
            break if !status
        }
    end

    # StarlightUserInterface::navigation()
    def self.navigation()
        node = StarlightUserInterface::selectNodeFromExistingNodes()
        return if node.nil?
        StarlightUserInterface::nodeDive(node)
    end

    # StarlightUserInterface::management()
    def self.management()
        loop {
            system("clear")
            puts "Starlight Management (root)"
            operations = [
                "make node",
                "make starlight path"
            ]
            operation = LucilleCore::selectEntityFromListOfEntitiesOrNull("operation", operations)
            break if operation.nil?
            if operation == "make node" then
                node = StarlightNodes::makeNodeInteractivelyOrNull()
                puts JSON.pretty_generate(node)
                NyxObjects::commitToDisk(node)
            end
            if operation == "make starlight path" then
                node1 = StarlightMakeAndOrSelectNodeQuest::makeAndOrSelectNodeOrNull()
                next if node1.nil?
                node2 = StarlightMakeAndOrSelectNodeQuest::makeAndOrSelectNodeOrNull()
                next if node2.nil?
                path = StarlightPaths::issuePathFromFirstNodeToSecondNodeOrNull(node1, node2)
                puts JSON.pretty_generate(path)
                NyxObjects::commitToDisk(path)
            end
        }
    end
end

class StarlightMakeAndOrSelectNodeQuest

    # StarlightMakeAndOrSelectNodeQuest::makeAndOrSelectNodeOrNull()
    def self.makeAndOrSelectNodeOrNull()
        puts "-> You are on a selection Quest [selecting a node]"
        puts "-> I am going to make you select one from existing and if that doesn't work, I will make you create a new one [with extensions if you want]"
        LucilleCore::pressEnterToContinue()
        node = StarlightUserInterface::selectNodeFromExistingNodes()
        return node if node
        puts "-> You are on a selection Quest [selecting a node]"
        if LucilleCore::askQuestionAnswerAsBoolean("-> ...but did not select anything. Do you want to create one ? ") then
            node = StarlightNodes::makeNodeInteractivelyOrNull()
            return nil if node.nil?
            puts "-> You are on a selection Quest [selecting a node]"
            puts "-> You have created '#{node["name"]}'"
            option1 = "quest: return '#{node["name"]}' immediately"
            option2 = "quest: dive first"
            options = [ option1, option2 ]
            option = LucilleCore::selectEntityFromListOfEntitiesOrNull("options", options)
            if option == option1 then
                return node
            end
            if option == option2 then
                StarlightUserInterface::nodeDive(node)
                return node
            end
        end
        nil
    end
end

