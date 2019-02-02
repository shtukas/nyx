
# encoding: UTF-8

class NSXCatalystObjectsOperator

    # NSXCatalystObjectsOperator::getEndOfCompulsoryTasks(metric)
    def self.getEndOfCompulsoryTasks(metric)
        {
            "uuid"      => "10bd6790", 
            "agentuid"  => nil,
            "metric"    => metric,
            "announce"  => "(╯°□°）╯︵ ┻━┻".yellow,
            "commands"  => []
        }
    end

    # NSXCatalystObjectsOperator::getObjects()
    def self.getObjects()
        NSXBob::agents()
            .map{|agentinterface| 
                agentinterface["get-objects"].call()
            }
            .flatten
    end

    # NSXCatalystObjectsOperator::objectUUIDsToCatalystObjects(objectuuids)
    def self.objectUUIDsToCatalystObjects(objectuuids)
        NSXCatalystObjectsOperator::getObjects().select{|object| objectuuids.include?(object["uuid"]) }
    end

    # NSXCatalystObjectsOperator::catalystObjectsForMainListing()
    def self.catalystObjectsForMainListing()
        spotObjectUUIDs = NSXSpots::getObjectUUIDs()
        NSXCatalystObjectsOperator::getObjects()
            .select{|object| !spotObjectUUIDs.include?(object["uuid"]) }
            .map{|object| object["isRunning"] ? object : NSXMiscUtils::fDoNotShowUntilDateTimeUpdateForDisplay(object) }
            .select{|object| object["metric"] >= 0.2 }
            .sort{|o1, o2| o1["metric"]<=>o2["metric"] }
            .reverse
    end

end
