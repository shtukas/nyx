# encoding: UTF-8

class NyxNetwork

    # NyxNetwork::selectEntityFromGivenEntitiesOrNull(entities)
    def self.selectEntityFromGivenEntitiesOrNull(entities)
        item = Utils::selectOneObjectUsingInteractiveInterfaceOrNull(entities, lambda{|entity| Nx31s::toString(entity) })
        return nil if item.nil?
        item
    end

    # -- connects -----------------------------------------------

    # NyxNetwork::linked(entity)
    def self.linked(entity)
         Links::parents(entity["uuid"]) + Links::related(entity["uuid"]) + Links::children(entity["uuid"])
    end

    # NyxNetwork::connectToOtherArchitectured(entity)
    def self.connectToOtherArchitectured(entity)
        connectionType = LucilleCore::selectEntityFromListOfEntitiesOrNull("connection type", ["other is parent", "other is related", "other is child"])
        return if connectionType.nil?
        other = Nx31s::architectOrNull()
        return if other.nil?
        Nx31s::landing(other)
        if connectionType == "other is parent" then
            Links::link(other["uuid"], entity["uuid"], 0)
        end
        if connectionType == "other is related" then
            Links::link(entity["uuid"], other["uuid"], 1)
        end
        if connectionType == "other is child" then
            Links::link(entity["uuid"], other["uuid"], 0)
        end
    end

    # NyxNetwork::disconnectFromLinkedInteractively(entity)
    def self.disconnectFromLinkedInteractively(entity)
        other = LucilleCore::selectEntityFromListOfEntitiesOrNull("connected", NyxNetwork::linked(entity), lambda{|entity| Nx31s::toString(entity)})
        return if other.nil?
        Links::unlink(entity["uuid"], other["uuid"])
    end
end
