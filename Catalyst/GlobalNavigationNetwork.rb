# encoding: UTF-8

# require "/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/Catalyst/GlobalNavigationNetwork.rb"

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

class GlobalNavigationNetworkNodes

    # GlobalNavigationNetworkNodes::makeNodeInteractivelyOrNull()
    def self.makeNodeInteractivelyOrNull()
        puts "Making a new Starlight node..."
        node = {
            "uuid"             => SecureRandom.uuid,
            "nyxType"          => "starlight-node-8826cbad-e54e-4e78-bf7d-28c9c5019721",
            "creationUnixtime" => Time.new.to_f,

            "name" => LucilleCore::askQuestionAnswerAsString("nodename: ")
        }
        NyxNetwork::commitToDisk(node)
        puts JSON.pretty_generate(node)
        node
    end

    # GlobalNavigationNetworkNodes::nodeToString(node)
    def self.nodeToString(node)
        "[node] #{node["name"]} (#{node["uuid"][0, 4]})"
    end
end

class GlobalNavigationNetworkPaths

    # GlobalNavigationNetworkPaths::path()
    def self.path()
        "/Users/pascal/Galaxy/DataBank/Catalyst/Global-Navigation-Network/paths"
    end

    # GlobalNavigationNetworkPaths::save(path)
    def self.save(path)
        filepath = "#{GlobalNavigationNetworkPaths::path()}/#{path["uuid"]}.json"
        File.open(filepath, "w") {|f| f.puts(JSON.pretty_generate(path)) }
    end

    # GlobalNavigationNetworkPaths::getOrNull(uuid)
    def self.getOrNull(uuid)
        filepath = "#{GlobalNavigationNetworkPaths::path()}/#{uuid}.json"
        return nil if !File.exists?(filepath)
        JSON.parse(IO.read(filepath))
    end

    # GlobalNavigationNetworkPaths::paths()
    def self.paths()
        Dir.entries(GlobalNavigationNetworkPaths::path())
            .select{|filename| filename[-5, 5] == ".json" }
            .map{|filename| "#{GlobalNavigationNetworkPaths::path()}/#{filename}" }
            .map{|filepath| JSON.parse(IO.read(filepath)) }
            .sort{|i1, i2| i1["creationTimestamp"]<=>i2["creationTimestamp"] }
    end

    # GlobalNavigationNetworkPaths::issuePathInteractivelyOrNull()
    def self.issuePathInteractivelyOrNull()
        path = {
            "catalystType"      => "catalyst-type:starlight-path",
            "creationTimestamp" => Time.new.to_f,
            "uuid"              => SecureRandom.uuid,

            "sourceuuid" => LucilleCore::askQuestionAnswerAsString("sourceuuid: "),
            "targetuuid" => LucilleCore::askQuestionAnswerAsString("targetuuid: ")
        }
        GlobalNavigationNetworkPaths::save(path)
        path
    end

    # GlobalNavigationNetworkPaths::issuePathFromFirstNodeToSecondNodeOrNull(node1, node2)
    def self.issuePathFromFirstNodeToSecondNodeOrNull(node1, node2)
        return nil if node1["uuid"] == node2["uuid"]
        path = {
            "catalystType"      => "catalyst-type:starlight-path",
            "creationTimestamp" => Time.new.to_f,
            "uuid"              => SecureRandom.uuid,
            "sourceuuid" => node1["uuid"],
            "targetuuid" => node2["uuid"]
        }
        GlobalNavigationNetworkPaths::save(path)
        path
    end

    # GlobalNavigationNetworkPaths::getPathsWithGivenTarget(targetuuid)
    def self.getPathsWithGivenTarget(targetuuid)
        GlobalNavigationNetworkPaths::paths()
            .select{|path| path["targetuuid"] == targetuuid }
    end

    # GlobalNavigationNetworkPaths::getPathsWithGivenSource(sourceuuid)
    def self.getPathsWithGivenSource(sourceuuid)
        GlobalNavigationNetworkPaths::paths()
            .select{|path| path["sourceuuid"] == sourceuuid }
    end

    # GlobalNavigationNetworkPaths::pathToString(path)
    def self.pathToString(path)
        "[stargate] #{path["sourceuuid"]} -> #{path["targetuuid"]}"
    end

    # GlobalNavigationNetworkPaths::getParents(node)
    def self.getParents(node)
        GlobalNavigationNetworkPaths::getPathsWithGivenTarget(node["uuid"])
            .map{|path| NyxNetwork::getOrNull(path["sourceuuid"]) }
            .compact
    end

    # GlobalNavigationNetworkPaths::getChildren(node)
    def self.getChildren(node)
        GlobalNavigationNetworkPaths::getPathsWithGivenSource(node["uuid"])
            .map{|path| NyxNetwork::getOrNull(path["targetuuid"]) }
            .compact
    end
end

class GlobalNavigationNetworkContents

    # GlobalNavigationNetworkContents::path()
    def self.path()
        "/Users/pascal/Galaxy/DataBank/Catalyst/Global-Navigation-Network/ownershipclaims"
    end

    # GlobalNavigationNetworkContents::save(dataclaim)
    def self.save(dataclaim)
        filepath = "#{GlobalNavigationNetworkContents::path()}/#{dataclaim["uuid"]}.json"
        File.open(filepath, "w") {|f| f.puts(JSON.pretty_generate(dataclaim)) }
    end

    # GlobalNavigationNetworkContents::getOrNull(uuid)
    def self.getOrNull(uuid)
        filepath = "#{GlobalNavigationNetworkContents::path()}/#{uuid}.json"
        return nil if !File.exists?(filepath)
        JSON.parse(IO.read(filepath))
    end

    # GlobalNavigationNetworkContents::claims()
    def self.claims()
        Dir.entries(GlobalNavigationNetworkContents::path())
            .select{|filename| filename[-5, 5] == ".json" }
            .map{|filename| "#{GlobalNavigationNetworkContents::path()}/#{filename}" }
            .map{|filepath| JSON.parse(IO.read(filepath)) }
            .sort{|i1, i2| i1["creationTimestamp"]<=>i2["creationTimestamp"] }
    end

    # GlobalNavigationNetworkContents::issueClaimGivenNodeAndEntity(node, something)
    def self.issueClaimGivenNodeAndEntity(node, something)
        claim = {
            "catalystType"      => "catalyst-type:time-ownership-claim",
            "creationTimestamp" => Time.new.to_f,
            "uuid"              => SecureRandom.uuid,

            "nodeuuid"   => node["uuid"],
            "targetuuid" => something["uuid"]
        }
        GlobalNavigationNetworkContents::save(claim)
        claim
    end

    # GlobalNavigationNetworkContents::claimToString(dataclaim)
    def self.claimToString(dataclaim)
        "[starlight ownership claim] #{dataclaim["nodeuuid"]} -> #{dataclaim["targetuuid"]}"
    end

    # GlobalNavigationNetworkContents::getNodeEntities(node)
    def self.getNodeEntities(node)
        GlobalNavigationNetworkContents::claims()
            .select{|claim| claim["nodeuuid"] == node["uuid"] }
            .map{|claim| PrimaryNetwork::getSomethingByUuidOrNull(claim["targetuuid"]) }
            .compact
    end

    # GlobalNavigationNetworkContents::getNodesForEntity(clique)
    def self.getNodesForEntity(clique)
        GlobalNavigationNetworkContents::claims()
            .select{|claim| claim["targetuuid"] == clique["uuid"] }
            .map{|claim| NyxNetwork::getOrNull(claim["nodeuuid"]) }
            .compact
    end
end

class GlobalNavigationNetworkUserInterface

    # GlobalNavigationNetworkUserInterface::selectNodeFromExistingNodes()
    def self.selectNodeFromExistingNodes()
        nodestrings = NyxNetwork::getObjects("starlight-node-8826cbad-e54e-4e78-bf7d-28c9c5019721").map{|node| GlobalNavigationNetworkNodes::nodeToString(node) }
        nodestring = CatalystCommon::chooseALinePecoStyle("node:", [""]+nodestrings)
        node = NyxNetwork::getObjects("starlight-node-8826cbad-e54e-4e78-bf7d-28c9c5019721")
                .select{|node| GlobalNavigationNetworkNodes::nodeToString(node) == nodestring }
                .first
    end

    # GlobalNavigationNetworkUserInterface::nodeDive(node)
    def self.nodeDive(node)
        loop {
            puts ""
            puts JSON.pretty_generate(node)
            puts "uuid: #{node["uuid"]}"
            puts GlobalNavigationNetworkNodes::nodeToString(node).green
            items = []
            items << ["rename", lambda{ 
                node["name"] = CatalystCommon::editTextUsingTextmate(node["name"]).strip
                NyxNetwork::commitToDisk(node)
            }]

            GlobalNavigationNetworkPaths::getParents(node)
                .sort{|n1, n2| n1["name"] <=> n2["name"] }
                .each{|n| items << ["[network parent] #{GlobalNavigationNetworkNodes::nodeToString(n)}", lambda{ GlobalNavigationNetworkUserInterface::nodeDive(n) }] }

            GlobalNavigationNetworkContents::getNodeEntities(node)
                .sort{|p1, p2| p1["creationTimestamp"] <=> p2["creationTimestamp"] } # "creationTimestamp" is a common attribute of all data entities
                .each{|something| items << ["[something] #{PrimaryNetwork::somethingToString(something)}", lambda{ PrimaryNetworkNavigation::visit(something) }] }

            GlobalNavigationNetworkPaths::getChildren(node)
                .sort{|n1, n2| n1["name"] <=> n2["name"] }
                .each{|n| items << ["[network child] #{GlobalNavigationNetworkNodes::nodeToString(n)}", lambda{ GlobalNavigationNetworkUserInterface::nodeDive(n) }] }

            items << ["add parent node", lambda{ 
                node0 = GlobalNavigationNetworkMakeAndOrSelectNodeQuest::makeAndOrSelectNodeOrNull()
                path = GlobalNavigationNetworkPaths::issuePathFromFirstNodeToSecondNodeOrNull(node0, node)
                puts JSON.pretty_generate(path)
                GlobalNavigationNetworkPaths::save(path)
            }]

            items << ["add child node", lambda{ 
                node2 = GlobalNavigationNetworkMakeAndOrSelectNodeQuest::makeAndOrSelectNodeOrNull()
                path = GlobalNavigationNetworkPaths::issuePathFromFirstNodeToSecondNodeOrNull(node, node2)
                puts JSON.pretty_generate(path)
                GlobalNavigationNetworkPaths::save(path)
            }]

            status = LucilleCore::menuItemsWithLambdas(items) # Boolean # Indicates whether an item was chosen
            break if !status
        }
    end

    # GlobalNavigationNetworkUserInterface::selectNodeFromExistingOrCreateOneOrNull()
    def self.selectNodeFromExistingOrCreateOneOrNull()
        puts "-> You are selecting a node (possibly will create one)"
        LucilleCore::pressEnterToContinue()
        node = GlobalNavigationNetworkUserInterface::selectNodeFromExistingNodes()
        return node if node
        if LucilleCore::askQuestionAnswerAsBoolean("Multiverse: You are being selecting a node but did not select any of the existing ones. Would you like to make a new node and return it ? ") then
            return GlobalNavigationNetworkNodes::makeNodeInteractivelyOrNull()
        end
        nil
    end

    # GlobalNavigationNetworkUserInterface::mainNavigation()
    def self.mainNavigation()
        node = GlobalNavigationNetworkUserInterface::selectNodeFromExistingNodes()
        return if node.nil?
        GlobalNavigationNetworkUserInterface::nodeDive(node)
    end

    # GlobalNavigationNetworkUserInterface::management()
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
                node = GlobalNavigationNetworkNodes::makeNodeInteractivelyOrNull()
                puts JSON.pretty_generate(node)
                NyxNetwork::commitToDisk(node)
            end
            if operation == "make starlight path" then
                node1 = GlobalNavigationNetworkMakeAndOrSelectNodeQuest::makeAndOrSelectNodeOrNull()
                next if node1.nil?
                node2 = GlobalNavigationNetworkMakeAndOrSelectNodeQuest::makeAndOrSelectNodeOrNull()
                next if node2.nil?
                path = GlobalNavigationNetworkPaths::issuePathFromFirstNodeToSecondNodeOrNull(node1, node2)
                puts JSON.pretty_generate(path)
                GlobalNavigationNetworkPaths::save(path)
            end
        }
    end
end

class GlobalNavigationNetworkMakeAndOrSelectNodeQuest

    # GlobalNavigationNetworkMakeAndOrSelectNodeQuest::makeAndOrSelectNodeOrNull()
    def self.makeAndOrSelectNodeOrNull()
        puts "-> You are on a selection Quest [selecting a node]"
        puts "-> I am going to make you select one from existing and if that doesn't work, I will make you create a new one [with extensions if you want]"
        LucilleCore::pressEnterToContinue()
        node = GlobalNavigationNetworkUserInterface::selectNodeFromExistingNodes()
        return node if node
        puts "-> You are on a selection Quest [selecting a node]"
        if LucilleCore::askQuestionAnswerAsBoolean("-> ...but did not select anything. Do you want to create one ? ") then
            node = GlobalNavigationNetworkNodes::makeNodeInteractivelyOrNull()
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
                GlobalNavigationNetworkUserInterface::nodeDive(node)
                return node
            end
        end
        nil
    end
end

