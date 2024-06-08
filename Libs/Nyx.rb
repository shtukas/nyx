
# encoding: UTF-8

class Nyx

    # Nyx::main()
    def self.main()
        if Config::isPrimaryInstance() then
            Items::processJournal()
        end
        loop {
            system("clear")
            options = [
                "search",
                "new node",
                "dive nodes",
            ]
            option = LucilleCore::selectEntityFromListOfEntitiesOrNull("operation", options)
            break if option.nil?
            if option == "search" then
                Search::searchAndDive()
            end
            if option == "new node" then
                node = Sx0138s::interactivelyIssueNewOrNull()
                next if node.nil?
                Sx0138s::program(node)
            end
            if option == "dive nodes" then
                loop {
                    nodes = Items::mikuType("Sx0138").sort{|n1, n2| n1["datetime"] <=> n2["datetime"] }
                    node = LucilleCore::selectEntityFromListOfEntitiesOrNull("node", nodes, lambda{|node| node["description"] })
                    break if node.nil?
                    Sx0138s::program(node)
                }
            end
        }
    end
end

