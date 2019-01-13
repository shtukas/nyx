
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

    # NSXCatalystObjectsOperator::alphaInsertionShouldIncludeMore(orderedObjectsRequired, orderedObjectsTail, streamDifferential)
    def self.alphaInsertionShouldIncludeMore(orderedObjectsRequired, orderedObjectsTail, streamDifferential)
        return false if orderedObjectsTail.size==0
        return true if orderedObjectsTail.any?{|object| object["agentuid"]=="201cac75-9ecc-4cac-8ca1-2643e962a6c6" and object["item-data"]["percentage"] and object["item-data"]["percentage"] < 100 }
        return true if orderedObjectsTail.any?{|object| object["agentuid"]=="283d34dd-c871-4a55-8610-31e7c762fb0d" }
        return true if ( streamDifferential>0 and orderedObjectsRequired.select{|object| object["agentuid"]=="d2de3f8e-6cf2-46f6-b122-58b60b2a96f1" }.size<streamDifferential )
        false
    end

    # NSXCatalystObjectsOperator::alphaInsert(orderedObjectsRequired, orderedObjectsTail, streamDifferential)
    def self.alphaInsert(orderedObjectsRequired, orderedObjectsTail, streamDifferential)
        # NSXCatalystObjectsOperator::getEndOfCompulsoryTasks()
        if NSXCatalystObjectsOperator::alphaInsertionShouldIncludeMore(orderedObjectsRequired, orderedObjectsTail, streamDifferential) then
            NSXCatalystObjectsOperator::alphaInsert(
                orderedObjectsRequired + orderedObjectsTail[0,1], 
                orderedObjectsTail[1,orderedObjectsTail.size],
                streamDifferential
            )
        else
            if orderedObjectsRequired.size>0 and orderedObjectsTail.size>0 then
                metric = (orderedObjectsRequired.last["metric"] + orderedObjectsTail.first["metric"]).to_f/2
                return orderedObjectsRequired + [ NSXCatalystObjectsOperator::getEndOfCompulsoryTasks(metric) ] + NSXStreamsUtils::get20StreamItemsCatalystObjects( (metric+0.2).to_f/2 )
            end
            if orderedObjectsRequired.size>0 and orderedObjectsTail.size==0 then
                metric = orderedObjectsRequired.last["metric"] - 0.001
                return orderedObjectsRequired + [NSXCatalystObjectsOperator::getEndOfCompulsoryTasks(metric)] + NSXStreamsUtils::get20StreamItemsCatalystObjects( (metric+0.2).to_f/2 )
            end
            if orderedObjectsRequired.size==0 and orderedObjectsTail.size>0 then
                metric = orderedObjectsTail.first["metric"] + 0.001
                return [NSXCatalystObjectsOperator::getEndOfCompulsoryTasks(metric)] + NSXStreamsUtils::get20StreamItemsCatalystObjects( (metric+0.2).to_f/2 )
            end
            if orderedObjectsRequired.size==0 and orderedObjectsTail.size==0 then
                return [NSXCatalystObjectsOperator::getEndOfCompulsoryTasks(0.5)] + NSXStreamsUtils::get20StreamItemsCatalystObjects(0.4)
            end
        end
    end

    # NSXCatalystObjectsOperator::catalystObjectsForMainListing()
    def self.catalystObjectsForMainListing()
        spotObjectUUIDs = NSXSpots::getObjectUUIDs()
        streamDifferential = NSXStreamsUtils::getDifferentialOrNull()
        objects = NSXCatalystObjectsOperator::getObjects()
            .select{|object| !spotObjectUUIDs.include?(object["uuid"]) }
            .map{|object| object["isRunning"] ? object : NSXMiscUtils::fDoNotShowUntilDateTimeUpdateForDisplay(object) }
            .select{|object| object["metric"] >= 0.2 }
            .sort{|o1, o2| o1["metric"]<=>o2["metric"] }
            .reverse
        NSXCatalystObjectsOperator::alphaInsert([], objects, streamDifferential)
    end

end
