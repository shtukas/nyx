
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

    # NSXCatalystObjectsOperator::objectUUIDsToCatalystObjects(objectuuids)
    def self.objectUUIDsToCatalystObjects(objectuuids)
        NSXCatalystObjectsOperator::getObjects().select{|object| objectuuids.include?(object["uuid"]) }
    end

    # NSXCatalystObjectsOperator::getAliveObjects()
    def self.getAliveObjects()
        objects = NSXCatalystObjectsOperator::getObjects()
            .map{|object| object["isRunning"] ? object : NSXMiscUtils::fDoNotShowUntilDateTimeUpdateForDisplay(object) }
            .select{|object| object["metric"] >= 0.2 }
    end

    # NSXCatalystObjectsOperator::arrangeObjectsOnDoubleDirection(objects)
    def self.arrangeObjectsOnDoubleDirection(objects)
        output = []
        while objects.size>2 do
            output << objects.shift     
            output << objects.pop 
        end
        while objects.size>0 do     
            output << objects.pop 
        end
        output
    end

    # NSXCatalystObjectsOperator::getStoredFrozenObjectsOrNull()
    def self.getStoredFrozenObjectsOrNull()
        objects = KeyValueStore::getOrNull(nil, "d685c96f-250f-4529-ba85-eb7f38a18b40")
        return nil if objects.nil?
        JSON.parse(objects)
    end

    # NSXCatalystObjectsOperator::getDoubleDirectionFrozenObjects(aliveObjects)
    def self.getDoubleDirectionFrozenObjects(aliveObjects)
        frozenObjects = NSXCatalystObjectsOperator::getStoredFrozenObjectsOrNull()
        if frozenObjects.nil? then
            if aliveObjects.size<2 then
                return aliveObjects
            end
            objects = NSXCatalystObjectsOperator::arrangeObjectsOnDoubleDirection(aliveObjects)
            KeyValueStore::set(nil, "d685c96f-250f-4529-ba85-eb7f38a18b40", JSON.generate(objects))
            return objects
        else
            frozenObjectsStillCurrent = frozenObjects.select{|fobject| aliveObjects.map{|o| o["uuid"] }.include?(fobject["uuid"]) }
            if frozenObjectsStillCurrent.empty? then
                KeyValueStore::destroy(nil, "d685c96f-250f-4529-ba85-eb7f38a18b40")
                return NSXCatalystObjectsOperator::getDoubleDirectionFrozenObjects(aliveObjects)
            end
            return frozenObjectsStillCurrent
        end     
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
            .sort{|o1, o2| o1["metric"]<=>o2["metric"] }
            .reverse
        objects = NSXCatalystObjectsOperator::getDoubleDirectionFrozenObjects(objects)
        NSXCatalystObjectsOperator::aliveObjectsSpecialCircumstancesProcessing(objects)
    end

end
