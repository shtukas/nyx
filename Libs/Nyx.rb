
# encoding: UTF-8

class Nyx

    # Nyx::main()
    def self.main()
        NxNode28::maintenance()
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
                node = NxNode28::interactivelyIssueNewOrNull()
                next if node.nil?
                NxNode28::program(node, false)
            end
            if option == "list nodes" then
                loop {
                    nodes = NxNode28::items().sort{|n1, n2| n1["datetime"] <=> n2["datetime"] }
                    node = LucilleCore::selectEntityFromListOfEntitiesOrNull("node", nodes, lambda{|node| node["description"] })
                    break if node.nil?
                    NxNode28::program(node, false)
                }
            end
            if option == "fsck" then
                NxNode28::items().each{|item|
                    puts "fsck: item: #{item["uuid"]}"
                    Item::fsckItem(item)
                }
                puts "fsck completed"
                LucilleCore::pressEnterToContinue()
            end
        }
    end
end

