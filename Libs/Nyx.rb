
# encoding: UTF-8

class Nyx

    # Nyx::main()
    def self.main()
        ItemsDatabase::maintenance()
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
                Nx27::programNode(node, false)
            end
            if option == "list nodes" then
                loop {
                    nodes = ItemsDatabase::items().sort{|n1, n2| n1["datetime"] <=> n2["datetime"] }
                    node = LucilleCore::selectEntityFromListOfEntitiesOrNull("node", nodes, lambda{|node| node["description"] })
                    break if node.nil?
                    Nx27::programNode(node, false)
                }
            end
            if option == "fsck" then
                ItemsDatabase::items().each{|item|
                    puts "fsck: item: #{item["uuid"]}"
                    Nx27::fsckItem(item)
                }
                puts "fsck completed"
                LucilleCore::pressEnterToContinue()
            end
        }
    end
end

