
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
            .map{|agentinterface| agentinterface["get-objects"].call() }
            .flatten
    end

    # NSXCatalystObjectsOperator::getAllObjectsFromAgents()
    def self.getAllObjectsFromAgents()
        NSXBob::agents()
            .map{|agentinterface| agentinterface["get-objects-all"].call() }
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
        scheduleStoreItemId = object["scheduleStoreItemId"]
        scheduleStoreItem = NSXScheduleStore::getItemOrNull(scheduleStoreItemId)
        object["decoration:metric"] = NSXScheduleStoreUtils::metric(scheduleStoreItemId)
        object["decoration:scheduleStoreItem"] = scheduleStoreItem
        object["decoration:defaultCommand"] = NSXScheduleStoreUtils::scheduleStoreItemToDefaultCommandOrNull(scheduleStoreItem)
        object["decoration:isRunning"] = NSXScheduleStoreUtils::isRunning(scheduleStoreItemId)
        object["decoration:RunTimesPoints"] = NSXRunTimes::getPoints(scheduleStoreItem["collectionuid"])
        object["decoration:metadata"] = NSXMetaDataStore::get(object["uuid"])
        object
    end

    # NSXCatalystObjectsOperator::getCatalystListingObjectsOrdered()
    def self.getCatalystListingObjectsOrdered()
        objects = NSXCatalystObjectsOperator::getListingObjectsFromAgents()

        objects = objects
            .map{|object| NSXCatalystObjectsOperator::addObjectDecorations(object) }

        objects = objects
            .reject{|object| 
                b1 = !NSXDoNotShowUntilDatetime::getFutureDatetimeOrNull(object['uuid']).nil? 
                b2 = !object["decoration:isRunning"]
                b1 and b2
            }

        if !NSXMiscUtils::hasInternetCondition1121() then
            objects = objects
                .reject{|object| 
                    b1 = NSXContentStoreUtils::contentStoreItemIdToAnnounceOrNull(object['contentStoreItemId']).include?("http") 
                    b2 = !object["decoration:isRunning"]
                    b1 and b2
                }
        end

        objects = objects
            .select{|object| object['decoration:metric'] >= 0.2 }
            .sort{|o1, o2| o1["decoration:metric"]<=>o2["decoration:metric"] }
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
            .sort{|o1, o2| o1["decoration:metric"]<=>o2["decoration:metric"] }
            .reverse

        objects.each{|object|
            KeyValueStore::set(nil, "86ecf8a5-ea95-4100-b4d4-03229d7f2c22:#{object["uuid"]}", object["agentuid"])
        }

        objects
    end

    # NSXCatalystObjectsOperator::screenNotificationsForAllDoneObjects()
    def self.screenNotificationsForAllDoneObjects()
        NSXCatalystObjectsOperator::getAllObjectsFromAgents()
        .each{|object|
            if object["isDone"] then
                sleep 2
                NSXMiscUtils::onScreenNotification("Catalyst", "[done] #{NSXContentStoreUtils::contentStoreItemIdToAnnounceOrNull(object['contentStoreItemId'])}")
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
