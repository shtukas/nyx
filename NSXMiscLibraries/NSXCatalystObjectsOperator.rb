
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

    # NSXCatalystObjectsOperator::catalystObjectsOrderedForMainListing()
    def self.catalystObjectsOrderedForMainListing()
        objects = NSXCatalystObjectsOperator::getObjects()
        objects = objects
                    .reject{|object| NSXDoNotShowUntilDatetime::getFutureDatetimeOrNull(object['uuid']) }
        objects
                .sort{|o1, o2| o1["metric"]<=>o2["metric"] }
                .reverse
    end

end
