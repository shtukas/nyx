
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

    # NSXCatalystObjectsOperator::getAliveObjects()
    def self.getAliveObjects()
        objects = NSXCatalystObjectsOperator::getObjects()
            .map{|object| object["isRunning"] ? object : NSXMiscUtils::fDoNotShowUntilDateTimeUpdateForDisplay(object) }
            .select{|object| object["metric"] >= 0.2 }
    end

    # NSXCatalystObjectsOperator::aliveObjectsSpecialCircumstancesProcessing(objects)
    def self.aliveObjectsSpecialCircumstancesProcessing(objects)
        minusEmailsUnixtime = NSXMiscUtils::getMinusEmailsUnixtimeOrNull()
        if minusEmailsUnixtime and (Time.new.to_i - minusEmailsUnixtime) < 3600 then
            objects = objects.reject{|object|
                (object["agentuid"]=="d2de3f8e-6cf2-46f6-b122-58b60b2a96f1") and object["data"]["generic-contents-item"]["type"] == "email"
            }
        end
        objects
    end

    # NSXCatalystObjectsOperator::catalystObjectsForMainListing()
    def self.catalystObjectsForMainListing()
        objects = NSXCatalystObjectsOperator::getAliveObjects()
        objects = NSXCatalystObjectsOperator::aliveObjectsSpecialCircumstancesProcessing(objects)
        objects
            .sort{|o1, o2| o1["metric"]<=>o2["metric"] }
            .reverse
    end

end
