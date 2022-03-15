
# encoding: UTF-8

class Transmutation
    # Transmutation::transmutation1(object, source, target)
    # source: "TxDated" (dated) | "TxTodo" | "TxFloat" (float) | "inbox"
    # target: "TxDated" (dated) | "TxTodo" | "TxFloat" (float)
    def self.transmutation1(object, source, target)

        if source == "inbox" and target == "TxTodo" then
            location = object
            TxTodos::interactivelyIssueItemUsingInboxLocation2(location)
            LucilleCore::removeFileSystemLocation(location)
            return
        end

        if source == "TxDated" and target == "TxTodo" then
            universe = Multiverse::interactivelySelectUniverse()
            ordinal = TxTodos::interactivelyDecideNewOrdinal(universe)
            object["ordinal"] = ordinal
            object["mikuType"] = "TxTodo"
            Librarian6Objects::commit(object)
            ObjectUniverseMapping::setObjectUniverseMapping(object["uuid"], universe)
            return
        end

        if source == "TxDated" and target == "TxFyre" then
            object["mikuType"] = "TxFyre"
            Librarian6Objects::commit(object)
            ObjectUniverseMapping::interactivelySetObjectUniverseMapping(object["uuid"])
            return
        end

        if source == "TxDated" and target == "TxFloat" then
            object["mikuType"] = "TxFloat"
            Librarian6Objects::commit(object)
            ObjectUniverseMapping::interactivelySetObjectUniverseMapping(object["uuid"])
            return
        end

        if source == "TxFloat" and target == "TxDated" then
            universe = Multiverse::interactivelySelectUniverse()
            object["mikuType"] = "TxDated"
            object["datetime"] = Utils::interactivelySelectAUTCIso8601DateTimeOrNull()
            Librarian6Objects::commit(object)
            ObjectUniverseMapping::setObjectUniverseMapping(object["uuid"], universe)
            return
        end

        if source == "TxFloat" and target == "TxFyre" then
            universe = Multiverse::interactivelySelectUniverse()
            object["mikuType"] = "TxFyre"
            Librarian6Objects::commit(object)
            ObjectUniverseMapping::setObjectUniverseMapping(object["uuid"], universe)
            return
        end

        if source == "TxFloat" and target == "TxTodo" then
            universe = Multiverse::interactivelySelectUniverse()
            ordinal = TxTodos::interactivelyDecideNewOrdinal(universe)
            object["ordinal"] = ordinal
            object["mikuType"] = "TxTodo"
            Librarian6Objects::commit(object)
            ObjectUniverseMapping::setObjectUniverseMapping(object["uuid"], universe)
            return
        end

        if source == "TxFyre" and target == "TxTodo" then
            universe = Multiverse::interactivelySelectUniverse()
            ordinal = TxTodos::interactivelyDecideNewOrdinal(universe)
            object["ordinal"] = ordinal
            object["mikuType"] = "TxTodo"
            Librarian6Objects::commit(object)
            ObjectUniverseMapping::setObjectUniverseMapping(object["uuid"], universe)
            return
        end

        if source == "TxFyre" and target == "TxFloat" then
            universe = Multiverse::interactivelySelectUniverse()
            object["mikuType"] = "TxFloat"
            Librarian6Objects::commit(object)
            ObjectUniverseMapping::setObjectUniverseMapping(object["uuid"], universe)
            return
        end

        if source == "TxTodo" and target == "TxFyre" then
            universe = Multiverse::interactivelySelectUniverse()
            object["mikuType"] = "TxFyre"
            Librarian6Objects::commit(object)
            ObjectUniverseMapping::setObjectUniverseMapping(object["uuid"], universe)
            return
        end

        puts "I do not yet know how to transmute from '#{source}' to '#{target}'"
        LucilleCore::pressEnterToContinue()
    end

    # Transmutation::transmutation2(object, source)
    def self.transmutation2(object, source)
        target = Transmutation::interactivelyGetTransmutationTargetOrNull()
        return if target.nil?
        Transmutation::transmutation1(object, source, target)
    end

    # Transmutation::interactivelyGetTransmutationTargetOrNull()
    def self.interactivelyGetTransmutationTargetOrNull()
        options = ["TxFloat", "TxFyre", "TxDated", "TxTodo" ]
        option = LucilleCore::selectEntityFromListOfEntitiesOrNull("target", options)
        return nil if option.nil?
        option
    end
end
