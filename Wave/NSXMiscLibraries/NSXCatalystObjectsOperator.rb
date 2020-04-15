
# encoding: UTF-8

require "/Users/pascal/Galaxy/LucilleOS/Software-Common/Ruby-Libraries/KeyValueStore.rb"
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
        # We have all the objects that the agents think should be done

        # Some of those objects might have been pushed to the future (something that happens outside the jurisdiction of the agents)
        # We remove those but we keep those that are running
        # Objects in the future which may be running have either
        # 1. Been incorrectly sent to the future while running
        # 2. Might have been started while being in the future after a search.
        objects = objects
            .select{|object|
                b1 = NSXDoNotShowUntilDatetime::getFutureDatetimeOrNull(object['uuid']).nil?
                b2 = object["isRunning"]
                b1 or b2
            }

        objects = objects
            .select{|object|
                b1 = object['metric'] >= 0.2
                b2 = object["isRunning"]
                b1 or b2
            }
            .sort{|o1, o2| o1["metric"]<=>o2["metric"] }
            .reverse

        objects.each{|object|
            next if object["agentuid"].nil?
            KeyValueStore::set(nil, "86ecf8a5-ea95-4100-b4d4-03229d7f2c22:#{object["uuid"]}", object["agentuid"])
        }

        loop {
            break if objects.empty?
            break if objects.size == 1
            break if objects[0]["contentItem"]["line"].nil?
            break if !objects[0]["contentItem"]["line"].include?('running: Wave')
            objects[0]["metric"] = objects[0]["metric"] - 0.01
            objects = objects
                .sort{|o1, o2| o1["metric"]<=>o2["metric"] }
                .reverse
        }

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
