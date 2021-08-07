
# encoding: UTF-8

class NyxEntities

    # NyxEntities::getEntityByIdOrNull(uuid)
    def self.getEntityByIdOrNull(uuid)
        entity = NxUniqueString::getNx27ByIdOrNull(uuid)
        return entity if entity
        entity = NxDataCarrier::getNx10ByIdOrNull(uuid)
        return entity if entity
        entity = NxAsteroid::getAsteroidByUUIDOrNull(uuid)
        return entity if entity
        entity = NxFSPoint::getItemByUUIDOrNull(uuid)
        return entity if entity
        entity = NxDirectory3::getItemByUUIDOrNull(uuid)
        return entity if entity
        entity = NxNode::getNxNodeByIdOrNull(uuid)
        return entity if entity
        nil
    end

    # NyxEntities::toString(entity)
    def self.toString(entity)
        if entity["entityType"] == "Nx27" then
            return NxUniqueString::toString(entity)
        end
        if entity["entityType"] == "Nx10" then
            return NxDataCarrier::toString(entity)
        end
        if entity["entityType"] == "Nx45" then
            return NxAsteroid::toString(entity)
        end
        if entity["entityType"] == "NxFSPoint" then
            return NxFSPoint::toString(entity)
        end
        if entity["entityType"] == "NxDirectory3" then
            return NxDirectory3::toString(entity)
        end
        if entity["entityType"] == "NxNode" then
            return NxNode::toString(entity)
        end
        raise "1f4f2950-acf2-4136-ba09-7a180338393f"
    end

    # NyxEntities::landing(entity)
    def self.landing(entity)
        if entity["entityType"] == "Nx27" then
            return NxUniqueString::landing(entity)
        end
        if entity["entityType"] == "Nx10" then
            return NxDataCarrier::landing(entity)
        end
        if entity["entityType"] == "Nx45" then
            return NxAsteroid::landing(entity)
        end
        if entity["entityType"] == "NxFSPoint" then
            return NxFSPoint::landing(entity)
        end
        if entity["entityType"] == "NxDirectory3" then
            return NxDirectory3::landing(entity)
        end
        if entity["entityType"] == "NxNode" then
            return NxNode::landing(entity)
        end
        raise "252103a9-c5f5-4206-92d7-c01fc91f8a06"
    end

    # NyxEntities::entities()
    def self.entities()
        NxUniqueString::nx27s() +
        NxDataCarrier::nx10s() +
        NxAsteroid::asteroids() +
        NxDirectory3::directories() + 
        NxFSPoint::points() +
        NxNode::nxnodes()
    end

    # NyxEntities::selectExistingEntityOrNull()
    def self.selectExistingEntityOrNull()
        nx19 = Utils::selectOneObjectUsingInteractiveInterfaceOrNull(NyxEntities::entities(), lambda{|entity| NyxEntities::toString(entity) })
        return nil if nx19.nil?
        nx19
    end

    # NyxEntities::interactivelyCreateNewEntityOrNull()
    def self.interactivelyCreateNewEntityOrNull()
        type = LucilleCore::selectEntityFromListOfEntitiesOrNull("entity type", ["node", "data carrier"])
        return nil if type.nil?
        if type == "node" then
            return NxNode::interactivelyCreateNewOrNull()
        end
        if type == "data carrier" then
            return NxDataCarrier::interactivelyCreateNewNx10OrNull()
        end
        raise "1902268c-f5e3-45fb-bcf5-573f4c14f160"
    end

    # NyxEntities::architectEntityOrNull()
    def self.architectEntityOrNull()
        operations = ["existing || new", "new"]
        operation = LucilleCore::selectEntityFromListOfEntitiesOrNull("operation", operations)
        return nil if operation.nil?
        if operation == "existing || new" then
            puts "-> existing"
            sleep 1
            entity = NyxEntities::selectExistingEntityOrNull()
            return entity if entity
            puts "-> new"
            sleep 1
            return NyxEntities::interactivelyCreateNewEntityOrNull()
        end
        if operation == "new" then
            return NyxEntities::interactivelyCreateNewEntityOrNull()
        end
    end

    # NyxEntities::entitiesDive(entities)
    def self.entitiesDive(entities)
        if entities.empty? then
            puts "info: entities dive: nothing provided"
            LucilleCore::pressEnterToContinue()
            return
        end
        loop {
            entity = LucilleCore::selectEntityFromListOfEntitiesOrNull("entity:", entities, lambda{|entity| NyxEntities::toString(entity) })
            break if entity.nil?
            NyxEntities::landing(entity)
        }
    end

    # -- links -----------------------------------------------

    # NyxEntities::linked(entity)
    def self.linked(entity)
         Links::entities(entity["uuid"])
    end

    # NyxEntities::linkToOtherArchitectured(entity)
    def self.linkToOtherArchitectured(entity)
        other = NyxEntities::architectEntityOrNull()
        return if other.nil?
        Links::insert(entity["uuid"], other["uuid"])
    end

    # NyxEntities::unlinkFromOther(entity)
    def self.unlinkFromOther(entity)
        other = LucilleCore::selectEntityFromListOfEntitiesOrNull("connected", NyxEntities::linked(entity))
        return if other.nil?
        Links::delete(entity["uuid"], other["uuid"])
    end
end
