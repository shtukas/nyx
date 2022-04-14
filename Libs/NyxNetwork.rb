# encoding: UTF-8

class NyxNetwork

    # NyxNetwork::selectEntityFromGivenEntitiesOrNull(items)
    def self.selectEntityFromGivenEntitiesOrNull(items)
        item = Utils::selectOneObjectUsingInteractiveInterfaceOrNull(items, lambda{|item| LxFunction::function("toString", item) })
        return nil if item.nil?
        item
    end

    # NyxNetwork::selectExistingNetworkElementOrNull()
    def self.selectExistingNetworkElementOrNull()
        nx20 = Search::funkyInterfaceInterativelySelectNx20OrNull()
        return nil if nx20.nil?
        nx20["payload"]
    end

    # NyxNetwork::interactivelyMakeNewOrNull()
    def self.interactivelyMakeNewOrNull()
        Nx100s::interactivelyCreateNewOrNull()
    end

    # NyxNetwork::architectOrNull()
    def self.architectOrNull()
        operations = ["existing || new", "new"]
        operation = LucilleCore::selectEntityFromListOfEntitiesOrNull("operation", operations)
        return nil if operation.nil?
        if operation == "existing || new" then
            puts "-> existing"
            sleep 1
            entity = NyxNetwork::selectExistingNetworkElementOrNull()
            return entity if entity
            puts "-> new"
            sleep 1
            return NyxNetwork::interactivelyMakeNewOrNull()
        end
        if operation == "new" then
            return NyxNetwork::interactivelyMakeNewOrNull()
        end
    end

    # NyxNetwork::linked(item)
    def self.linked(item)
         Links::parents(item["uuid"]) + Links::related(item["uuid"]) + Links::children(item["uuid"])
    end

    # NyxNetwork::linkToDesignatedOther(item, other)
    def self.linkToDesignatedOther(item, other)
        connectionType = LucilleCore::selectEntityFromListOfEntitiesOrNull("connection type", ["other is parent", "other is related (default)", "other is child"])
        if connectionType.nil? or connectionType == "other is related (default)" then
            Links::link(item["uuid"], other["uuid"], true)
        end
        if connectionType == "other is parent" then
            Links::link(other["uuid"], item["uuid"], false)
        end
        if connectionType == "other is child" then
            Links::link(item["uuid"], other["uuid"], false)
        end
    end

    # NyxNetwork::connectToOtherArchitectured(item)
    def self.connectToOtherArchitectured(item)
        connectionType = LucilleCore::selectEntityFromListOfEntitiesOrNull("connection type", ["other is parent", "other is related", "other is child"])
        return if connectionType.nil?
        other = NyxNetwork::architectOrNull()
        return if other.nil?
        if connectionType == "other is parent" then
            Links::link(other["uuid"], item["uuid"], false)
        end
        if connectionType == "other is related" then
            Links::link(item["uuid"], other["uuid"], true)
        end
        if connectionType == "other is child" then
            Links::link(item["uuid"], other["uuid"], false)
        end
        LxAction::action("landing", other)
    end

    def self.relinkToOther(item)
        other = LucilleCore::selectEntityFromListOfEntitiesOrNull("linked", NyxNetwork::linked(item), lambda{|item| LxFunction::function("toString", item)})
        return if other.nil?
        Links::unlink(item["uuid"], other["uuid"])
        NyxNetwork::linkToDesignatedOther(item, other)
    end

    # NyxNetwork::disconnectFromLinkedInteractively(item)
    def self.disconnectFromLinkedInteractively(item)
        other = LucilleCore::selectEntityFromListOfEntitiesOrNull("linked", NyxNetwork::linked(item), lambda{|item| LxFunction::function("toString", item)})
        return if other.nil?
        Links::unlink(item["uuid"], other["uuid"])
    end
end
