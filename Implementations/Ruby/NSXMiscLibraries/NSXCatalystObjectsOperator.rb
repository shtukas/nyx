
# encoding: UTF-8

require "/Users/pascal/Galaxy/Software/Misc-Common/Ruby-Libraries/KeyValueStore.rb"
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
    end

    # NSXCatalystObjectsOperator::getAllObjectsFromAgents()
    def self.getAllObjectsFromAgents()
        NSXBob::agents()
            .map{|agentinterface| Object.const_get(agentinterface["agent-name"]).send("getAllObjects") }
            .flatten
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
                    b1 = !NSX1ContentsItemUtils::contentItemToAnnounce(object['contentItem']).include?("http") 
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

        objects = objects
            .sort{|o1, o2| o1["metric"]<=>o2["metric"] }
            .reverse

        objects.each{|object|
            KeyValueStore::set(nil, "86ecf8a5-ea95-4100-b4d4-03229d7f2c22:#{object["uuid"]}", object["agentuid"])
        }

        if objects.empty? then
            return NSXStreamsUtils::getAllStreamItemsCatalystObjectsChaseMode()
        end

        objects
    end

    # NSXCatalystObjectsOperator::screenNotificationsForAllDoneObjects()
    def self.screenNotificationsForAllDoneObjects()
        NSXCatalystObjectsOperator::getAllObjectsFromAgents()
        .each{|object|
            if object["isRunning"] and object["isDone"] then
                sleep 2
                NSXMiscUtils::onScreenNotification("Catalyst", "done: #{NSX1ContentsItemUtils::contentItemToAnnounce(object['contentItem'])}")
            end
        }
    end
end
