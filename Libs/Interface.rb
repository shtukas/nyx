
# encoding: UTF-8

class Interface

    # Interface::main()
    def self.main()
        loop {
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
                node = NxNode::interactivelyIssueNewOrNull()
                next if node.nil?
                NxNode::program(node, false)
            end
            if option == "list nodes" then
                loop {
                    nodes = NxNode::items().sort{|n1, n2| n1["datetime"] <=> n2["datetime"] }
                    node = LucilleCore::selectEntityFromListOfEntitiesOrNull("node", nodes, lambda{|node| node["description"] })
                    break if node.nil?
                    NxNode::program(node, false)
                }
            end
            if option == "fsck" then
                NxNode::items().each{|item|
                    if item["mikuType"] == "Nx27" then
                        puts "fsck: item: #{item["uuid"]}"
                        NxNode::fsckItem(item)
                    end
                }
                puts "fsck completed"
                LucilleCore::pressEnterToContinue()
            end
        }
    end
end

