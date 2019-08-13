
# encoding: UTF-8

require "/Galaxy/Software/Misc-Common/Ruby-Libraries/Torr.rb"
=begin
    Torr::event(repositorylocation, collectionuuid, mass)
    Torr::weight(repositorylocation, collectionuuid, stabililityPeriodInSeconds, simulationWeight = 0)
    Torr::metric(repositorylocation, collectionuuid, stabililityPeriodInSeconds, targetWeight, metricAtZero, metricAtTarget)
=end

class NSXCatalystObjectsOperator

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

    # NSXCatalystObjectsOperator::getCatalystListingObjectsOrdered()
    def self.getCatalystListingObjectsOrdered()
        objects = NSXCatalystObjectsOperator::getSomeObjectsFromAgents()
            .reject{|object| NSXDoNotShowUntilDatetime::getFutureDatetimeOrNull(object['uuid']) }

        objects = objects + NSXCatalystSpecialObjects::objects()

        objects = objects
            .select{|object| object['metric'] >= 0.2 }
            .sort{|o1, o2| o1["metric"]<=>o2["metric"] }
            .reverse

        # Now we remove any object after special object 1
        objects = objects.reduce([]) { |collection, object|
            if collection.any?{|o| o["uuid"] == "392eb09c-572b-481d-9e8e-894e9fa016d4-so1" } then
                collection
            else
                collection + [ object ]
            end
        }

        objects = objects
            .sort{|o1, o2| o1["metric"]<=>o2["metric"] }
            .reverse

        objects
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
