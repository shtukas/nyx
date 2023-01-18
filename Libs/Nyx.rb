
# encoding: UTF-8

class Nyx

    # Nyx::pathToNyx()
    def self.pathToNyx()
        "#{Config::pathToGalaxy()}/Nyx"
    end

    # Nyx::main()
    def self.main()
        loop {
            options = ["search", "make new node", "list nodes"]
            option = LucilleCore::selectEntityFromListOfEntitiesOrNull("operation", options)
            break if option.nil?
            if option == "search" then
                SearchNyx::run()
            end
            if option == "make new node" then
                node = NxNodes::interactivelyIssueNewOrNull()
                NxNodes::landing(node)
            end
            if option == "list nodes" then
                loop {
                    items = NxNodes::items().sort{|n1, n2| n1["unixtime"] <=> n2["unixtime"] }
                    node = LucilleCore::selectEntityFromListOfEntitiesOrNull("node", items, lambda{|node| NxNodes::toString(node) })
                    break if node.nil?
                    NxNodes::landing(node)
                }
            end
        }
    end
end
