
# encoding: UTF-8

class NSXRequirementsOperator

    # ----------------------------------------------------------------------

    # NSXRequirementsOperator::getCurrentlyUnsatisfiedRequirements()
    def self.getCurrentlyUnsatisfiedRequirements()
        NSXSystemDataOperator::getOrDefaultValue("Currently-Unsatisfied-Requirements-7f8bba56-6755-401c-a1d2-490c0176337f", [])
    end

    # NSXRequirementsOperator::setUnsatisfiedRequirement(requirement)    
    def self.setUnsatisfiedRequirement(requirement)
        rs = NSXRequirementsOperator::getCurrentlyUnsatisfiedRequirements()
        rs = (rs + [ requirement ]).uniq
        NSXSystemDataOperator::set("Currently-Unsatisfied-Requirements-7f8bba56-6755-401c-a1d2-490c0176337f", rs)
    end

    # NSXRequirementsOperator::setSatisfifiedRequirement(requirement)    
    def self.setSatisfifiedRequirement(requirement)
        rs = NSXRequirementsOperator::getCurrentlyUnsatisfiedRequirements()
        rs = rs.reject{|r| r==requirement }
        NSXSystemDataOperator::set("Currently-Unsatisfied-Requirements-7f8bba56-6755-401c-a1d2-490c0176337f", rs)
    end

    # NSXRequirementsOperator::requirementIsCurrentlySatisfied(requirement)    
    def self.requirementIsCurrentlySatisfied(requirement)
        !NSXRequirementsOperator::getCurrentlyUnsatisfiedRequirements().include?(requirement)
    end

    # ----------------------------------------------------------------------

    # NSXRequirementsOperator::selectRequirementFromExistingRequirementsOrNull()
    def self.selectRequirementFromExistingRequirementsOrNull()
        LucilleCore::selectEntityFromListOfEntitiesOrNull("requirement", NSXCatalystMetadataInterface::allKnownRequirementsCarriedByObjects())
    end

    # NSXRequirementsOperator::updateForDisplay(object)
    def self.updateForDisplay(object)
        if !NSXCatalystMetadataInterface::allObjectRequirementsAreSatisfied(object["uuid"]) and object["metric"]<=1 then
            # The second condition in case we start running an object that wasn't scheduled to be shown today (they can be found through search)
            object["metric"] = 0
            object[":netric-updated-by:NSXRequirementsOperator::updateForDisplay:"] = true
            # There is also something else we need to do: removing the cycle marker
            NSXCatalystMetadataInterface::unSetMetricCycleUnixtimeForObject(object["uuid"])
        end
        object
    end
end
