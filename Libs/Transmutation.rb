
# encoding: UTF-8

class Transmutation

    # Transmutation::transmutation1(item, source, target)
    def self.transmutation1(item, source, target)

        if source == "TxDated" and target == "TxTodo" then
            item["mikuType"] = "TxTodo"
            Librarian::commit(item)
            return
        end

        if source == "TxDated" and target == "TxFloat" then
            item["mikuType"] = "TxFloat"
            Librarian::commit(item)
            return
        end

        if source == "TxFloat" and target == "TxDated" then
            item["mikuType"] = "TxDated"
            item["datetime"] = CommonUtils::interactivelySelectAUTCIso8601DateTimeOrNull()
            Librarian::commit(item)
            return
        end

        if source == "TxFloat" and target == "TxTodo" then
            item["mikuType"] = "TxTodo"
            Librarian::commit(item)
            return
        end

        if source == "TxTodo" and target == "NxDataNode" then
            item["mikuType"] = "NxDataNode"
            Librarian::commit(item)
            LxAction::action("landing", item)
            return
        end

        if source == "NxDataNode" and target == "NxPerson" then
            item["mikuType"] = "NxPerson"
            item["name"] = item["description"]
            Librarian::commit(item)
        end

        puts "I do not yet know how to transmute from '#{source}' to '#{target}'"
        LucilleCore::pressEnterToContinue()
    end

    # Transmutation::transmutation2(item, source)
    def self.transmutation2(item, source)
        target = Transmutation::interactivelyGetTransmutationTargetOrNull()
        return if target.nil?
        Transmutation::transmutation1(item, source, target)
    end

    # Transmutation::interactivelyGetTransmutationTargetOrNull()
    def self.interactivelyGetTransmutationTargetOrNull()
        options = Iam::nx111Types() + Iam::aggregationTypes()
        LucilleCore::selectEntityFromListOfEntitiesOrNull("target type", options)
    end
end
