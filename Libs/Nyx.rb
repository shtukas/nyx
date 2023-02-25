
# encoding: UTF-8

class Nyx

    # Nyx::pathToNyx()
    def self.pathToNyx()
        "#{Config::pathToGalaxy()}/Nyx"
    end

    # Nyx::main()
    def self.main()
        loop {
            options = ["search", "new node", "list nodes", "fs scan", "fsck"]
            option = LucilleCore::selectEntityFromListOfEntitiesOrNull("operation", options)
            break if option.nil?
            if option == "search" then
                NightSky::search_action()
            end
            if option == "new node" then
                node = NightSky::interactivelyIssueNewNxNodeNull()
                next if node.nil?
                NightSky::landing(node)
            end
            if option == "list nodes" then
                loop {
                    nodes = NightSky::nodes().sort{|n1, n2| n1.unixtime() <=> n2.unixtime() }
                    node = LucilleCore::selectEntityFromListOfEntitiesOrNull("node", nodes, lambda{|node| node.description() })
                    break if node.nil?
                    NightSky::landing(node)
                }
            end
            if option == "fs scan" then
                NightSky::fs_scan()
            end
            if option == "fsck" then
                NightSky::nodeEnumeratorFromFSEnumeration().each{|node|
                    node.fsck()
                }
            end
        }
    end
end

