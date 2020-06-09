
# encoding: UTF-8
require 'json'

require 'fileutils'

require "/Users/pascal/Galaxy/LucilleOS/Libraries/Ruby-Libraries/LucilleCore.rb"

require "/Users/pascal/Galaxy/LucilleOS/Libraries/Ruby-Libraries/KeyValueStore.rb"
=begin
    KeyValueStore::setFlagTrue(repositorylocation or nil, key)
    KeyValueStore::setFlagFalse(repositorylocation or nil, key)
    KeyValueStore::flagIsTrue(repositorylocation or nil, key)

    KeyValueStore::set(repositorylocation or nil, key, value)
    KeyValueStore::getOrNull(repositorylocation or nil, key)
    KeyValueStore::getOrDefaultValue(repositorylocation or nil, key, defaultValue)
    KeyValueStore::destroy(repositorylocation or nil, key)
=end

require "/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/Catalyst/DoNotShowUntil.rb"
#    DoNotShowUntil::setUnixtime(uid, unixtime)
#    DoNotShowUntil::isVisible(uid)

# -----------------------------------------------------------------

class VideoStream

    # VideoStream::spaceFolderpath()
    def self.spaceFolderpath()
        "/Users/pascal/x-space/YouTube Videos"
    end

    # VideoStream::energyGridFolderpath()
    def self.energyGridFolderpath()
        "/Volumes/EnergyGrid/Data/Pascal/YouTube-Videos"
    end

    # VideoStream::videoFolderpathsAtFolder(folderpath)
    def self.videoFolderpathsAtFolder(folderpath)
        return [] if !File.exists?(folderpath)
        Dir.entries(folderpath)
            .select{|filename| filename[0,1] != "." }
            .map{|filename| "#{folderpath}/#{filename}" }
            .sort
    end

    # VideoStream::filepathToVideoUUID(filepath)
    def self.filepathToVideoUUID(filepath)
        Digest::SHA1.hexdigest("cec985f2-3287-4d3a-b4f8-a05f30a6cc52:#{filepath}")
    end

    # VideoStream::getVideoFilepathByUUIDOrNull(uuid)
    def self.getVideoFilepathByUUIDOrNull(uuid)
        VideoStream::videoFolderpathsAtFolder(VideoStream::spaceFolderpath())
            .select{|filepath| VideoStream::filepathToVideoUUID(filepath) == uuid }
            .first
    end

    # VideoStream::metric(indx)
    def self.metric(indx)
        0.60 - indx.to_f/1000 - (0.4/25)*Ping::totalOverTimespan("VideoStream-3623a0c2-ef0d-47e2-9008-3c1a9fd52c01", 86400) # We go down by 0.4 after 25, we do over 24 hours
    end

    # VideoStream::catalystObjects()
    def self.catalystObjects()
        loop {
            break if VideoStream::videoFolderpathsAtFolder(VideoStream::spaceFolderpath()).size >= 40
            break if VideoStream::videoFolderpathsAtFolder(VideoStream::energyGridFolderpath()).size == 0
            filepath = VideoStream::videoFolderpathsAtFolder(VideoStream::energyGridFolderpath()).first
            filename = File.basename(filepath)
            targetFilepath = "#{VideoStream::spaceFolderpath()}/#{filename}"
            FileUtils.mv(filepath, targetFilepath)
            break if !File.exists?(targetFilepath)
        }

        if !File.exists?(VideoStream::spaceFolderpath()) then
            return []
        end

        objects = []

        VideoStream::videoFolderpathsAtFolder(VideoStream::spaceFolderpath())
        .first(3)
        .map
        .with_index{|filepath, indx|
            uuid = VideoStream::filepathToVideoUUID(filepath)
            objects << {
                "uuid"        => uuid,
                "application" => "VideoStream",
                "body"        => "[VideoStream] #{File.basename(filepath)}",
                "metric"      => VideoStream::metric(indx),
                "execute"     => lambda { VideoStream::execute(filepath) }
            }
        }

        objects
    end

    # VideoStream::execute(filepath)
    def self.execute(filepath)
        options = ["play", "completed"]
        option = LucilleCore::selectEntityFromListOfEntitiesOrNull("operation", options)
        if option == "play" then
            puts filepath
            if filepath.include?("'") then
                filepath2 = filepath.gsub("'", ',')
                FileUtils.mv(filepath, filepath2)
                filepath = filepath2
            end
            system("open '#{filepath}'")
            if LucilleCore::askQuestionAnswerAsBoolean("-> completed? ", true) then
                FileUtils.rm(filepath)
                sleep 1
            end
            Ping::put("VideoStream-3623a0c2-ef0d-47e2-9008-3c1a9fd52c01", 1)
        end
        if option == "completed" then
            exit if filepath.nil?
            puts filepath
            FileUtils.rm(filepath)
            Ping::put("VideoStream-3623a0c2-ef0d-47e2-9008-3c1a9fd52c01", 1)
        end
    end

end

