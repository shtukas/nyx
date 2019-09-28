#!/usr/bin/ruby

# encoding: UTF-8
require 'json'

require 'fileutils'

require 'drb/drb'

require "/Galaxy/Software/Misc-Common/Ruby-Libraries/LucilleCore.rb"

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

# -----------------------------------------------------------------

XSPACE_VIDEO_REPOSITORY_FOLDERPATH = "/x-space/YouTube Videos"

ENERGYGRID_VIDEO_REPOSITORY_FOLDERPATH = "/Volumes/EnergyGrid/Data/Pascal/YouTube Videos"

class NSXAgentVideosStreamConsumptionMonitorHelper
    # NSXAgentVideosStreamConsumptionMonitorHelper::getHits()
    def self.getHits()
        JSON.parse(KeyValueStore::getOrDefaultValue(nil, "9c88426d-00c0-497c-a7f5-9fa2e042bdd7:#{NSXMiscUtils::currentDay()}", "[]"))
            .select{|x| (Time.new.to_i - x) < 86400 }
    end

    # NSXAgentVideosStreamConsumptionMonitorHelper::registerHit()
    def self.registerHit()
        a = NSXAgentVideosStreamConsumptionMonitorHelper::getHits()
        a << Time.new.to_i
        KeyValueStore::set(nil, "9c88426d-00c0-497c-a7f5-9fa2e042bdd7:#{NSXMiscUtils::currentDay()}", JSON.generate(a))
    end

    # NSXAgentVideosStreamConsumptionMonitorHelper::metric()
    def self.metric()
        Math.exp(-NSXAgentVideosStreamConsumptionMonitorHelper::getHits().count.to_f/20)
    end
end

class NSXAgentVideosStreamConsumptionMonitor

    # NSXAgentVideosStreamConsumptionMonitor::agentuid()
    def self.agentuid()
        "a3b9934f-4b01-4fca-80a3-63eb2a521df0"
    end

    # NSXAgentVideosStreamConsumptionMonitor::getObjects()
    def self.getObjects()
        NSXAgentVideosStreamConsumptionMonitor::getAllObjects()
    end

    def self.videoFolderpathsAtFolder(folderpath)
        return [] if !File.exists?(folderpath)
        Dir.entries(folderpath)
            .select{|filename| filename[0,1] != "." }
            .map{|filename| "#{folderpath}/#{filename}" }
            .sort
    end

    # NSXAgentVideosStreamConsumptionMonitor::getAllObjects()
    def self.getAllObjects()
        loop {
            break if NSXAgentVideosStreamConsumptionMonitor::videoFolderpathsAtFolder(XSPACE_VIDEO_REPOSITORY_FOLDERPATH).size >= 200
            break if NSXAgentVideosStreamConsumptionMonitor::videoFolderpathsAtFolder(ENERGYGRID_VIDEO_REPOSITORY_FOLDERPATH).size == 0
            filepath = NSXAgentVideosStreamConsumptionMonitor::videoFolderpathsAtFolder(ENERGYGRID_VIDEO_REPOSITORY_FOLDERPATH).first
            filename = File.basename(filepath)
            targetFilepath = "#{XSPACE_VIDEO_REPOSITORY_FOLDERPATH}/#{filename}"
            FileUtils.mv(filepath, targetFilepath)
            break if !File.exists?(targetFilepath)
        }
        filepath = NSXAgentVideosStreamConsumptionMonitor::videoFolderpathsAtFolder(XSPACE_VIDEO_REPOSITORY_FOLDERPATH).first
        return [] if filepath.nil?
        uuid = "f7845869-e058-44cd-bfae-3412957c7dba"
        announce = "YouTube Video Stream"
        contentItem = {
            "type" => "line",
            "line" => announce
        }
        [
            {
                "uuid"                => uuid,
                "agentuid"            => NSXAgentVideosStreamConsumptionMonitor::agentuid(),
                "contentItem"         => contentItem,
                "metric"              => NSXAgentVideosStreamConsumptionMonitorHelper::metric(),
                "commands"            => ["activate"],
                "defaultCommand"      => "activate",
                "agent:meta:filepath" => filepath
            }
        ]
    end

    # NSXAgentVideosStreamConsumptionMonitor::processObjectAndCommand(objectuuid, command, isLocalCommand)
    def self.processObjectAndCommand(objectuuid, command, isLocalCommand)
        if command == "activate" then
            filepath = videoFolderpathsAtFolder(XSPACE_VIDEO_REPOSITORY_FOLDERPATH).first
            return if filepath.nil?
            puts filepath
            if filepath.include?("'") then
                filepath2 = filepath.gsub("'", ',')
                FileUtils.mv(filepath, filepath2)
                filepath = filepath2
            end
            system("open '#{filepath}'")
            LucilleCore::pressEnterToContinue()
            FileUtils.rm(filepath)
            NSXAgentVideosStreamConsumptionMonitorHelper::registerHit()
            return 
        end
    end
end


