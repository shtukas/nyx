
# encoding: UTF-8

$CATALYST_OBJECTS_C1C8DF29 = {}

class NSXCatalystObjectsOperator

    # NSXCatalystObjectsOperator::catalystObjectWaterLevel()
    def self.catalystObjectWaterLevel()
        object = {}
        object["uuid"] = "0c1daadd-5759-4775-9b42-957bf9701506"
        object["agentuid"] = nil
        object["metric"] = 0.3
        object["announce"] = "-- water level --"
        object["commands"] = []
        object
    end

    # NSXCatalystObjectsOperator::getListingObjectsFromAgents()
    def self.getListingObjectsFromAgents()
        NSXBob::agents()
            .map{|agentinterface| agentinterface["get-objects"].call() }
            .flatten
    end

    # NSXCatalystObjectsOperator::getAllObjectsFromAgents()
    def self.getAllObjectsFromAgents()
        NSXBob::agents()
            .map{|agentinterface| agentinterface["get-objects-all"].call() }
            .flatten
    end

    # NSXCatalystObjectsOperator::updateInMemoryObjects()
    def self.updateInMemoryObjects()
        catalyst_in_memory_objects = {}
        NSXCatalystObjectsOperator::getCatalystListingObjectsFromAgents()
            .each{|object|
                catalyst_in_memory_objects[object["uuid"]] = object
            }
        $CATALYST_OBJECTS_C1C8DF29 = catalyst_in_memory_objects
    end

    # NSXCatalystObjectsOperator::getCatalystListingObjectsFromAgents()
    def self.getCatalystListingObjectsFromAgents()
        NSXCatalystObjectsOperator::getListingObjectsFromAgents()
            .reject{|object| NSXDoNotShowUntilDatetime::getFutureDatetimeOrNull(object['uuid']) }
            .map{|object| NSXOrdinals::ordinalTransform(object) }
            .select{|object| object['metric'] >= 0.2 }
    end

    # NSXCatalystObjectsOperator::getCatalystListingObjectsOrdered()
    def self.getCatalystListingObjectsOrdered()
        objects = NSXCatalystObjectsOperator::getCatalystListingObjectsFromAgents()
        objects = objects + [ NSXCatalystObjectsOperator::catalystObjectWaterLevel() ]
        objects
            .map{|object|
                ratio = NSXMiscUtils::metricWeightRatioOrNull(object["uuid"])
                object[":catalyst-weigth-ratio:"] = ratio
                if ratio then
                    object["metric"] = ratio*object["metric"]

                end
                object
            }
            .select{|object| object['metric'] >= 0.2 }
            .sort{|o1, o2| o1["metric"]<=>o2["metric"] }
            .reverse
    end

    # NSXCatalystObjectsOperator::notifyAllDoneObjects()
    def self.notifyAllDoneObjects()
        NSXCatalystObjectsOperator::getAllObjectsFromAgents()
        .each{|object|
            if object["isDone"] then
                sleep 2
                NSXMiscUtils::onScreenNotification("Catalyst", "[done] #{object["announce"]}")
            end
        }
    end

    # NSXCatalystObjectsOperator::processProcessingSignal(signal)
    def self.processProcessingSignal(signal)
        puts "signal: #{JSON.generate(signal)}"
        return if signal[0].nil?
        if signal[0] == "remove" then
            objectuuid = signal[1]
            $CATALYST_OBJECTS_C1C8DF29.delete(objectuuid)
        end
        if signal[0] == "update" then
            object = signal[1].clone
            $CATALYST_OBJECTS_C1C8DF29[object["uuid"]] = object
        end
    end
end
