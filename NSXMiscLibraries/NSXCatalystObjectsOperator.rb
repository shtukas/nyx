
# encoding: UTF-8

class NSXCatalystObjectsOperator

    # NSXCatalystObjectsOperator::getAllObjects()
    def self.getAllObjects()
        NSXBob::agents()
            .map{|agentinterface| agentinterface["get-objects-all"].call() }
            .flatten
    end

    # NSXCatalystObjectsOperator::getCatalystListingObjects()
    def self.getCatalystListingObjects()
        NSXBob::agents()
            .map{|agentinterface| agentinterface["get-objects"].call() }
            .flatten
            .reject{|object| NSXDoNotShowUntilDatetime::getFutureDatetimeOrNull(object['uuid']) }
            .select{|object| object['metric'] >= 0.2 }
    end

    # NSXCatalystObjectsOperator::getCatalystListingObjectsOrdered()
    def self.getCatalystListingObjectsOrdered()
        objects = NSXCatalystObjectsOperator::getCatalystListingObjects()
        objects
            .map{|object|
                ratio = NSXMiscUtils::metricWeightRatioOrNull(object["uuid"])
                object[":catalyst-weigth-ratio:"] = ratio
                if ratio then
                    object["metric"] = ratio*(object["metric"]-0.2)+0.2

                end
                object
            }
            .sort{|o1, o2| o1["metric"]<=>o2["metric"] }
            .reverse
    end
end
