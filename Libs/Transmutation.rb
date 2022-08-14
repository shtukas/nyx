
# encoding: UTF-8

class Transmutation

    # Transmutation::transmutation1(item, source, target)
    def self.transmutation1(item, source, target)

        if source == "NxCollection" and target == "NxPerson" then
            Fx18Attributes::setJsonEncoded(item["uuid"], "name", item["description"])
            Fx18Attributes::setJsonEncoded(item["uuid"], "mikuType", "NxPerson")
            return
        end

        if source == "NxCollection" and target == "NxTimeline" then
            Fx18Attributes::setJsonEncoded(item["uuid"], "mikuType", "NxTimeline")
            return
        end

        if source == "NxDataNode" and target == "NxCollection" then
            Fx18Attributes::setJsonEncoded(item["uuid"], "mikuType", "NxCollection")
            return
        end

        if source == "NxDataNode" and target == "NxEvent" then
            Fx18Attributes::setJsonEncoded(item["uuid"], "datetime", CommonUtils::interactiveDateTimeBuilder())
            Fx18Attributes::setJsonEncoded(item["uuid"], "mikuType", "NxEvent")
            return
        end

        if source == "NxDataNode" and target == "NxPerson" then
            Fx18Attributes::setJsonEncoded(item["uuid"], "name", item["description"])
            Fx18Attributes::setJsonEncoded(item["uuid"], "mikuType", "NxPerson")
            return
        end

        if source == "NxDataNode" and target == "NxTimeline" then
            Fx18Attributes::setJsonEncoded(item["uuid"], "mikuType", "NxTimeline")
            return
        end

        if source == "NxFrame" and target == "NxDataNode" then
            Fx18Attributes::setJsonEncoded(item["uuid"], "mikuType", "NxDataNode")
            return
        end

        if source == "NxFrame" and target == "NxEvent" then
            Fx18Attributes::setJsonEncoded(item["uuid"], "datetime", CommonUtils::interactiveDateTimeBuilder())
            Fx18Attributes::setJsonEncoded(item["uuid"], "mikuType", "NxEvent")
            return
        end

        if source == "NxFrame" and target == "TxDated" then
            Fx18Attributes::setJsonEncoded(item["uuid"], "mikuType", "TxDated")
            Fx18Attributes::setJsonEncoded(item["uuid"], "datetime", CommonUtils::interactivelySelectDateTimeIso8601OrNullUsingDateCode())
            return
        end

        if source == "NxFrame" and target == "NxTask" then
            Fx18Attributes::setJsonEncoded(item["uuid"], "mikuType", "NxTask")
            NxGroups::interactivelyProposeToAttachTaskToProject(item)
            return
        end

        if source == "NxLine" and target == "TxDated" then
            description = item["line"]
            nx111 = Nx111::interactivelyCreateNewNx111OrNull(item["uuid"])
            Fx18Attributes::setJsonEncoded(item["uuid"], "mikuType", "TxDated")
            Fx18Attributes::setJsonEncoded(item["uuid"], "description", description)
            Fx18Attributes::setJsonEncoded(item["uuid"], "nx111", nx111)
            return
        end

        if source == "NxLine" and target == "NxTask" then
            description = item["line"]
            nx111 = Nx111::interactivelyCreateNewNx111OrNull(item["uuid"])

            Fx18Attributes::setJsonEncoded(item["uuid"], "mikuType", "NxTask")
            Fx18Attributes::setJsonEncoded(item["uuid"], "description", description)
            Fx18Attributes::setJsonEncoded(item["uuid"], "nx111", nx111)
            return
        end

        if source == "NxTask" and target == "NxDataNode" then
            Fx18Attributes::setJsonEncoded(item["uuid"], "mikuType", "NxDataNode")
            LxAction::action("landing", item)
            return
        end

        if source == "TxDated" and target == "NxDataNode" then
            Fx18Attributes::setJsonEncoded(item["uuid"], "mikuType", "NxDataNode")
            LxAction::action("landing", item)
            return
        end

        if source == "TxDated" and target == "NxFrame" then
            Fx18Attributes::setJsonEncoded(item["uuid"], "mikuType", "NxFrame")
            return
        end

        if source == "TxDated" and target == "NxTask" then
            Fx18Attributes::setJsonEncoded(item["uuid"], "mikuType", "NxTask")
            NxGroups::interactivelyProposeToAttachTaskToProject(item)
            return
        end

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
