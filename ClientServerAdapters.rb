# encoding: utf-8

# -----------------------------------------------------------------

# FlockOperator::flockObjects()
# FlockOperator::flockObjectsAsMap()
# FlockOperator::removeObjectIdentifiedByUUID(uuid)
# FlockOperator::removeObjectsFromAgent(agentuuid)
# FlockOperator::addOrUpdateObject(object)
# FlockOperator::addOrUpdateObjects(objects)
# FlockOperator::getDoNotShowUntilDateTimeDistribution()
# FlockOperator::setDoNotShowUntilDateTime(uuid, datetime)

class FlockOperator
    def self.flockObjects()
        DRbObject.new(nil, "druby://:18171").flockOperator_flockObjects()
    end
    
    def self.flockObjectsAsMap()
        DRbObject.new(nil, "druby://:18171").flockOperator_flockObjectsAsMap()
    end

    def self.removeObjectIdentifiedByUUID(uuid)
        DRbObject.new(nil, "druby://:18171").flockOperator_removeObjectIdentifiedByUUID(uuid)
    end

    def self.removeObjectsFromAgent(agentuuid)
        DRbObject.new(nil, "druby://:18171").flockOperator_removeObjectsFromAgent(agentuuid)
    end

    def self.addOrUpdateObject(object)
        DRbObject.new(nil, "druby://:18171").flockOperator_addOrUpdateObject(object)
    end

    def self.addOrUpdateObjects(objects)
        DRbObject.new(nil, "druby://:18171").flockOperator_addOrUpdateObjects(objects)
    end    
    
    def self.getDoNotShowUntilDateTimeDistribution()
        DRbObject.new(nil, "druby://:18171").flockOperator_getDoNotShowUntilDateTimeDistribution()
    end

    def self.setDoNotShowUntilDateTime(uuid, datetime)
        DRbObject.new(nil, "druby://:18171").flockOperator_setDoNotShowUntilDateTime(uuid, datetime)
    end
end

# FKVStore::getOrNull(key): value
# FKVStore::getOrDefaultValue(key, defaultValue): value
# FKVStore::set(key, value)

class FKVStore
    def self.getOrNull(key)
        DRbObject.new(nil, "druby://:18171").fKVStore_getOrNull(key)
    end

    def self.getOrDefaultValue(key, defaultValue)
        DRbObject.new(nil, "druby://:18171").fKVStore_getOrDefaultValue(key, defaultValue)
    end

    def self.set(key, value)
        DRbObject.new(nil, "druby://:18171").fKVStore_set(key, value)
    end
end

# TodayOrNotToday::notToday(uuid)

class TodayOrNotToday
    def self.notToday(uuid)
        DRbObject.new(nil, "druby://:18171").todayOrNotToday_notToday(uuid)
    end
end

# RequirementsOperator::getCurrentlyUnsatisfiedRequirements()
# RequirementsOperator::setUnsatisfiedRequirement(requirement)
# RequirementsOperator::setSatisfifiedRequirement(requirement)
# RequirementsOperator::requirementIsCurrentlySatisfied(requirement)

# RequirementsOperator::getObjectRequirements(uuid)
# RequirementsOperator::setObjectRequirements(uuid, requirements)
# RequirementsOperator::addRequirementToObject(uuid,requirement)
# RequirementsOperator::removeRequirementFromObject(uuid,requirement)
# RequirementsOperator::objectMeetsRequirements(uuid)

# RequirementsOperator::getAllRequirements()
# RequirementsOperator::transform()

class RequirementsOperator

    def self.getCurrentlyUnsatisfiedRequirements()
        DRbObject.new(nil, "druby://:18171").requirementsOperator_getCurrentlyUnsatisfiedRequirements()
    end

    def self.setUnsatisfiedRequirement(requirement)
        DRbObject.new(nil, "druby://:18171").requirementsOperator_setUnsatisfiedRequirement(requirement)
    end

    def self.setSatisfifiedRequirement(requirement)
        DRbObject.new(nil, "druby://:18171").requirementsOperator_setSatisfifiedRequirement(requirement)
    end

    def self.requirementIsCurrentlySatisfied(requirement)
        !RequirementsOperator::getCurrentlyUnsatisfiedRequirements().include?(requirement)
    end

    # objects

    def self.getObjectRequirements(uuid)
        DRbObject.new(nil, "druby://:18171").requirementsOperator_getObjectRequirements(uuid)
    end

    def self.setObjectRequirements(uuid, requirements)
        DRbObject.new(nil, "druby://:18171").requirementsOperator_setObjectRequirements(uuid, requirements)
    end

    def self.addRequirementToObject(uuid,requirement)
        RequirementsOperator::setObjectRequirements(uuid, (RequirementsOperator::getObjectRequirements(uuid) + [requirement]).uniq)
    end

    def self.removeRequirementFromObject(uuid,requirement)
        RequirementsOperator::setObjectRequirements(uuid, (RequirementsOperator::getObjectRequirements(uuid).reject{|r| r==requirement }))
    end

    def self.objectMeetsRequirements(uuid)
        RequirementsOperator::getObjectRequirements(uuid)
            .all?{|requirement| RequirementsOperator::requirementIsCurrentlySatisfied(requirement) }
    end

    def self.getAllRequirements()
        FlockOperator::flockObjects().map{|object| RequirementsOperator::getObjectRequirements(object["uuid"]) }.flatten.uniq
    end

    def self.selectRequirementFromExistingRequirementsOrNull()
        LucilleCore::interactivelySelectEntityFromListOfEntitiesOrNull("requirement", RequirementsOperator::getAllRequirements())
    end

    def self.transform()
        FlockOperator::flockObjects().each{|object|
            if !RequirementsOperator::objectMeetsRequirements(object["uuid"]) and object["metric"]<=1 then
                # The second condition in case we start running an object that wasn't scheduled to be shown today (they can be found through search)
                object["metric"] = 0
            end
            FlockOperator::addOrUpdateObject(object)
        }
    end
end

# FlockService::top10Objects()

class FlockService
    def self.top10Objects()
        DRbObject.new(nil, "druby://:18171").top10Objects()
    end
end
