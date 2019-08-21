#!/usr/bin/ruby

# encoding: UTF-8
require 'json'

require 'fileutils'

require 'drb/drb'

require "/Galaxy/Software/Misc-Common/Ruby-Libraries/Torr.rb"
=begin
    Torr::event(repositorylocation, collectionuuid, mass)
    Torr::weight(repositorylocation, collectionuuid, stabililityPeriodInSeconds)
    Torr::metric(repositorylocation, collectionuuid, stabililityPeriodInSeconds, targetWeight, metricAtZero, metricAtTarget)
=end

require "/Galaxy/Software/Misc-Common/Ruby-Libraries/LucilleCore.rb"

# -----------------------------------------------------------------

XSPACE_VIDEO_REPOSITORY_FOLDERPATH = "/x-space/YouTube Videos"

ENERGYGRID_VIDEO_REPOSITORY_FOLDERPATH = "/Volumes/EnergyGrid/Data/Pascal/YouTube Videos"

class NSXAgentVideosStreamConsumptionMonitor

    # NSXAgentVideosStreamConsumptionMonitor::agentuuid()
    def self.agentuuid()
        "6e02cc3f-5342-46b8-b98c-7865b7e163f1"
    end

    # NSXAgentVideosStreamConsumptionMonitor::getObjects()
    def self.getObjects()
        []
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
        [
            {
                "uuid"               => "f7845869-e058-44cd-bfae-3412957c7db9",
                "agentuid"           => "9fad55cf-3f41-45ae-b480-5cbef40ce57f",
                "metric"             => Torr::metric("/Galaxy/DataBank/Catalyst/Agents-Data/TheBridge/Data/videos-stream-consumption", "d1dc93db-baac-440f-bc61-e069092427f6", 86400, 20, 0.53, 0.51),
                "announce"           => "videos stream consumption [day target 15]",
                "commands"           => ["view"],
                "defaultCommand"     => nil,
                ":meta:weight"       => Torr::weight("/Galaxy/DataBank/Catalyst/Agents-Data/TheBridge/Data/videos-stream-consumption", "d1dc93db-baac-440f-bc61-e069092427f6", 86400)
            }
        ]
    end

    # NSXAgentVideosStreamConsumptionMonitor::processObjectAndCommand(object, command)
    def self.processObjectAndCommand(object, command)
        if command == "view" then
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
            Torr::event("/Galaxy/DataBank/Catalyst/Agents-Data/TheBridge/Data/videos-stream-consumption", "d1dc93db-baac-440f-bc61-e069092427f6", 1)
            return 
        end
    end
end


