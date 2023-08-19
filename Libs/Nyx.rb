
# encoding: UTF-8

class Nyx

    # Nyx::main()
    def self.main()
        loop {
            system("clear")
            options = [
                "new node",
                "search",
                "list nodes",
                "fsck"
            ]
            option = LucilleCore::selectEntityFromListOfEntitiesOrNull("operation", options)
            break if option.nil?
            if option == "search" then
                Search::searchAndDive()
            end
            if option == "new node" then
                node = Nx101s::interactivelyIssueNewOrNull()
                next if node.nil?
                Nx101s::program(node)
            end
            if option == "list nodes" then
                loop {
                    nodes = Cubes::mikuType("Nx101").sort{|n1, n2| n1["datetime"] <=> n2["datetime"] }
                    node = LucilleCore::selectEntityFromListOfEntitiesOrNull("node", nodes, lambda{|node| node["description"] })
                    break if node.nil?
                    Nx101s::program(node)
                }
            end
            if option == "fsck" then
                Cubes::mikuType("Nx101").each{|node|
                    node["coreDataRefs"].each{|ref|
                        CoreDataRefsNxCDRs::fsck(node["uuid"], ref)
                    }
                }
            end
        }
    end
end

