
# encoding: UTF-8

class Frontpage

    # Frontpage::main()
    def self.main()
        loop {
            options = [
                "search",
                "new node",
                "list objects",
                "fsck",
            ]
            option = LucilleCore::selectEntityFromListOfEntitiesOrNull("operation", options)
            break if option.nil?
            if option == "search" then
                Search::searchAndDive()
            end
            if option == "new node" then
                node = PolyActions::forgeNewNodeOrNull()
                next if node.nil?
                Dives::objectDive(node, false)
            end
            if option == "list objects" then
                loop {
                    objects = NxObjectIO::allObjects()
                        .select{|object| PolyFunctions::networkNodeTypes().include?(object["mikuType"]) }
                        .sort{|n1, n2| n1["datetime"] <=> n2["datetime"] }
                    object = LucilleCore::selectEntityFromListOfEntitiesOrNull("object", objects, lambda{|object| PolyFunctions::toString(object) })
                    break if object.nil?
                    Dives::objectDive(object, false)
                }
            end
            if option == "fsck" then
                Fsck::fsckAll()
                LucilleCore::pressEnterToContinue()
            end
        }
    end
end

