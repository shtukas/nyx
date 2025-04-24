
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
            if option == "fsck" then
                NxNode28s::items().each{|item|
                    puts "fsck: item: #{item["uuid"]}"
                    NxNode28s::fsckNxNode28(item)
                }
                puts "fsck completed"
                LucilleCore::pressEnterToContinue()
            end
        }
    end
end

