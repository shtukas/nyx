
# encoding: UTF-8

class Nyx

    # Nyx::main()
    def self.main()
        loop {
            system("clear")
            options = [
                "search",
                "new node (101)",
                "new node (avaldi)",
                "list nodes",
                "fsck"
            ]
            option = LucilleCore::selectEntityFromListOfEntitiesOrNull("operation", options)
            break if option.nil?
            if option == "search" then
                Search::searchAndDive()
            end
            if option == "new node (101)" then
                node = Nx101s::interactivelyIssueNewOrNull()
                next if node.nil?
                Nx101s::program(node)
            end
            if option == "new node (avaldi)" then
                node = NxAvaldis::interactivelyIssueNewOrNull()
                next if node.nil?
                NxAvaldis::program(node)
            end
            if option == "list nodes" then
                loop {
                    nodes = PolyFunctions::mikuType2("Nx101").sort{|n1, n2| n1["datetime"] <=> n2["datetime"] }
                    node = LucilleCore::selectEntityFromListOfEntitiesOrNull("node", nodes, lambda{|node| node["description"] })
                    break if node.nil?
                    Nx101s::program(node)
                }
            end
            if option == "fsck" then
                Fsck::fsckAll()
            end
        }
    end
end

