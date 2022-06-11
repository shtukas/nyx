
# encoding: UTF-8

class Nyx

    # Nyx::program()
    def self.program()
        loop {
            system("clear")

            operations = [
                "search (interactive)",
                "search (classic)",
                "display nodes in timeline order",
                "make new entity"
            ]
            operation = LucilleCore::selectEntityFromListOfEntitiesOrNull("operation", operations)
            return if operation.nil?
            if operation == "search (interactive)" then
                Search::interativeInterface()
            end
            if operation == "search (classic)" then
                Search::classicInterface()
            end
            if operation == "display nodes in timeline order" then
                NxDataNodes::items()
                    .sort{|i1, i2| i1["datetime"] <=> i2["datetime"] }
                    .each{|item| puts NxDataNodes::toString(item) }
                LucilleCore::pressEnterToContinue()
            end
            if operation == "make new entity" then
                item = NyxNetwork::interactivelyMakeNewOrNull()
                next if item.nil?
                LxAction::action("landing", item)
            end
        }
    end
end
