#!/usr/bin/ruby

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

require 'digest/sha1'
# Digest::SHA1.hexdigest 'foo'
# Digest::SHA1.file(myFile).hexdigest

class NSXScheduleStore

    # NSXScheduleStore::getItemOrNull(scheduleStoreItemId: String): ContentStoreItem or null
    def self.getItemOrNull(scheduleStoreItemId)
        sha1hash = Digest::SHA1.hexdigest(scheduleStoreItemId)
        pathfragment = "#{sha1hash[0,2]}/#{sha1hash[2,2]}/#{sha1hash}.json"
        filepath = "#{CATALYST_COMMON_DATABANK_CATALYST_INSTANCE_FOLDERPATH}/Schedule-Store/Schedule/#{pathfragment}"
        if !File.exists?(filepath) then
            return nil
        end
        JSON.parse(IO.read(filepath))
    end

    # NSXScheduleStore::setItem(scheduleStoreItemId, scheduleStoreItem)
    def self.setItem(scheduleStoreItemId, scheduleStoreItem)
        sha1hash = Digest::SHA1.hexdigest(scheduleStoreItemId)
        pathfragment = "#{sha1hash[0,2]}/#{sha1hash[2,2]}/#{sha1hash}.json"
        filepath = "#{CATALYST_COMMON_DATABANK_CATALYST_INSTANCE_FOLDERPATH}/Schedule-Store/Schedule/#{pathfragment}"
        scheduleStoreItemAsString = JSON.generate(scheduleStoreItem)
        if File.exists?(filepath) and (IO.read(filepath) == scheduleStoreItemAsString) then
            # We avoid rewriting a file whose content have nove changed
            return
        end
        if !File.exists?(File.dirname(filepath)) then
            FileUtils.mkpath(File.dirname(filepath))
        end
        File.open(filepath, "w"){|f| f.write(scheduleStoreItemAsString) }
    end

end

class NSXScheduleStoreUtils

    # NSXScheduleStoreUtils::itemToAnnounce(item)
    def self.itemToAnnounce(item)

    end

    # NSXScheduleStoreUtils::scheduleStoreItemToCommands(objectuuid, scheduleStoreItem)
    def self.scheduleStoreItemToCommands(objectuuid, scheduleStoreItem)
        if scheduleStoreItem["type"] == "todo-and-inform-agent-11b30518" then
            return ["done"]
        end
        if scheduleStoreItem["type"] == "toactivate-and-inform-agent-2d839ef7" then
            return ["activate"]
        end
        if scheduleStoreItem["type"] == "24h-sliding-time-commitment-da8b7ca8" then
            return ["start", "stop", "done"]
        end
        if scheduleStoreItem["type"] == "stream-item-7e37790b" then
            return ["start", "stop", "done"]
        end
        if scheduleStoreItem["type"] == "wave-item-dc583ed2" then
            return ["done"]
        end
        raise "I do not know the commands for scheduleStoreItem: #{scheduleStoreItem}"
    end

    # NSXScheduleStoreUtils::scheduleStoreItemIdToAnnounceOrNull(scheduleStoreItemId)
    def self.scheduleStoreItemIdToAnnounceOrNull(scheduleStoreItemId)
        item = NSXScheduleStore::getItemOrNull(scheduleStoreItemId)
        return "NSXScheduleStoreUtils::scheduleStoreItemIdToAnnounceOrNull(#{scheduleStoreItemId})" if item.nil?
        NSXScheduleStoreUtils::itemToAnnounce(item)
    end

    # NSXScheduleStoreUtils::executeScheduleStoreItem(objectuuid, scheduleStoreItemId, command)
    def self.executeScheduleStoreItem(objectuuid, scheduleStoreItemId, command)
        puts "NSXScheduleStoreUtils::executeScheduleStoreItem(#{objectuuid}, #{scheduleStoreItemId}, #{command})"
        scheduleStoreItem = NSXScheduleStore::getItemOrNull(scheduleStoreItemId)
        return if scheduleStoreItem.nil?
        if scheduleStoreItem["type"] == "todo-and-inform-agent-11b30518" then
            # In this case it doesn't matter what the command is, we just forwards to the agent.
            # TODO: here we are calling the object to get the agent uid. We should have a shortcut here
            object = NSXCatalystObjectsOperator::getObjectIdentifiedByUUIDOrNull(objectuuid)
            return if object.nil?
            agentdata = NSXBob::getAgentDataByAgentUUIDOrNull(object["agentuid"])
            return if agentdata.nil?
            agentdata["object-command-processor"].call(objectuuid, command, true)
            return
        end
        if scheduleStoreItem["type"] == "toactivate-and-inform-agent-2d839ef7" then
            # In this case it doesn't matter what the command is, we just forwards to the agent.
            # TODO: here we are calling the object to get the agent uid. We should have a shortcut here
            object = NSXCatalystObjectsOperator::getObjectIdentifiedByUUIDOrNull(objectuuid)
            return if object.nil?
            agentdata = NSXBob::getAgentDataByAgentUUIDOrNull(object["agentuid"])
            return if agentdata.nil?
            agentdata["object-command-processor"].call(objectuuid, command, true)
            return
        end
        if scheduleStoreItem["type"] == "wave-item-dc583ed2" then
            object = NSXCatalystObjectsOperator::getObjectIdentifiedByUUIDOrNull(objectuuid)
            return if object.nil?
            agentdata = NSXBob::getAgentDataByAgentUUIDOrNull(object["agentuid"])
            return if agentdata.nil?
            agentdata["object-command-processor"].call(objectuuid, command, true)
            return
        end
        if scheduleStoreItem["type"] == "stream-item-7e37790b" then
            object = NSXCatalystObjectsOperator::getObjectIdentifiedByUUIDOrNull(objectuuid)
            return if object.nil?
            agentdata = NSXBob::getAgentDataByAgentUUIDOrNull(object["agentuid"])
            return if agentdata.nil?
            agentdata["object-command-processor"].call(objectuuid, command, true)
            return
        end
        puts "NSXScheduleStoreUtils::executeScheduleStoreItem cannot to this:"
        puts "objectuuid: #{objectuuid}"
        puts "scheduleStoreItem"
        puts JSON.pretty_generate(scheduleStoreItem)
        puts "command: #{command}"
        exit
    end
end