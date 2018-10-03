
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

    # RequirementsOperator::selectRequirementFromExistingRequirementsOrNull()
    def self.selectRequirementFromExistingRequirementsOrNull()
        LucilleCore::selectEntityFromListOfEntitiesOrNull("requirement", MetadataInterface::allKnownRequirementsCarriedByObjects())
    end

    # RequirementsOperator::updateForDisplay(object)
    def self.updateForDisplay(object)
        if !MetadataInterface::allObjectRequirementsAreSatisfied(object["uuid"]) and object["metric"]<=1 then
            # The second condition in case we start running an object that wasn't scheduled to be shown today (they can be found through search)
            object["metric"] = 0
            object[":netric-updated-by:RequirementsOperator::updateForDisplay:"] = true
            # There is also something else we need to do: removing the cycle marker
            MetadataInterface::unSetMetricCycleUnixtimeForObject(object["uuid"])
        end
        object
    end
end
