#!/usr/bin/ruby

# encoding: UTF-8
require 'json'

require 'fileutils'

require 'drb/drb'

require "/Users/pascal/Galaxy/Software/Misc-Common/Ruby-Libraries/LucilleCore.rb"

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

# -----------------------------------------------------------------

XSPACE_VIDEO_REPOSITORY_FOLDERPATH = "/Users/pascal/x-space/YouTube Videos"

ENERGYGRID_VIDEO_REPOSITORY_FOLDERPATH = "/Volumes/EnergyGrid/Data/Pascal/YouTube Videos"

class NSXAgentVideosStreamConsumptionMonitorHelper

    # NSXAgentVideosStreamConsumptionMonitorHelper::registerHit()
    def self.registerHit()
        NSXRunTimes::addPoint("7766a7ae-01ff-42f4-84e4-5c27f939f4d7", Time.new.to_i, 0)
    end

    # NSXAgentVideosStreamConsumptionMonitorHelper::metric()
    def self.metric()
        points = NSXRunTimes::getPoints("7766a7ae-01ff-42f4-84e4-5c27f939f4d7")
        targetCount = 15
        periodInSeconds = 86400
        metricAtZero = 0.8
        metricAtTarget = 0.5
        NSXRunMetrics3::metric(points, targetCount, periodInSeconds, metricAtZero, metricAtTarget)
    end

    # NSXAgentVideosStreamConsumptionMonitorHelper::videoFolderpathsAtFolder(folderpath)
    def self.videoFolderpathsAtFolder(folderpath)
        return [] if !File.exists?(folderpath)
        Dir.entries(folderpath)
            .select{|filename| filename[0,1] != "." }
            .map{|filename| "#{folderpath}/#{filename}" }
            .sort
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

    # NSXAgentVideosStreamConsumptionMonitor::getAllObjects()
    def self.getAllObjects()
        loop {
            break if NSXAgentVideosStreamConsumptionMonitorHelper::videoFolderpathsAtFolder(XSPACE_VIDEO_REPOSITORY_FOLDERPATH).size >= 200
            break if NSXAgentVideosStreamConsumptionMonitorHelper::videoFolderpathsAtFolder(ENERGYGRID_VIDEO_REPOSITORY_FOLDERPATH).size == 0
            filepath = NSXAgentVideosStreamConsumptionMonitorHelper::videoFolderpathsAtFolder(ENERGYGRID_VIDEO_REPOSITORY_FOLDERPATH).first
            filename = File.basename(filepath)
            targetFilepath = "#{XSPACE_VIDEO_REPOSITORY_FOLDERPATH}/#{filename}"
            FileUtils.mv(filepath, targetFilepath)
            break if !File.exists?(targetFilepath)
        }
        filepath = NSXAgentVideosStreamConsumptionMonitorHelper::videoFolderpathsAtFolder(XSPACE_VIDEO_REPOSITORY_FOLDERPATH).first
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

    # NSXAgentVideosStreamConsumptionMonitor::processObjectAndCommand(objectuuid, command)
    def self.processObjectAndCommand(objectuuid, command)
        if command == "activate" then
            loop {
                filepath = NSXAgentVideosStreamConsumptionMonitorHelper::videoFolderpathsAtFolder(XSPACE_VIDEO_REPOSITORY_FOLDERPATH).first
                break if filepath.nil?
                puts filepath
                if filepath.include?("'") then
                    filepath2 = filepath.gsub("'", ',')
                    FileUtils.mv(filepath, filepath2)
                    filepath = filepath2
                end
                system("open '#{filepath}'")
                shouldContinue = LucilleCore::askQuestionAnswerAsBoolean("Continue ? : ")
                FileUtils.rm(filepath)
                NSXAgentVideosStreamConsumptionMonitorHelper::registerHit()
                break if !shouldContinue
            }
            return 
        end
    end
end

begin
    NSXBob::registerAgent(
        {
            "agent-name"  => "NSXAgentVideosStreamConsumptionMonitor",
            "agentuid"    => NSXAgentVideosStreamConsumptionMonitor::agentuid(),
        }
    )
rescue
end

