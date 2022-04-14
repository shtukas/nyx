
# encoding: UTF-8

class Nyx

    # Nyx::program()
    def self.program()
        loop {
            system("clear")
            operations = [
                "search (interactive)",
                "search classic (fragment)",
                "new entity",
                "special ops"
            ]
            operation = LucilleCore::selectEntityFromListOfEntitiesOrNull("operation", operations)
            return if operation.nil?
            if operation == "search (interactive)" then
                Search::interativeInterface()
            end
            if operation == "search classic (fragment)" then
                Search::classicInterface()
            end
            if operation == "new entity" then
                item = NyxNetwork::interactivelyMakeNewOrNull()
                next if item.nil?
                LxAction::action("landing", item)
            end
            if operation == "special ops" then
                specialOps = [
                    "listing per date fragment",
                ]
                op = LucilleCore::selectEntityFromListOfEntitiesOrNull("op", specialOps)
                if op == "listing per date fragment" then
                    puts "(95999b79-5d10-4db0-a4ef-c4f640013d0d: This has not been implemented, need re-implementation after refactoring)"
                    LucilleCore::pressEnterToContinue()
                    next

                    fragment = LucilleCore::askQuestionAnswerAsString("fragment: ")
                    items = []
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
