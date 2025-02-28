
# encoding: UTF-8

class Nyx

    # Nyx::main()
    def self.main()
        loop {
            system("clear")
            options = [
                "search",
                "new node",
                "list nodes",
            ]
            option = LucilleCore::selectEntityFromListOfEntitiesOrNull("operation", options)
            break if option.nil?
            if option == "search" then
                Search::searchAndDive()
            end
            if option == "new node" then
                node = NxNode28s::interactivelyIssueNewOrNull()
                next if node.nil?
                NxNode28s::program(node)
            end
            if option == "list nodes" then
                loop {
                    nodes = NxNode28s::items().sort{|n1, n2| n1["datetime"] <=> n2["datetime"] }
                    node = LucilleCore::selectEntityFromListOfEntitiesOrNull("node", nodes, lambda{|node| node["description"] })
                    break if node.nil?
                    NxNode28s::program(node)
                }
            end
        }
    end
end

