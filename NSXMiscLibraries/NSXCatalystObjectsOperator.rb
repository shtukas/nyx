
# encoding: UTF-8

class NSXCatalystObjectsOperator

    # NSXCatalystObjectsOperator::getObjects()
    def self.getObjects()
        NSXBob::agents()
            .map{|agentinterface| 
                agentinterface["get-objects"].call()
            }
            .flatten
    end

    # NSXCatalystObjectsOperator::catalystObjectsOrderedForMainListing1()
    def self.catalystObjectsOrderedForMainListing1()
        objects = NSXCatalystObjectsOperator::getObjects()
        objects = objects
                    .reject{|object| NSXDoNotShowUntilDatetime::getFutureDatetimeOrNull(object['uuid']) }
        objects
                .sort{|o1, o2| o1["metric"]<=>o2["metric"] }
                .reverse
    end

    # NSXCatalystObjectsOperator::catalystObjectsOrderedForMainListing2()
    def self.catalystObjectsOrderedForMainListing2()
        objects = NSXCatalystObjectsOperator::getObjects()
        objects = objects.reject{|object| NSXDoNotShowUntilDatetime::getFutureDatetimeOrNull(object['uuid']) }
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
