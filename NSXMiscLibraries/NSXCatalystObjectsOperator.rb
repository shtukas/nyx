
# encoding: UTF-8

class NSXCatalystObjectsOperator

    # NSXCatalystObjectsOperator::getObjectsEligibleForListing()
    def self.getObjectsEligibleForListing()
        NSXBob::agents()
            .map{|agentinterface| agentinterface["get-objects"].call() }
            .flatten
            .select{|object| object['metric'] >= 0.2 }
            .reject{|object| NSXDoNotShowUntilDatetime::getFutureDatetimeOrNull(object['uuid']) }
    end

    # NSXCatalystObjectsOperator::getAllObjects()
    def self.getAllObjects()
        NSXBob::agents()
            .map{|agentinterface| agentinterface["get-objects-all"].call() }
            .flatten
    end

    # NSXCatalystObjectsOperator::catalystObjectsOrderedForMainListing1()
    def self.catalystObjectsOrderedForMainListing1()
        objects = NSXCatalystObjectsOperator::getObjectsEligibleForListing()
        objects
                .sort{|o1, o2| o1["metric"]<=>o2["metric"] }
                .reverse
    end

    # NSXCatalystObjectsOperator::catalystObjectsOrderedForMainListing2()
    def self.catalystObjectsOrderedForMainListing2()
        objects = NSXCatalystObjectsOperator::getObjectsEligibleForListing()
        if $GLOBAL_PLACEMENT then
            uuids = NSXPlacements::getClaimsForPlacement($GLOBAL_PLACEMENT).map{|claim| claim["catalystObjectUUID"] }
            objects = objects.select{|object| uuids.include?(object["uuid"]) }
            if objects.size==0 then
                $GLOBAL_PLACEMENT = nil
                return NSXCatalystObjectsOperator::catalystObjectsOrderedForMainListing2()
            end
        else
            uuids = NSXPlacements::getAllClaimsForAllActivePlacements().map{|claim| claim["catalystObjectUUID"] }
            objects = objects.reject{|object| uuids.include?(object["uuid"]) }
        end
        objects
            .sort{|o1, o2| o1["metric"]<=>o2["metric"] }
            .reverse
    end

end
