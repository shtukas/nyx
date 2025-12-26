
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
                "fsck",
            ]
            option = LucilleCore::selectEntityFromListOfEntitiesOrNull("operation", options)
            break if option.nil?
            if option == "search" then
                Search::searchAndDive()
            end
            if option == "new node" then
                node = Nx27::interactivelyIssueNewOrNull()
                next if node.nil?
                Nx27::program(node, false)
            end
            if option == "list nodes" then
                loop {
                    nodes = Nodes::nodes().sort{|n1, n2| n1["datetime"] <=> n2["datetime"] }
                    node = LucilleCore::selectEntityFromListOfEntitiesOrNull("node", nodes, lambda{|node| Nodes::description(node) })
                    break if node.nil?
                    Nodes::program(node, false)
                }
            end
            if option == "fsck" then
                Nodes::nodes().each{|item|
                    if item["mikuType"] == "Nx27" then
                        puts "fsck: item: #{item["uuid"]}"
                        Nx27::fsckItem(item)
                    end
                }
                puts "fsck completed"
                LucilleCore::pressEnterToContinue()
            end
        }
    end
end

