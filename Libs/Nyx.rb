
# encoding: UTF-8

class Nyx

    # Nyx::nyxNodes()
    def self.nyxNodes()
        NyxNodes::items()
    end

    # Nyx::selectExistingNetworkNodeOrNull()
    def self.selectExistingNetworkNodeOrNull()
        Search::foxTerrier()
    end

    # Nyx::architectOneOrNull() # item or null
    def self.architectOneOrNull()
        operations = ["existing || new", "new"]
        operation = LucilleCore::selectEntityFromListOfEntitiesOrNull("operation", operations)
        return nil if operation.nil?
        if operation == "existing || new" then
            entity = Nyx::selectExistingNetworkNodeOrNull()
            return entity if entity
            return NyxNodes::interactivelyIssueNewOrNull()
        end
        if operation == "new" then
            return NyxNodes::interactivelyIssueNewOrNull()
        end
    end

    # Nyx::program()
    def self.program()
        loop {
            system("clear")

            operations = [
                "search",
                "last [n] nodes dive",
                "make new nyx node"
            ]
            operation = LucilleCore::selectEntityFromListOfEntitiesOrNull("operation", operations)
            return if operation.nil?
            if operation == "search" then
                Search::navigation()
            end
            if operation == "last [n] nodes dive" then
                cardinal = LucilleCore::askQuestionAnswerAsString("cardinal : ").to_i

                nodes = Nyx::nyxNodes()
                            .sort{|i1, i2| i1["datetime"] <=> i2["datetime"] }
                            .reverse
                            .first(cardinal)
                            .reverse

                loop {
                    node = LucilleCore::selectEntityFromListOfEntitiesOrNull("node", nodes, lambda{|item| PolyFunctions::toString(item) })
                    break if node.nil?
                    PolyActions::landing(node)
                }
            end
            if operation == "make new nyx node" then
                item = NyxNodes::interactivelyIssueNewOrNull()
                next if item.nil?
                puts JSON.pretty_generate(item)
                PolyActions::landing(item)
            end
        }
    end
end
