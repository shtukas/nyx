
# encoding: UTF-8

class Nyx

    # Nyx::nyxNodes()
    def self.nyxNodes()
        [
            NxConcepts::items(),
            NxDataNodes::items(),
            NxEntities::items(),
            NxEvents::items(),
            NxPersons::items(),
        ].flatten
    end

    # Nyx::program()
    def self.program()
        loop {
            system("clear")

            operations = [
                "search (interactive)",
                "search (classic)",
                "last [n] nodes dive",
                "make new data entity",
                "make new event"
            ]
            operation = LucilleCore::selectEntityFromListOfEntitiesOrNull("operation", operations)
            return if operation.nil?
            if operation == "search (interactive)" then
                Search::interativeInterface()
            end
            if operation == "search (classic)" then
                Search::classicInterface()
            end
            if operation == "last [n] nodes dive" then
                cardinal = LucilleCore::askQuestionAnswerAsString("cardinal : ").to_i

                nodes = Nyx::nyxNodes()
                            .sort{|i1, i2| i1["datetime"] <=> i2["datetime"] }
                            .reverse
                            .first(cardinal)
                            .reverse

                loop {
                    node = LucilleCore::selectEntityFromListOfEntitiesOrNull("node", nodes, lambda{|item| LxFunction::function("toString", item) })
                    break if node.nil?
                    Landing::landing(node)
                }
            end

            if operation == "make new data entity" then
                itemuuid = Architect::interactivelyMakeNewOrNull()
                next if itemuuid.nil?
                item = Fx18Utils::objectuuidToItemOrNull(itemuuid)
                next if item.nil?
                LxAction::action("landing", item)
            end
            if operation == "make new event" then
                item = NxEvents::interactivelyIssueNewItemOrNull()
                puts JSON.pretty_generate(item)
                LxAction::action("landing", item)
            end
        }
    end
end
