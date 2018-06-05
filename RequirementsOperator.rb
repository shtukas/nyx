
# encoding: UTF-8

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
        JSON.parse(DRbObject.new(nil, "druby://:18171").fKVStore_getOrDefaultValue("Currently-Unsatisfied-Requirements-7f8bba56-6755-401c-a1d2-490c0176337e", "[]"))
    end

    def self.setUnsatisfiedRequirement(requirement)
        rs = RequirementsOperator::getCurrentlyUnsatisfiedRequirements()
        rs = (rs + [ requirement ]).uniq
        DRbObject.new(nil, "druby://:18171").fKVStore_set("Currently-Unsatisfied-Requirements-7f8bba56-6755-401c-a1d2-490c0176337e", JSON.generate(rs))
    end

    def self.setSatisfifiedRequirement(requirement)
        rs = RequirementsOperator::getCurrentlyUnsatisfiedRequirements()
        rs = rs.reject{|r| r==requirement }
        DRbObject.new(nil, "druby://:18171").fKVStore_set("Currently-Unsatisfied-Requirements-7f8bba56-6755-401c-a1d2-490c0176337e", JSON.generate(rs))
    end

    def self.requirementIsCurrentlySatisfied(requirement)
        !RequirementsOperator::getCurrentlyUnsatisfiedRequirements().include?(requirement)
    end

    # objects

    def self.getObjectRequirements(uuid)
        JSON.parse(DRbObject.new(nil, "druby://:18171").fKVStore_getOrDefaultValue("Object-Requirements-List-6acb38bd-3c4a-4265-a920-2c89154125ce:#{uuid}", "[]"))
    end

    def self.setObjectRequirements(uuid, requirements)
        DRbObject.new(nil, "druby://:18171").fKVStore_set("Object-Requirements-List-6acb38bd-3c4a-4265-a920-2c89154125ce:#{uuid}", JSON.generate(requirements))
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
        DRbObject.new(nil, "druby://:18171").flockOperator_flockObjects().map{|object| RequirementsOperator::getObjectRequirements(object["uuid"]) }.flatten.uniq
    end

    def self.selectRequirementFromExistingRequirementsOrNull()
        LucilleCore::interactivelySelectEntityFromListOfEntitiesOrNull("requirement", RequirementsOperator::getAllRequirements())
    end

    def self.transform()
        DRbObject.new(nil, "druby://:18171").flockOperator_flockObjects().each{|object|
            if !RequirementsOperator::objectMeetsRequirements(object["uuid"]) and object["metric"]<=1 then
                # The second condition in case we start running an object that wasn't scheduled to be shown today (they can be found through search)
                object["metric"] = 0
            end
            DRbObject.new(nil, "druby://:18171").flockOperator_addOrUpdateObject(object)
        }
    end
end
