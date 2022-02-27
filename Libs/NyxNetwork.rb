# encoding: UTF-8

class NyxNetwork

    # NyxNetwork::selectEntityFromGivenEntitiesOrNull(entities)
    def self.selectEntityFromGivenEntitiesOrNull(entities)
        item = Utils2::selectOneObjectUsingInteractiveInterfaceOrNull(entities, lambda{|entity| Nx31::toString(entity) })
        return nil if item.nil?
        item
    end

    # -- connects -----------------------------------------------

    # NyxNetwork::linked(entity)
    def self.linked(entity)
         Links::entities(entity["uuid"])
    end

    # NyxNetwork::connectToOtherArchitectured(entity)
    def self.connectToOtherArchitectured(entity)
        other = Nx31::architectOrNull()
        return if other.nil?
        Links::link(entity["uuid"], other["uuid"])
    end

    # NyxNetwork::disconnectFromOtherInteractively(entity)
    def self.disconnectFromOtherInteractively(entity)
        other = LucilleCore::selectEntityFromListOfEntitiesOrNull("connected", NyxNetwork::linked(entity), lambda{|entity| Nx31::toString(entity)})
        return if other.nil?
        Links::unlink(entity["uuid"], other["uuid"])
    end

    # NyxNetwork::networkReplace(uuid1, uuid2)
    # If we want to update the uuid of an element (original: uuid1, new: uuid2)
    # Then we use this function to give to uuid2 the same connects as uuid1 
    def self.networkReplace(uuid1, uuid2)
        Links::entities(uuid1).each{|entity|
            Links::link(uuid2, entity["uuid"])
        }
    end

    # ----------------------------------------------------
    # Deep lines functions

    # NyxNetwork::nomaliseDescriptionForDeepLineSearch(str)
    def self.nomaliseDescriptionForDeepLineSearch(str)
        str.split("::")
            .map{|element| element.strip }
            .join(" :: ")
    end

    # NyxNetwork::computeDeepLineNodes(entity)
    def self.computeDeepLineNodes(entity)
        normalisedDescription = NyxNetwork::nomaliseDescriptionForDeepLineSearch(entity["description"])
        Nx31::mikus().select{|nx31| NyxNetwork::nomaliseDescriptionForDeepLineSearch(nx31["description"]).start_with?(normalisedDescription) }
    end

    # NyxNetwork::computeDeepLineConnectedEntities(entity)
    def self.computeDeepLineConnectedEntities(entity)
        NyxNetwork::computeDeepLineNodes(entity)
            .map{|node| Links::entities(node["uuid"]) }
            .flatten
            .reduce([]){|selected, y|
                if selected.none?{|x| x["uuid"] == y["uuid"] } then
                    selected << y
                end
                selected
            }
    end
end
