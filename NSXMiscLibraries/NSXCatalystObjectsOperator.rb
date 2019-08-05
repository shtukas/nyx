
# encoding: UTF-8

require "/Galaxy/Software/Misc-Common/Ruby-Libraries/Torr.rb"
=begin
    Torr::event(repositorylocation, collectionuuid, mass)
    Torr::weight(repositorylocation, collectionuuid, stabililityPeriodInSeconds, simulationWeight = 0)
    Torr::metric(repositorylocation, collectionuuid, stabililityPeriodInSeconds, targetWeight, metricAtZero, metricAtTarget)
=end

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

    # NSXCatalystObjectsOperator::getSomeObjectsFromAgents()
    def self.getSomeObjectsFromAgents()
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

    # NSXCatalystObjectsOperator::getCatalystListingObjects()
    def self.getCatalystListingObjects()
        NSXCatalystObjectsOperator::getSomeObjectsFromAgents()
            .reject{|object| NSXDoNotShowUntilDatetime::getFutureDatetimeOrNull(object['uuid']) }
            .select{|object| object['metric'] >= 0.2 }
    end

    # NSXCatalystObjectsOperator::getCatalystListingObjectsOrdered()
    def self.getCatalystListingObjectsOrdered()
        objects = NSXCatalystObjectsOperator::getCatalystListingObjects()
        objects = objects + [ NSXCatalystObjectsOperator::catalystObjectWaterLevel() ]
        objects
            .map{|object|
                multiplier = NSXMiscUtils::objectMetricMultiplierOrNull(object)
                if multiplier then
                    object[":catalyst-weigth-multiplier:metric-before-adjustement"] = object["metric"]
                    object[":catalyst-weigth-multiplier:multiplier"] = multiplier
                    object["metric"] = multiplier*object["metric"]
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
end
