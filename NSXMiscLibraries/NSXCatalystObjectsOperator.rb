
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

    # NSXCatalystObjectsOperator::catalystObjectsForMainListing()
    def self.catalystObjectsForMainListing()
        objects = NSXCatalystObjectsOperator::getObjects()
        objects = NSXMiscUtils::upgradePriotarizationIfRunningAndFilterAwayDoNotShowUntilObjects(objects)
        objects = objects
                    .map{|object| 
                        object["catalyst:placement"] = NSXPlacement::getValue(object["uuid"]) 
                        object
                    }
        NSXPlacement::clean(objects.map{|object| object["uuid"] })
        objects = objects
                    .sort{|o1, o2| o1["catalyst:placement"] <=> o2["catalyst:placement"] }
        objects
    end

end
