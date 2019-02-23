
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

        # ----------------------------------------------------
        # Do not display emails when emails are off
        minusEmailsUnixtime = NSXMiscUtils::getMinusEmailsUnixtimeOrNull()
        if minusEmailsUnixtime and (Time.new.to_i - minusEmailsUnixtime) < 3600 then
            objects = objects.reject{|object|
                (object["agentuid"]=="d2de3f8e-6cf2-46f6-b122-58b60b2a96f1") and object["data"]["generic-contents-item"]["type"] == "email"
            }
        end

        # ----------------------------------------------------
        # Apply special mapping for less then 0.5 elements
        getStoredUUIDsOfLowElementsOrNull = lambda {
            uuids = KeyValueStore::getOrNull(nil, "3714dfd8-6bbb-413e-a9ef-4022508ce4e4:#{NSXMiscUtils::currentDay()}")
            return nil if uuids.nil?
            JSON.parse(uuids)
        }
        getTodayUUIDsOfLowElements = lambda {|objects|
            uuids = getStoredUUIDsOfLowElementsOrNull.call()
            return uuids if uuids
            uuids = objects
                        .select{|object| object["metric"] < 0.5 }
                        .map{|object| object["uuid"] }
            KeyValueStore::set(nil, "3714dfd8-6bbb-413e-a9ef-4022508ce4e4:#{NSXMiscUtils::currentDay()}", JSON.generate(uuids))
            uuids
        }
        metricRecomputation = lambda {|metric|
            # [0.2, 0.6] -> [0.9, 0.6]
            0.9 - ((metric-0.2).to_f/4)*3
        }
        uuidsx = getTodayUUIDsOfLowElements.call(objects)
        objects = objects.map{|object|
            if !object["isRunning"] and uuidsx.include?(object["uuid"]) then
                object["announce"] = "[bumped] #{object["announce"]}"
                object["metric-pre-bump:61a9ee39"] = object["metric"]
                object["metric"] = metricRecomputation.call(object["metric"])
            end
            object
        }

        # ----------------------------------------------------
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
