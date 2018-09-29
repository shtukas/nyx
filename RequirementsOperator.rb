
# encoding: UTF-8

class RequirementsOperator

    # ----------------------------------------------------------------------

    # RequirementsOperator::getCurrentlyUnsatisfiedRequirements()
    def self.getCurrentlyUnsatisfiedRequirements()
        JSON.parse(KeyValueStore::getOrDefaultValue(CATALYST_COMMON_PATH_TO_KV_REPOSITORY, "Currently-Unsatisfied-Requirements-7f8bba56-6755-401c-a1d2-490c0176337f", "[]"))
    end

    # RequirementsOperator::setUnsatisfiedRequirement(requirement)    
    def self.setUnsatisfiedRequirement(requirement)
        rs = RequirementsOperator::getCurrentlyUnsatisfiedRequirements()
        rs = (rs + [ requirement ]).uniq
        KeyValueStore::set(CATALYST_COMMON_PATH_TO_KV_REPOSITORY, "Currently-Unsatisfied-Requirements-7f8bba56-6755-401c-a1d2-490c0176337f", JSON.generate(rs))
    end

    # RequirementsOperator::setSatisfifiedRequirement(requirement)    
    def self.setSatisfifiedRequirement(requirement)
        rs = RequirementsOperator::getCurrentlyUnsatisfiedRequirements()
        rs = rs.reject{|r| r==requirement }
        KeyValueStore::set(CATALYST_COMMON_PATH_TO_KV_REPOSITORY, "Currently-Unsatisfied-Requirements-7f8bba56-6755-401c-a1d2-490c0176337f", JSON.generate(rs))
    end

    # RequirementsOperator::requirementIsCurrentlySatisfied(requirement)    
    def self.requirementIsCurrentlySatisfied(requirement)
        !RequirementsOperator::getCurrentlyUnsatisfiedRequirements().include?(requirement)
    end

    # ----------------------------------------------------------------------

    # RequirementsOperator::getObjectRequirements(uuid)    
    def self.getObjectRequirements(uuid)
        JSON.parse(KeyValueStore::getOrDefaultValue(CATALYST_COMMON_PATH_TO_KV_REPOSITORY, "Object-Requirements-List-6acb38bd-3c4a-4265-a920-2c89154125ce:#{uuid}", "[]"))
    end

    # RequirementsOperator::setObjectRequirements(uuid, requirements)
    def self.setObjectRequirements(uuid, requirements)
        KeyValueStore::set(CATALYST_COMMON_PATH_TO_KV_REPOSITORY, "Object-Requirements-List-6acb38bd-3c4a-4265-a920-2c89154125ce:#{uuid}", JSON.generate(requirements))
    end

    # RequirementsOperator::addRequirementToObject(uuid,requirement)
    def self.addRequirementToObject(uuid,requirement)
        RequirementsOperator::setObjectRequirements(uuid, (RequirementsOperator::getObjectRequirements(uuid) + [requirement]).uniq)
    end

    # RequirementsOperator::removeRequirementFromObject(uuid,requirement)
    def self.removeRequirementFromObject(uuid,requirement)
        RequirementsOperator::setObjectRequirements(uuid, (RequirementsOperator::getObjectRequirements(uuid).reject{|r| r==requirement }))
    end

    # RequirementsOperator::objectMeetsRequirements(uuid)
    def self.objectMeetsRequirements(uuid)
        RequirementsOperator::getObjectRequirements(uuid)
            .all?{|requirement| RequirementsOperator::requirementIsCurrentlySatisfied(requirement) }
    end

    # ----------------------------------------------------------------------

    # RequirementsOperator::getAllRequirements()
    def self.getAllRequirements()
        TheFlock::flockObjects().map{|object| RequirementsOperator::getObjectRequirements(object["uuid"]) }.flatten.uniq
    end

    # RequirementsOperator::selectRequirementFromExistingRequirementsOrNull()
    def self.selectRequirementFromExistingRequirementsOrNull()
        LucilleCore::selectEntityFromListOfEntitiesOrNull("requirement", RequirementsOperator::getAllRequirements())
    end

    # RequirementsOperator::updateForDisplay(object)
    def self.updateForDisplay(object)
        if !RequirementsOperator::objectMeetsRequirements(object["uuid"]) and object["metric"]<=1 then
            # The second condition in case we start running an object that wasn't scheduled to be shown today (they can be found through search)
            object["metric"] = 0
            # There is also something else we need to do: removing the cycle marker
            CyclesOperator::removeUnixtimeMark(object["uuid"])
        end
        object
    end
end
