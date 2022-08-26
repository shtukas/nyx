
# encoding: UTF-8

class Transmutation

    # Transmutation::transmutation1(item, source, target)
    def self.transmutation1(item, source, target)

        if source == "NxCollection" and target == "NxPerson" then
            DxF1s::setJsonEncoded(item["uuid"], "name", item["description"])
            DxF1s::setJsonEncoded(item["uuid"], "mikuType", "NxPerson")
            return
        end

        if source == "NxCollection" and target == "NxTimeline" then
            DxF1s::setJsonEncoded(item["uuid"], "mikuType", "NxTimeline")
            return
        end

        if source == "NxDataNode" and target == "NxCollection" then
            DxF1s::setJsonEncoded(item["uuid"], "mikuType", "NxCollection")
            return
        end

        if source == "NxDataNode" and target == "NxEvent" then
            DxF1s::setJsonEncoded(item["uuid"], "datetime", CommonUtils::interactiveDateTimeBuilder())
            DxF1s::setJsonEncoded(item["uuid"], "mikuType", "NxEvent")
            return
        end

        if source == "NxDataNode" and target == "NxPerson" then
            DxF1s::setJsonEncoded(item["uuid"], "name", item["description"])
            DxF1s::setJsonEncoded(item["uuid"], "mikuType", "NxPerson")
            return
        end

        if source == "NxDataNode" and target == "NxTimeline" then
            DxF1s::setJsonEncoded(item["uuid"], "mikuType", "NxTimeline")
            return
        end

        if source == "NxFrame" and target == "NxDataNode" then
            DxF1s::setJsonEncoded(item["uuid"], "mikuType", "NxDataNode")
            return
        end

        if source == "NxFrame" and target == "NxEvent" then
            DxF1s::setJsonEncoded(item["uuid"], "datetime", CommonUtils::interactiveDateTimeBuilder())
            DxF1s::setJsonEncoded(item["uuid"], "mikuType", "NxEvent")
            return
        end

        if source == "NxFrame" and target == "TxDated" then
            DxF1s::setJsonEncoded(item["uuid"], "mikuType", "TxDated")
            DxF1s::setJsonEncoded(item["uuid"], "datetime", CommonUtils::interactivelySelectDateTimeIso8601OrNullUsingDateCode())
            return
        end

        if source == "NxFrame" and target == "NxTask" then
            DxF1s::setJsonEncoded(item["uuid"], "mikuType", "NxTask")
            item = Fx256::getProtoItemOrNull(uuid)
            TxTimeCommitmentProjects::interactivelyAddThisElementToOwner(item)
            return
        end

        if source == "NxIced" and target == "NxDataNode" then
            DxF1s::setJsonEncoded(item["uuid"], "mikuType", "NxDataNode")
            return
        end

        if source == "NxLine" and target == "TxDated" then
            description = item["line"]
            nx111 = Nx111::interactivelyCreateNewNx111OrNull(item["uuid"])
            DxF1s::setJsonEncoded(item["uuid"], "mikuType", "TxDated")
            DxF1s::setJsonEncoded(item["uuid"], "description", description)
            DxF1s::setJsonEncoded(item["uuid"], "nx111", nx111)
            return
        end

        if source == "NxLine" and target == "NxTask" then
            description = item["line"]
            nx111 = Nx111::interactivelyCreateNewNx111OrNull(item["uuid"])
            DxF1s::setJsonEncoded(item["uuid"], "mikuType", "NxTask")
            DxF1s::setJsonEncoded(item["uuid"], "description", description)
            DxF1s::setJsonEncoded(item["uuid"], "nx111", nx111)
            TxTimeCommitmentProjects::interactivelyAddThisElementToOwner(item)
            return
        end

        if source == "NxTask" and target == "NxDataNode" then
            DxF1s::setJsonEncoded(item["uuid"], "mikuType", "NxDataNode")
            item = Fx256::getProtoItemOrNull(uuid)
            LxAction::action("landing", item)
            return
        end

        if source == "TxDated" and target == "NxDataNode" then
            DxF1s::setJsonEncoded(item["uuid"], "mikuType", "NxDataNode")
            item = Fx256::getProtoItemOrNull(uuid)
            LxAction::action("landing", item)
            return
        end

        if source == "TxDated" and target == "NxFrame" then
            DxF1s::setJsonEncoded(item["uuid"], "mikuType", "NxFrame")
            return
        end

        if source == "TxDated" and target == "NxTask" then
            DxF1s::setJsonEncoded(item["uuid"], "mikuType", "NxTask")
            item = Fx256::getProtoItemOrNull(uuid)
            TxTimeCommitmentProjects::interactivelyAddThisElementToOwner(item)
            return
        end

        if source == "TxIncoming" and target == "NxTask" then
            DxF1s::setJsonEncoded(item["uuid"], "description", item["line"])
            DxF1s::setJsonEncoded(item["uuid"], "nx111", nil)
            DxF1s::setJsonEncoded(item["uuid"], "mikuType", "NxTask")
            item = Fx256::getProtoItemOrNull(item["uuid"])
            TxTimeCommitmentProjects::interactivelyAddThisElementToOwner(item)
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
