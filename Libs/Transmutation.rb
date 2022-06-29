
# encoding: UTF-8

class Transmutation

    # Transmutation::transmutation1(item, source, target, isSimulation)
    def self.transmutation1(item, source, target, isSimulation = false)

        if source == "NxCollection" and target == "NxPerson" then
            return true if isSimulation
            item["mikuType"] = "NxPerson"
            item["name"] = item["description"]
            Librarian::commit(item)
            return
        end

        if source == "NxDataNode" and target == "NxCollection'" then
            return true if isSimulation
            item["mikuType"] = "NxCollection"
            Librarian::commit(item)
            return
        end

        if source == "NxDataNode" and target == "NxPerson" then
            return true if isSimulation
            item["mikuType"] = "NxPerson"
            item["name"] = item["description"]
            Librarian::commit(item)
            return
        end

        if source == "NxDataNode" and target == "NxTimeline" then
            return true if isSimulation
            item["mikuType"] = "NxTimeline"
            Librarian::commit(item)
            return
        end

        if source == "NxFrame" and target == "TxDated" then
            return true if isSimulation
            item["mikuType"] = "TxDated"
            item["datetime"] = CommonUtils::interactivelySelectAUTCIso8601DateTimeOrNull()
            Librarian::commit(item)
            return
        end

        if source == "NxTask" and target == "NxDataNode" then
            return true if isSimulation
            item["mikuType"] = "NxDataNode"
            Librarian::commit(item)
            LxAction::action("landing", item)
            return
        end

        if source == "TxDated" and target == "NxDataNode" then
            return true if isSimulation
            item["mikuType"] = "NxDataNode"
            Librarian::commit(item)
            LxAction::action("landing", item)
            return
        end

        if source == "TxDated" and target == "NxFrame" then
            return true if isSimulation
            item["mikuType"] = "NxFrame"
            Librarian::commit(item)
            return
        end

        if source == "TxDated" and target == "NxTask" then
            return true if isSimulation
            item["mikuType"] = "NxTask"
            item["status"] = "active"
            Librarian::commit(item)
            return
        end

        return false if isSimulation

        puts "I do not yet know how to transmute from '#{source}' to '#{target}'"
        LucilleCore::pressEnterToContinue()
    end

    # Transmutation::transmutation2(item, source)
    def self.transmutation2(item, source)
        target = Iam::interactivelyGetTransmutationTargetOrNull()
        return if target.nil?
        Transmutation::transmutation1(item, source, target)
    end
end
