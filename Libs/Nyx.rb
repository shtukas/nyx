
# encoding: UTF-8

class Nyx

    # Nyx::main()
    def self.main()
        loop {
            EventsTimeline::procesLine()
            system("clear")
            options = [
                "search",
                "new node: 101",
                "new node: avaldi",
                "new node: url",
                "new node: aion-point",
                "list nodes",
                "fsck"
            ]
            option = LucilleCore::selectEntityFromListOfEntitiesOrNull("operation", options)
            break if option.nil?
            if option == "search" then
                Search::searchAndDive()
            end
            if option == "new node: 101" then
                node = Nx101::interactivelyIssueNewOrNull()
                next if node.nil?
                Nx101::program(node)
            end
            if option == "new node: avaldi" then
                node = NxAvaldi::interactivelyIssueNewOrNull()
                next if node.nil?
                NxAvaldi::program(node)
            end
            if option == "new node: url" then
                node = NxUrl1005::interactivelyIssueNewOrNull()
                next if node.nil?
                NxUrl1005::program(node)
            end
            if option == "new node: aion-point" then
                node = NxAionPoints0849::interactivelyIssueNewOrNull()
                next if node.nil?
                NxAionPoints0849::program(node)
            end
            if option == "list nodes" then
                loop {
                    nodes = ItemsDatabase::mikuType2("Nx101").sort{|n1, n2| n1["datetime"] <=> n2["datetime"] }
                    node = LucilleCore::selectEntityFromListOfEntitiesOrNull("node", nodes, lambda{|node| node["description"] })
                    break if node.nil?
                    Nx101::program(node)
                }
            end
            if option == "fsck" then
                Fsck::fsckAll()
            end
        }
    end
end

