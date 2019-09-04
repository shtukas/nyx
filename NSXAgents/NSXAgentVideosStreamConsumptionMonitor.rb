#!/usr/bin/ruby

# encoding: UTF-8
require 'json'

require 'fileutils'

require 'drb/drb'

require "/Galaxy/Software/Misc-Common/Ruby-Libraries/LucilleCore.rb"

# -----------------------------------------------------------------

XSPACE_VIDEO_REPOSITORY_FOLDERPATH = "/x-space/YouTube Videos"

ENERGYGRID_VIDEO_REPOSITORY_FOLDERPATH = "/Volumes/EnergyGrid/Data/Pascal/YouTube Videos"

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
        contentStoreItem = {
            "type" => "line",
            "line" => announce
        }
        NSXContentStore::setItem(uuid, contentStoreItem)
        scheduleStoreItem = {
            "type" => "toactivate-and-inform-agent-2d839ef7",
            "metric" => 0.5
        }
        NSXScheduleStore::setItem(uuid, scheduleStoreItem)
        [
            {
                "uuid"               => uuid,
                "agentuid"           => NSXAgentVideosStreamConsumptionMonitor::agentuid(),
                "contentStoreItemId"  => uuid,
                "scheduleStoreItemId" => uuid,
                "agent:meta:filepath" => filepath
            }
        ]
    end

    def self.getCommands()
        []
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
            return 
        end
    end
end


