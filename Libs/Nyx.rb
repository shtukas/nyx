
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

    # Nyx::selectExistingNetworkNodeOrNull()
    def self.selectExistingNetworkNodeOrNull()
        Search::run(isSearchAndSelect = true)
    end

    # Nyx::interactivelyMakeNewOrNull() # objectuuid or null
    def self.interactivelyMakeNewOrNull()
        action = LucilleCore::selectEntityFromListOfEntitiesOrNull("operation", ["NxDataNode"] + Iam::aggregationTypes())
        return if action.nil?

        if action == "NxDataNode" then
            return NxDataNodes::interactivelyIssueNewItemOrNull()
        end
        if action == "NxPerson" then
            return NxPersons::interactivelyIssueNewOrNull()
        end
        if action == "NxEntity" then
            return NxEntities::interactivelyIssueNewItemOrNull()
        end
        if action == "NxConcept" then
            return NxConcepts::interactivelyIssueNewItemOrNull()
        end
        if action == "NxCollection" then
            return NxCollections::interactivelyIssueNewItemOrNull()
        end
        if action == "NxTimeline" then
            return NxTimelines::interactivelyIssueNewItemOrNull()
        end

        raise "(error: 46cb00c3-9c1d-41cd-8d3d-bfc6598d3e73)"
    end

    # Nyx::architectOneOrNull() # item or null
    def self.architectOneOrNull()
        operations = ["existing || new", "new"]
        operation = LucilleCore::selectEntityFromListOfEntitiesOrNull("operation", operations)
        return nil if operation.nil?
        if operation == "existing || new" then
            entity = Nyx::selectExistingNetworkNodeOrNull()
            return entity if entity
            return Nyx::interactivelyMakeNewOrNull()
        end
        if operation == "new" then
            return Nyx::interactivelyMakeNewOrNull()
        end
    end

    # Nyx::program()
    def self.program()
        loop {
            system("clear")

            operations = [
                "search",
                "last [n] nodes dive",
                "make new data entity",
                "make new event"
            ]
            operation = LucilleCore::selectEntityFromListOfEntitiesOrNull("operation", operations)
            return if operation.nil?
            if operation == "search" then
                Search::run(isSearchAndSelect = false)
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
                    Landing::landing(node, isSearchAndSelect = false)
                }
            end

            if operation == "make new data entity" then
                item = Nyx::interactivelyMakeNewOrNull()
                next if item.nil?
                item = Fx18s::itemOrNull(item["uuid"])
                if item.nil? then
                    raise "(error: 2bce1d88-4460-47ba-9fda-6db066974c75) this should not have hapenned 🤔"
                end
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
