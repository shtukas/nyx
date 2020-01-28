#!/usr/bin/ruby

# encoding: UTF-8
require "/Users/pascal/Galaxy/2020-LucilleOS/Software-Common/Ruby-Libraries/LucilleCore.rb"
require 'securerandom'
# SecureRandom.hex    #=> "eb693ec8252cd630102fd0d0fb7c3485"
# SecureRandom.hex(4) #=> "eb693123"
# SecureRandom.uuid   #=> "2d931510-d99f-494a-8c67-87feb05e1594"
require "time"

# -------------------------------------------------------------------------------------

class NSXAgentInfinityStream

    # NSXAgentInfinityStream::agentuid()
    def self.agentuid()
        "7afde9c0-4bfd-4773-b6a5-62bd4ec25738"
    end

    # NSXAgentInfinityStream::getObjects()
    def self.getObjects()
        if $STREAM_ITEMS_IN_MEMORY_4B4BFE22.nil? or $STREAM_ITEMS_IN_MEMORY_4B4BFE22.empty? then
            $STREAM_ITEMS_IN_MEMORY_4B4BFE22 = NSXStreamsUtils::getSelectionOfStreamItems()
        end
        $STREAM_ITEMS_IN_MEMORY_4B4BFE22.map{|item| NSXStreamsUtils::streamItemToCatalystObject(item) }
    end

    # NSXAgentInfinityStream::getAllObjects()
    def self.getAllObjects()
        NSXStreamsUtils::getStreamItems()
            .map{|item| NSXStreamsUtils::streamItemToCatalystObject(item) }
    end

    # NSXAgentInfinityStream::processObjectAndCommand(objectuuid, command)
    def self.processObjectAndCommand(objectuuid, command)
        item = NSXStreamsUtils::getStreamItemByUUIDOrNull(objectuuid)
        return if item.nil?
        if command == "open" then
            genericContent = NSX2GenericContentUtils::viewGenericContentItemReturnUpdatedItemOrNull(item["generic-content"])
            if genericContent then
                item["generic-content"] = genericContent
                NSXStreamsUtils::commitItemToDisk(item)
            end
            return
        end
        if command == "done" then
            NSXStreamsUtils::destroyItem(item)
            nsx1309_removeItemIdentifiedById(item["uuid"])
            return
        end
        if command == "recast" then
            item = NSXStreamsUtils::recastStreamItem(item)
            NSXStreamsUtils::commitItemToDisk(item)
            nsx1309_removeItemIdentifiedById(item["uuid"])
            return
        end
        if command == "folder" then
            folderpath = NSX2GenericContentUtils::resolveFoldernameToFolderpathOrNull(item["generic-content"]["parent-foldername"])
            return if folderpath.nil?
            system("open '#{folderpath}'")
            return
        end
    end
end

begin
    NSXBob::registerAgent(
        {
            "agent-name"  => "NSXAgentInfinityStream",
            "agentuid"    => NSXAgentInfinityStream::agentuid(),
        }
    )
rescue
end
