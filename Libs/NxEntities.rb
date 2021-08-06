
# encoding: UTF-8

class NxEntities

    # NxEntitiesgetEntityByIdOrNull(uuid)
    def self.getEntityByIdOrNull(uuid)
        entity = NxUniqueString::getNx27ByIdOrNull(uuid)
        return entity if entity
        entity = NxNode::getNx10ByIdOrNull(uuid)
        return entity if entity
        entity = NxAsteroid::getAsteroidByUUIDOrNull(uuid)
        return entity if entity
        entity = NxDirectory2::directoryIdToNxDirectory2OrNull(uuid)
        return entity if entity
        nil
    end

    # NxEntitiestoString(entity)
    def self.toString(entity)
        if entity["entityType"] == "Nx27" then
            return NxUniqueString::toString(entity)
        end
        if entity["entityType"] == "Nx10" then
            return NxNode::toString(entity)
        end
        if entity["entityType"] == "Nx45" then
            return NxAsteroid::toString(entity)
        end
        if entity["entityType"] == "NxDirectory2" then
            return NxDirectory2::toString(entity)
        end
        raise "1f4f2950-acf2-4136-ba09-7a180338393f"
    end

    # NxEntitieslanding(entity)
    def self.landing(entity)
        if entity["entityType"] == "Nx27" then
            return NxUniqueString::landing(entity)
        end
        if entity["entityType"] == "Nx10" then
            return NxNode::landing(entity)
        end
        if entity["entityType"] == "Nx45" then
            return NxAsteroid::landing(entity)
        end
        if entity["entityType"] == "NxDirectory2" then
            return NxDirectory2::landing(entity)
        end
        raise "252103a9-c5f5-4206-92d7-c01fc91f8a06"
    end

    # NxEntitiesentities()
    def self.entities()
        NxUniqueString::nx27s() +
        NxNode::nx10s() +
        NxAsteroid::nx45s() +
        NxDirectory2::directories()
    end

    # NxEntitiesselectExistingEntityOrNull()
    def self.selectExistingEntityOrNull()
        nx19 = Utils::selectOneObjectUsingInteractiveInterfaceOrNull(NxEntitiesentities(), lambda{|entity| NxEntitiestoString(entity) })
        return nil if nx19.nil?
        nx19
    end

    # NxEntitiesinteractivelyCreateNewEntityOrNull()
    def self.interactivelyCreateNewEntityOrNull()
        type = LucilleCore::selectEntityFromListOfEntitiesOrNull("entity type", ["url", "text", "aion-point", "unique-string", "node", "NxDirectory2"])
        return nil if type.nil?
        if type == "url" then
            return NxAsteroid::interactivelyCreateNewUrlOrNull()
        end
        if type == "text" then
            return NxAsteroid::interactivelyCreateNewTextOrNull()
        end
        if type == "aion-point" then
            return NxAsteroid::interactivelyCreateNewAionPointOrNull()
        end
        if type == "unique-string" then
            return NxUniqueString::interactivelyCreateNewUniqueStringOrNull()
        end
        if type == "node" then
            return NxNode::interactivelyCreateNewNx10OrNull()
        end
        if type == "NxDirectory2" then
            return NxDirectory2::interactivelyRegisterNewNxDirectoryOrNull()
        end
        raise "1902268c-f5e3-45fb-bcf5-573f4c14f160"
    end

    # NxEntitiesarchitectEntityOrNull()
    def self.architectEntityOrNull()
        operations = ["existing || new", "new"]
        operation = LucilleCore::selectEntityFromListOfEntitiesOrNull("operation", operations)
        return nil if operation.nil?
        if operation == "existing || new" then
            puts "-> existing"
            sleep 1
            entity = NxEntitiesselectExistingEntityOrNull()
            return entity if entity
            puts "-> new"
            sleep 1
            return NxEntitiesinteractivelyCreateNewEntityOrNull()
        end
        if operation == "new" then
            return NxEntitiesinteractivelyCreateNewEntityOrNull()
        end
    end

    # NxEntitiesentitiesDive(entities)
    def self.entitiesDive(entities)
        loop {
            entity = LucilleCore::selectEntityFromListOfEntitiesOrNull("entity:", entities, lambda{|entity| NxEntitiestoString(entity) })
            break if entity.nil?
            NxEntitieslanding(entity)
        }
    end

    # -- links -----------------------------------------------

    # NxEntitieslinkToOtherArchitectured(entity)
    def self.linkToOtherArchitectured(entity)
        other = NxEntitiesarchitectEntityOrNull()
        return if other.nil?
        Links::insert(entity["uuid"], other["uuid"])
    end

    # NxEntitieslinked(entity)
    def self.linked(entity)
         Links::entities(entity["uuid"])
    end

    # NxEntitiesunlinkFromOther(entity)
    def self.unlinkFromOther(entity)
        other = LucilleCore::selectEntityFromListOfEntitiesOrNull("connected", NxEntitieslinked(entity))
        return if other.nil?
        Links::delete(entity["uuid"], other["uuid"])
    end
end
