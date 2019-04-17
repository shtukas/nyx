
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

end
