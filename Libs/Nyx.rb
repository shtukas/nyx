
# encoding: UTF-8

class Nyx

    # Nyx::nyxNodes()
    def self.nyxNodes()
        [
            DxAionPoint::items(),
            DxFile::items(),
            DxLine::items(),
            DxText::items(),
            DxUniqueString::items(),
            DxUrl::items(),
            NxConcepts::items(),
            NxCollections::items(),
            NxEntities::items(),
            NxEvents::items(),
            NxPersons::items(),
            NxTimelines::items()
        ].flatten
    end

    # Nyx::selectExistingNetworkNodeOrNull()
    def self.selectExistingNetworkNodeOrNull()
        puts "Nyx::selectExistingNetworkNodeOrNull() [needs implementation]"
        LucilleCore::pressEnterToContinue()
        nil
    end

    # Nyx::interactivelyMakeNewOrNull() # objectuuid or null
    def self.interactivelyMakeNewOrNull()
        action = LucilleCore::selectEntityFromListOfEntitiesOrNull("operation", Iam::nyxNetworkTypes())
        return if action.nil?
        if action == "DxLine" then
            return DxLine::interactivelyIssueNewOrNull()
        end
        if action == "DxUrl" then
            return DxUrl::interactivelyIssueNewOrNull()
        end
        if action == "DxText" then
            return DxText::interactivelyIssueNewOrNull()
        end
        if action == "DxFile" then
            return DxFile::interactivelyIssueNewOrNull()
        end
        if action == "DxAionPoint" then
            return DxAionPoint::interactivelyIssueNewOrNull()
        end
        if action == "DxUniqueString" then
            return DxUniqueString::interactivelyIssueNew()
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
                "make new nyx node"
            ]
            operation = LucilleCore::selectEntityFromListOfEntitiesOrNull("operation", operations)
            return if operation.nil?
            if operation == "search" then
                Search::run()
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
                item = Nyx::interactivelyMakeNewOrNull()
                next if item.nil?
                puts JSON.pretty_generate(item)
                PolyActions::landing(item)
            end
        }
    end
end
