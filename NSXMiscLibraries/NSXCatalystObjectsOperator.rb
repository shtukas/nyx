
# encoding: UTF-8

class NSXCatalystObjectsOperator

    # NSXCatalystObjectsOperator::getEndOfHardWorkEmoticon()
    def self.getEndOfHardWorkEmoticon()
        {
            "uuid"      => "10bd6790", 
            "agentUID"  => nil,
            "metric"    => 0.2 + 0.2*Math.exp(-2),
            "announce"  => "(╯°□°）╯︵ ┻━┻",
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

    # NSXCatalystObjectsOperator::catalystObjectsForMainListing()
    def self.catalystObjectsForMainListing()
        spotObjectUUIDs = NSXSpots::getObjectUUIDs()
        (NSXCatalystObjectsOperator::getObjects() + [NSXCatalystObjectsOperator::getEndOfHardWorkEmoticon()])
            .select{|object| !spotObjectUUIDs.include?(object["uuid"]) }
            .map{|object| object["isRunning"] ? object : NSXMiscUtils::fDoNotShowUntilDateTimeUpdateForDisplay(object) }
            .select{|object| object["metric"] >= 0.2 }
            .sort{|o1, o2| o1["metric"]<=>o2["metric"] }
            .reverse
    end

    # NSXCatalystObjectsOperator::objectUUIDsToCatalystObjects(objectuuids)
    def self.objectUUIDsToCatalystObjects(objectuuids)
        NSXCatalystObjectsOperator::getObjects().select{|object| objectuuids.include?(object["uuid"]) }
    end

end
