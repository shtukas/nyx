
# encoding: UTF-8
require 'json'

require 'fileutils'

require "/Users/pascal/Galaxy/LucilleOS/Software-Common/Ruby-Libraries/LucilleCore.rb"

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

# -----------------------------------------------------------------

XSPACE_VIDEO_REPOSITORY_FOLDERPATH = "/Users/pascal/x-space/YouTube Videos"

ENERGYGRID_VIDEO_REPOSITORY_FOLDERPATH = "/Volumes/EnergyGrid/Data/Pascal/Galaxy/YouTube Videos"

class NSXAgentVideosStreamConsumptionMonitor

    # NSXAgentVideosStreamConsumptionMonitor::registerHit()
    def self.registerHit()
        points = KeyValueStore::getOrDefaultValue(nil, "7766a7ae-11ff-42f4-84e4-5c27f939f4d8:#{Time.new.to_s[0, 10]}", "[]")
        points = JSON.parse(points)
        points << Time.new.to_i
        KeyValueStore::set(nil, "7766a7ae-11ff-42f4-84e4-5c27f939f4d8:#{Time.new.to_s[0, 10]}", JSON.generate(points))
    end

    # NSXAgentVideosStreamConsumptionMonitor::metric()
    def self.metric()
        points = KeyValueStore::getOrDefaultValue(nil, "7766a7ae-11ff-42f4-84e4-5c27f939f4d8:#{Time.new.to_s[0, 10]}", "[]")
        points = JSON.parse(points)
        return 0.8 if points.empty?
        n = points.select{|point| (Time.new.to_i-point) < 3600*2 }.count
        0.8*Math.exp(-n.to_f/6)
    end

    # NSXAgentVideosStreamConsumptionMonitor::videoFolderpathsAtFolder(folderpath)
    def self.videoFolderpathsAtFolder(folderpath)
        return [] if !File.exists?(folderpath)
        Dir.entries(folderpath)
            .select{|filename| filename[0,1] != "." }
            .map{|filename| "#{folderpath}/#{filename}" }
            .sort
    end

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
        return [] if !NSXMiscUtils::isLucille18()
        loop {
            break if NSXAgentVideosStreamConsumptionMonitor::videoFolderpathsAtFolder(XSPACE_VIDEO_REPOSITORY_FOLDERPATH).size >= 40
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
                "metric"              => NSXAgentVideosStreamConsumptionMonitor::metric(),
                "commands"            => [],
                "defaultCommand"      => "view",
                "agent:meta:filepath" => filepath
            }
        ]
    end

    # NSXAgentVideosStreamConsumptionMonitor::processObjectAndCommand(objectuuid, command)
    def self.processObjectAndCommand(objectuuid, command)
        if command == "view" then
            filepath = NSXAgentVideosStreamConsumptionMonitor::videoFolderpathsAtFolder(XSPACE_VIDEO_REPOSITORY_FOLDERPATH).first
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
            NSXAgentVideosStreamConsumptionMonitor::registerHit()
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
