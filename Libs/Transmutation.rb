
# encoding: UTF-8

class Transmutation

    # Transmutation::transmutation1(item, source, target, isSimulation)
    def self.transmutation1(item, source, target, isSimulation = false)

        if source == "NxCollection" and target == "NxPerson" then
            return true if isSimulation
            Fx18s::setAttribute2(item["uuid"], "name", item["description"])
            Fx18s::setAttribute2(item["uuid"], "mikuType", "NxPerson")
            return
        end

        if source == "NxCollection" and target == "NxTimeline" then
            return true if isSimulation
            Fx18s::setAttribute2(item["uuid"], "mikuType", "NxTimeline")
            return
        end

        if source == "NxDataNode" and target == "NxCollection" then
            return true if isSimulation
            Fx18s::setAttribute2(item["uuid"], "mikuType", "NxCollection")
            return
        end

        if source == "NxDataNode" and target == "NxEvent" then
            return true if isSimulation
            Fx18s::setAttribute2(item["uuid"], "datetime", CommonUtils::interactiveDateTimeBuilder())
            Fx18s::setAttribute2(item["uuid"], "mikuType", "NxEvent")
            return
        end

        if source == "NxDataNode" and target == "NxPerson" then
            return true if isSimulation
            Fx18s::setAttribute2(item["uuid"], "name", item["description"])
            Fx18s::setAttribute2(item["uuid"], "mikuType", "NxPerson")
            return
        end

        if source == "NxDataNode" and target == "NxTimeline" then
            return true if isSimulation
            Fx18s::setAttribute2(item["uuid"], "mikuType", "NxTimeline")
            return
        end

        if source == "NxFrame" and target == "NxDataNode" then
            return true if isSimulation
            Fx18s::setAttribute2(item["uuid"], "mikuType", "NxDataNode")
            return
        end

        if source == "NxFrame" and target == "NxEvent" then
            return true if isSimulation
            Fx18s::setAttribute2(item["uuid"], "datetime", CommonUtils::interactiveDateTimeBuilder())
            Fx18s::setAttribute2(item["uuid"], "mikuType", "NxEvent")
            return
        end

        if source == "NxFrame" and target == "TxDated" then
            return true if isSimulation
            Fx18s::setAttribute2(item["uuid"], "mikuType", "TxDated")
            Fx18s::setAttribute2(item["uuid"], "datetime", CommonUtils::interactivelySelectDateTimeIso8601OrNullUsingDateCode())
            return
        end

        if source == "NxTask" and target == "NxDataNode" then
            return true if isSimulation
            Fx18s::setAttribute2(item["uuid"], "mikuType", "NxDataNode")
            LxAction::action("landing", item)
            return
        end

        if source == "TxDated" and target == "NxDataNode" then
            return true if isSimulation
            Fx18s::setAttribute2(item["uuid"], "mikuType", "NxDataNode")
            LxAction::action("landing", item)
            return
        end

        if source == "TxDated" and target == "NxFrame" then
            return true if isSimulation
            Fx18s::setAttribute2(item["uuid"], "mikuType", "NxFrame")
            return
        end

        if source == "TxDated" and target == "NxTask" then
            return true if isSimulation
            Fx18s::setAttribute2(item["uuid"], "mikuType", "NxTask")
            TxProjects::interactivelyProposeToAttachTaskToProject(item["uuid"])
            return
        end

        return false if isSimulation

        puts "I do not yet know how to transmute from '#{source}' to '#{target}'"
        LucilleCore::pressEnterToContinue()
    end

    # Transmutation::transmutationToInteractivelySelectedTargetType(item)
    def self.transmutationToInteractivelySelectedTargetType(item)
        source = item["mikuType"]
        target = Iam::interactivelyGetTransmutationTargetOrNull()
        return if target.nil?
        Transmutation::transmutation1(item, source, target)
    end
end
