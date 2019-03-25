
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
        objects1 = objects
                    .select{|object| object["prioritization"] == "running" }
                    .sort{|o1, o2| o1["catalyst:placement"] <=> o2["catalyst:placement"] }
        objects2 = objects
                    .select{|object| object["prioritization"] == "high" }
                    .sort{|o1, o2| o1["catalyst:placement"] <=> o2["catalyst:placement"] }
        objects3 = objects
                    .select{|object| object["prioritization"] == "standard" or object["prioritization"].nil? }
                    .sort{|o1, o2| o1["catalyst:placement"] <=> o2["catalyst:placement"] }
        objects = objects1 + objects2 + objects3
        objects
    end

end
