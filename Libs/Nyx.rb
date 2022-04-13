
# encoding: UTF-8

class Nyx

    # Nyx::program()
    def self.program()
        loop {
            system("clear")
            operations = [
                "search (all)",
                "search classic (fragment)",
                "new entity",
                "special ops"
            ]
            operation = LucilleCore::selectEntityFromListOfEntitiesOrNull("operation", operations)
            return if operation.nil?
            if operation == "search (all)" then
                Search::funkyInterface()
            end
            if operation == "search classic (fragment)" then
                Search::searchClassic()
            end
            if operation == "new entity" then
                item = NyxNetwork::interactivelyMakeNewOrNull()
                next if item.nil?
                LxAction::action("landing", item)
            end
            if operation == "special ops" then
                specialOps = [
                    "listing per date fragment",
                    "make genesis point",
                ]
                op = LucilleCore::selectEntityFromListOfEntitiesOrNull("op", specialOps)
                if op == "listing per date fragment" then
                    fragment = LucilleCore::askQuestionAnswerAsString("fragment: ")
                    items = [] # TODO
                    loop {
                        item = NyxNetwork::selectEntityFromGivenEntitiesOrNull(items)
                        break if item.nil?
                        LxAction::action("landing", item)
                    }
                end
            end
        }
    end
end
