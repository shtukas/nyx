
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
        objects = NSXCatalystObjectsOperator::getObjects()
            .select{|object| !spotObjectUUIDs.include?(object["uuid"]) }
            .map{|object| object["isRunning"] ? object : NSXMiscUtils::fDoNotShowUntilDateTimeUpdateForDisplay(object) }
            .select{|object| object["metric"] >= 0.2 }
            .sort{|o1, o2| o1["metric"]<=>o2["metric"] }
            .reverse
        minusEmailsUnixtime = NSXMiscUtils::getMinusEmailsUnixtimeOrNull()
        if minusEmailsUnixtime and (Time.new.to_i - minusEmailsUnixtime) < 3600 then
            objects = objects.reject{|object|
                (object["agentuid"]=="d2de3f8e-6cf2-46f6-b122-58b60b2a96f1") and object["data"]["generic-contents-item"]["type"] == "email"
            }
        end
        objects
    end

end
