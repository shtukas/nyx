
# encoding: UTF-8

require "/Galaxy/Software/Misc-Common/Ruby-Libraries/KeyValueStore.rb"
=begin
    KeyValueStore::setFlagTrue(repositorylocation or nil, key)
    KeyValueStore::setFlagFalse(repositorylocation or nil, key)
    KeyValueStore::flagIsTrue(repositorylocation or nil, key)

    KeyValueStore::set(repositorylocation or nil, key, value)
    KeyValueStore::getOrNull(repositorylocation or nil, key)
    KeyValueStore::getOrDefaultValue(repositorylocation or nil, key, defaultValue)
    KeyValueStore::destroy(repositorylocation or nil, key)
=end

class NSXCatalystObjectsOperator

    # NSXCatalystObjectsOperator::getListingObjectsFromAgents()
    def self.getListingObjectsFromAgents()
        NSXBob::agents()
            .map{|agentinterface| Object.const_get(agentinterface["agent-name"]).send("getObjects") }
            .flatten
            .map{|object| NSXCatalystObjectsOperator::addObjectDecorations(object) }
    end


    # NSXCatalystObjectsOperator::getAllObjectsFromAgents()
    def self.getAllObjectsFromAgents()
        NSXBob::agents()
            .map{|agentinterface| Object.const_get(agentinterface["agent-name"]).send("getAllObjects") }
            .flatten
            .map{|object| NSXCatalystObjectsOperator::addObjectDecorations(object) }
    end

    # NSXCatalystObjectsOperator::getObjectIdentifiedByUUIDOrNull(uuid)
    def self.getObjectIdentifiedByUUIDOrNull(uuid)
        NSXCatalystObjectsOperator::getAllObjectsFromAgents()
            .select{|object| object["uuid"] == uuid }
            .first
    end

    # NSXCatalystObjectsOperator::getAgentUUIDByObjectUUIDOrNull(objectuuid)
    def self.getAgentUUIDByObjectUUIDOrNull(objectuuid)
        agentuid = KeyValueStore::getOrNull(nil, "86ecf8a5-ea95-4100-b4d4-03229d7f2c22:#{objectuuid}")
        return agentuid if agentuid
        object = NSXCatalystObjectsOperator::getObjectIdentifiedByUUIDOrNull(objectuuid)
        return nil if object.nil?
        KeyValueStore::set(nil, "86ecf8a5-ea95-4100-b4d4-03229d7f2c22:#{objectuuid}", object["agentuid"])
        object["agentuid"]
    end

    # NSXCatalystObjectsOperator::addObjectDecorations(object)
    def self.addObjectDecorations(object)
        object["decoration:metadata"] = NSXMetaDataStore::get(object["uuid"])
        object
    end

    # NSXCatalystObjectsOperator::getCatalystListingObjectsOrdered()
    def self.getCatalystListingObjectsOrdered()
        objects = NSXCatalystObjectsOperator::getListingObjectsFromAgents()

        objects = objects
            .select{|object|
                b1 = NSXDoNotShowUntilDatetime::getFutureDatetimeOrNull(object['uuid']).nil?
                b2 = object["isRunning"]
                b1 or b2
            }

        if !NSXMiscUtils::hasInternetCondition1121() then
            objects = objects
                .select{|object|
                    b1 = !NSXContentUtils::itemToAnnounce(object['contentItem']).include?("http") 
                    b2 = object["isRunning"]
                    b1 or b2
                }
        end

        objects = objects
            .select{|object|
                b1 = object['metric'] >= 0.2
                b2 = object["isRunning"]
                b1 or b2
            }
            .sort{|o1, o2| o1["metric"]<=>o2["metric"] }
            .reverse

        # Now we remove any object after special object 1
        objects = objects.reduce([]) { |collection, object|
            if collection.any?{|o| o["uuid"] == "392eb09c-572b-481d-9e8e-894e9fa016d4-so1" } and !object["isRunning"] then
                collection
            else
                collection + [ object ]
            end
        }

        objects = objects
            .sort{|o1, o2| o1["metric"]<=>o2["metric"] }
            .reverse

        objects.each{|object|
            KeyValueStore::set(nil, "86ecf8a5-ea95-4100-b4d4-03229d7f2c22:#{object["uuid"]}", object["agentuid"])
        }

        if objects.empty? then
            return NSXStreamsUtils::getAllCatalystObjectsChaseMode()
        end

        objects
    end

    # NSXCatalystObjectsOperator::screenNotificationsForAllDoneObjects()
    def self.screenNotificationsForAllDoneObjects()
        NSXCatalystObjectsOperator::getAllObjectsFromAgents()
        .each{|object|
            if object["isDone"] then
                sleep 2
                NSXMiscUtils::onScreenNotification("Catalyst", "[done] #{NSXContentUtils::itemToAnnounce(object['contentItem'])}")
            end
        }
    end

    # NSXCatalystObjectsOperator::screenNotificationsForOmega1Condition()
    def self.screenNotificationsForOmega1Condition()
        objects = NSXCatalystObjectsOperator::getCatalystListingObjectsOrdered()
        return if objects.empty?
        return if objects.none?{|object| object["uuid"] == "392eb09c-572b-481d-9e8e-894e9fa016d4-so1" }
        return if objects.first["uuid"] == "392eb09c-572b-481d-9e8e-894e9fa016d4-so1"
        NSXMiscUtils::onScreenNotification("Catalyst", "Objects above Daily Guardian Work")
    end
end
