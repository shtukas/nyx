
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

require "/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/Catalyst/Metrics.rb"

# -----------------------------------------------------------------

class VideoStream

    # VideoStream::spaceFolderpath()
    def self.spaceFolderpath()
        "/Users/pascal/x-space/YouTube Videos"
    end

    # VideoStream::energyGridFolderpath()
    def self.energyGridFolderpath()
        "/Volumes/EnergyGrid/Data/Pascal/01-Data/YouTube-Videos"
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
        timeInHours = Ping::totalToday("VideoStream-3623a0c2-ef0d-47e2-9008-3c1a9fd52c01").to_f/3600
        Metrics::metricNX1RequiredValueAndThenFall(0.55, timeInHours, 0.5) - indx.to_f/1000
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
                    "body"        => "[VideoStream] #{File.basename(filepath)}",
                    "metric"      => VideoStream::metric(indx),
                    "execute"     => lambda { VideoStream::execute(filepath) },
                    "x-video-stream" => true,
                    "x-filepath"  => filepath
                }
            }

        objects
    end

    # VideoStream::play(filepath)
    def self.play(filepath)
        startTime = Time.new.to_f
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
        watchTime = Time.new.to_f - startTime
        Ping::put("VideoStream-3623a0c2-ef0d-47e2-9008-3c1a9fd52c01", watchTime)
    end

    # VideoStream::execute(filepath)
    def self.execute(filepath)
        options = ["play", "completed"]
        option = LucilleCore::selectEntityFromListOfEntitiesOrNull("operation", options)
        if option == "play" then
            VideoStream::play(filepath)
        end
        if option == "completed" then
            exit if filepath.nil?
            puts filepath
            FileUtils.rm(filepath)
        end
    end

end

