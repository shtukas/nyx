
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


    # NSXCatalystObjectsOperator::catalystObjectsForMainListing()
    def self.catalystObjectsForMainListing()
        objects = NSXCatalystObjectsOperator::getObjects()
        objects = objects
                    .map{|object| 
                        if NSXRunner::isRunning?(object["uuid"]) then 
                            object["prioritization"] = "running"
                            object 
                        else
                            if NSXDoNotShowUntilDatetime::getFutureDatetimeOrNull(object['uuid']).nil? then
                                object
                            else
                                nil
                            end
                        end
                    }
                    .compact
        objects = objects
                    .map{|object| 
                        object["catalyst:placement"] = NSXPlacement::getValue(object["uuid"]) 
                        object
                    }
        NSXPlacement::clean(objects.map{|object| object["uuid"] })
        objects = objects
                    .sort{|o1, o2| o1["catalyst:placement"] <=> o2["catalyst:placement"] }
                    .reverse
        objects
    end

end
