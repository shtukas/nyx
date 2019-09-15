#!/usr/bin/ruby

# encoding: UTF-8
require "/Galaxy/Software/Misc-Common/Ruby-Libraries/LucilleCore.rb"
require 'securerandom'
# SecureRandom.hex    #=> "eb693ec8252cd630102fd0d0fb7c3485"
# SecureRandom.hex(4) #=> "eb693123"
# SecureRandom.uuid   #=> "2d931510-d99f-494a-8c67-87feb05e1594"
require "time"

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

# -------------------------------------------------------------------------------------

class NSXAgentStreams

    # NSXAgentStreams::agentuid()
    def self.agentuid()
        "d2de3f8e-6cf2-46f6-b122-58b60b2a96f1"
    end

    # NSXAgentStreams::getObjects()
    def self.getObjects()
        NSXStreamsUtils::getCatalystObjectsForDisplay()
    end

    # NSXAgentStreams::getAllObjects()
    def self.getAllObjects()
        NSXStreamsUtils::getAllCatalystObjects()
    end

    def self.getCommands()
        ["open", "folder", "done", "recast", "push"]
    end

    # NSXAgentStreams::processObjectAndCommand(objectuuid, command, isLocalCommand)
    def self.processObjectAndCommand(objectuuid, command, isLocalCommand)
        item = NSXStreamsUtils::getItemByUUIDOrNull(objectuuid)
        return if item.nil?
        if command == "open" then
            genericContentItem = NSXGenericContents::viewGenericContentItemReturnUpdatedItemOrNull(item["generic-content-item"])
            if genericContentItem then
                item["generic-content-item"] = genericContentItem
                NSXStreamsUtils::commitItemToDisk(item)
            end
            return
        end
        if command == "folder" then
            folderpath = NSXGenericContents::resolveFoldernameToFolderpathOrNull(item["generic-content-item"]["parent-foldername"])
            return if folderpath.nil?
            system("open '#{folderpath}'")
            return
        end
        if command == "done" then
            NSXStreamsUtils::destroyItem(item)
            if isLocalCommand then
                NSXMultiInstancesWrite::sendEventToDisk({
                    "instanceName" => NSXMiscUtils::instanceName(),
                    "eventType"    => "MultiInstanceEventType:CatalystObjectUUID+Command",
                    "payload"      => {
                        "objectuuid" => objectuuid,
                        "command"    => "done"
                    }
                })
            end
            nsx1309_removeItemIdentifiedById(item["uuid"])
            return
        end
        if command == "recast" then
            item = NSXStreamsUtils::recastStreamItem(item)
            NSXStreamsUtils::commitItemToDisk(item)
            nsx1309_removeItemIdentifiedById(item["uuid"])
            return
        end
        if command == "push" then
            options = [
                "put to position 6 on stream",
                "put to end of stream"
            ]
            option = LucilleCore::selectEntityFromListOfEntitiesOrNull("option", options)
            if option == "put to position 6 on stream" then
                item["ordinal"] = NSXStreamsUtils::newPositionNOrdinalForStreamItem(item["streamuuid"], 6, item["uuid"])
                NSXStreamsUtils::commitItemToDisk(item)
            end
            if option == "put to end of stream" then
                item["ordinal"] = NSXMiscUtils::makeEndOfQueueStreamItemOrdinal()
                NSXStreamsUtils::commitItemToDisk(item)
            end
            nsx1309_removeItemIdentifiedById(item["uuid"])
            return
        end
    end
end
