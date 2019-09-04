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
        "NSXScheduleStoreUtils::itemToAnnounce"
    end

    # NSXScheduleStoreUtils::scheduleStoreItemIdToAnnounceOrNull(scheduleStoreItemId)
    def self.scheduleStoreItemIdToAnnounceOrNull(scheduleStoreItemId)
        item = NSXScheduleStore::getItemOrNull(scheduleStoreItemId)
        return "NSXScheduleStoreUtils::scheduleStoreItemIdToAnnounceOrNull(#{scheduleStoreItemId})" if item.nil?
        NSXScheduleStoreUtils::itemToAnnounce(item)
    end

    # NSXScheduleStoreUtils::scheduleStoreItemToCommands(scheduleStoreItem)
    def self.scheduleStoreItemToCommands(scheduleStoreItem)
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
        raise "[error: 748abbe9] I do not know the commands for scheduleStoreItem: #{scheduleStoreItem}"
    end

    # NSXScheduleStoreUtils::scheduleStoreItemToDefaultCommandOrNull(scheduleStoreItem)
    def self.scheduleStoreItemToDefaultCommandOrNull(scheduleStoreItem)
        if scheduleStoreItem["type"] == "wave-item-dc583ed2" then
            if scheduleStoreItem["wave-schedule"]["@"] == "sticky" then
                return "done"
            end
        end
        nil
    end

    # NSXScheduleStoreUtils::executeScheduleStoreItem(objectuuid, scheduleStoreItemId, command)
    def self.executeScheduleStoreItem(objectuuid, scheduleStoreItemId, command)
        scheduleStoreItem = NSXScheduleStore::getItemOrNull(scheduleStoreItemId)
        return if scheduleStoreItem.nil?
        if scheduleStoreItem["type"] == "todo-and-inform-agent-11b30518" then
            return false
        end
        if scheduleStoreItem["type"] == "toactivate-and-inform-agent-2d839ef7" then
            return false
        end
        if scheduleStoreItem["type"] == "wave-item-dc583ed2" then
            return false
        end
        if scheduleStoreItem["type"] == "stream-item-7e37790b" then
            if command == "start" then
                puts "error 1311"
                exit
                return true
            end
            if command == "stop" then
                puts "error 1312"
                exit
                return true
            end
            # We let the agent perform "done"
            return false
        end
        false
    end

    # NSXScheduleStoreUtils::metric(scheduleStoreItemId)
    def self.metric(scheduleStoreItemId)
        scheduleStoreItem = NSXScheduleStore::getItemOrNull(scheduleStoreItemId)
        if scheduleStoreItem.nil? then
            raise "Error: c27092edd0a3 (attemtping to compute metric of an unknown scheduleStoreItem)"
        end
        if scheduleStoreItem["type"] == "todo-and-inform-agent-11b30518" then
            return scheduleStoreItem["metric"]
        end
        if scheduleStoreItem["type"] == "toactivate-and-inform-agent-2d839ef7" then
            return scheduleStoreItem["metric"]
        end
        if scheduleStoreItem["type"] == "24h-sliding-time-commitment-da8b7ca8" then
            collectionuid = scheduleStoreItem["collectionuid"]
            ordinal = scheduleStoreItem["ordinal"]
            points = NSXRunTimes::getPoints(collectionuid)
            targetTimeInSeconds = scheduleStoreItem["commitmentInHours"]*3600
            stabilityPeriodInSeconds = scheduleStoreItem["stabilityPeriodInSeconds"]
            metricAtZero = scheduleStoreItem["metricAtZero"]
            metricAtTarget = scheduleStoreItem["metricAtTarget"]
            return NSXRunTimes::metric1(points, targetTimeInSeconds, stabilityPeriodInSeconds, metricAtZero, metricAtTarget) + Math.exp(-ordinal.to_f/100).to_f/100
        end
        if scheduleStoreItem["type"] == "stream-item-7e37790b" then
            collectionuid = scheduleStoreItem["collectionuid"]
            points = NSXRunTimes::getPoints(collectionuid)
            targetTimeInSeconds = scheduleStoreItem["commitmentInHours"]*3600
            stabilityPeriodInSeconds = scheduleStoreItem["stabilityPeriodInSeconds"]
            metricAtZero = scheduleStoreItem["metricAtZero"]
            metricAtTarget = scheduleStoreItem["metricAtTarget"]
            return NSXRunTimes::metric1(points, targetTimeInSeconds, stabilityPeriodInSeconds, metricAtZero, metricAtTarget)
        end
        if scheduleStoreItem["type"] == "wave-item-dc583ed2" then
            return WaveSchedules::scheduleToMetric(scheduleStoreItem["wave-schedule"]) + NSXMiscUtils::traceToMetricShift(Digest::SHA1.hexdigest(scheduleStoreItemId)) 
        end
        raise "[error: 15833148] I do not know compute metric for scheduleStoreItem: #{scheduleStoreItem}"
    end

end