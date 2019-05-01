
# encoding: UTF-8

class NSXCatalystObjectsOperator

    # NSXCatalystObjectsOperator::getObjectsEligibleForListing()
    def self.getObjectsEligibleForListing()
        NSXBob::agents()
            .map{|agentinterface| agentinterface["get-objects"].call() }
            .flatten
            .reject{|object| NSXDoNotShowUntilDatetime::getFutureDatetimeOrNull(object['uuid']) }
            .select{|object| object['metric'] >= 0.2 }
    end

    # NSXCatalystObjectsOperator::getAllObjects()
    def self.getAllObjects()
        NSXBob::agents()
            .map{|agentinterface| agentinterface["get-objects-all"].call() }
            .flatten
    end

    # NSXCatalystObjectsOperator::catalystObjectsOrderedForMainListing()
    def self.catalystObjectsOrderedForMainListing()
        objects = NSXCatalystObjectsOperator::getObjectsEligibleForListing()
        objects
            .map{|object|
                ratio = NSXMiscUtils::metricWeightRatioOrNull(object["uuid"])
                object[":catalyst-weigth-ratio:"] = ratio
                if ratio then
                    object["metric"] = ratio*object["metric"]

                end
                object
            }
            .select{|object| object['metric'] >= 0.2 }
            .sort{|o1, o2| o1["metric"]<=>o2["metric"] }
            .reverse
    end
end
