
# encoding: UTF-8

class Nyx

    # Nyx::pathToNyx()
    def self.pathToNyx()
        "#{Config::pathToGalaxy()}/Nyx"
    end

    # Nyx::main()
    def self.main()
        loop {
            system("clear")
            options = [
                "new node", 
                "search", 
                "list nodes", 
                "blades mikutypes fs scan", 
                "fsck"
            ]
            option = LucilleCore::selectEntityFromListOfEntitiesOrNull("operation", options)
            break if option.nil?
            if option == "search" then
                Search::searchAndDive()
            end
            if option == "new node" then
                node = NxNodes::NxNodesinteractivelyIssueNewNxNodeOrNull()
                next if node.nil?
                NxNodes::landing(node)
            end
            if option == "list nodes" then
                loop {
                    nodes = NxNodes::nodes().sort{|n1, n2| n1["datetime"] <=> n2["datetime"] }
                    node = LucilleCore::selectEntityFromListOfEntitiesOrNull("node", nodes, lambda{|node| node["description"] })
                    break if node.nil?
                    NxNodes::landing(node)
                }
            end
            if option == "blades mikutypes fs scan" then
                MikuTypes::scan()
            end
            if option == "fsck" then
                MikuTypes::mikuTypeUUIDsCached("NxNode").each{|uuid|
                    Solingen::getSet2(uuid, "NxCoreDataRefs").each{|ref|
                        CoreDataRefs::fsck(uuid, ref)
                    }
                }
            end
        }
    end
end

