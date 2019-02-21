
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

    # NSXCatalystObjectsOperator::getAliveObjects()
    def self.getAliveObjects()
        objects = NSXCatalystObjectsOperator::getObjects()
            .map{|object| object["isRunning"] ? object : NSXMiscUtils::fDoNotShowUntilDateTimeUpdateForDisplay(object) }
            .select{|object| object["metric"] >= 0.2 }
    end

    # NSXCatalystObjectsOperator::getStoredFrozenObjectsOrNull()
    def self.getStoredFrozenObjectsOrNull()
        return nil if Time.new.hour<18
        objects = KeyValueStore::getOrNull(nil, "#{CATALYST_RUN_HASH}:d685c96f-250f-4529-ba85-eb7f38a18b39")
        return nil if objects.nil?
        JSON.parse(objects)
    end

    # NSXCatalystObjectsOperator::getManagedFrozenObjectsOrNull()
    def self.getManagedFrozenObjectsOrNull()
        aliveObjects = NSXCatalystObjectsOperator::getAliveObjects()
        frozenObjects = NSXCatalystObjectsOperator::getStoredFrozenObjectsOrNull()
        if frozenObjects.nil? then
            aliveObjectsSample = aliveObjects
                .reject{|object| object["agentuid"]=="d3d1d26e-68b5-4a99-a372-db8eb6c5ba58" }
                .sample(10)
                .shuffle
            if aliveObjectsSample.size<5 then
                return nil
            end
            KeyValueStore::set(nil, "#{CATALYST_RUN_HASH}:d685c96f-250f-4529-ba85-eb7f38a18b39", JSON.generate(aliveObjectsSample))
            return aliveObjectsSample
        else
            frozenObjectsStillCurrent = frozenObjects.select{|fobject| aliveObjects.map{|o| o["uuid"] }.include?(fobject["uuid"]) }
            if frozenObjectsStillCurrent.size<5 then
                KeyValueStore::destroy(nil, "#{CATALYST_RUN_HASH}:d685c96f-250f-4529-ba85-eb7f38a18b39")
                return NSXCatalystObjectsOperator::getManagedFrozenObjectsOrNull()
            end
            return frozenObjectsStillCurrent
        end     
    end

    # NSXCatalystObjectsOperator::aliveObjectsSpecialCircumstancesProcessing(object)
    def self.aliveObjectsSpecialCircumstancesProcessing(object)
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
        if Time.new.hour>=18 then
            objects = NSXCatalystObjectsOperator::getManagedFrozenObjectsOrNull()
            return objects if objects
        end
        objects = NSXCatalystObjectsOperator::getAliveObjects()   
            .sort{|o1, o2| o1["metric"]<=>o2["metric"] }
            .reverse
        NSXCatalystObjectsOperator::aliveObjectsSpecialCircumstancesProcessing(object)
    end

end
