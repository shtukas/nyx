
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

class YouTubeVideoStream

    # YouTubeVideoStream::spaceFolderpath()
    def self.spaceFolderpath()
        "/Users/pascal/x-space/YouTube Videos"
    end

    # YouTubeVideoStream::energyGridFolderpath()
    def self.energyGridFolderpath()
        "/Volumes/EnergyGrid/Data/Pascal/Galaxy/YouTube Videos"
    end

    # YouTubeVideoStream::registerHit()
    def self.registerHit()
        points = KeyValueStore::getOrDefaultValue(nil, "7766a7ae-11ff-42f4-84e4-5c27f939f4d8:#{Time.new.to_s[0, 10]}", "[]")
        points = JSON.parse(points)
        points << Time.new.to_i
        KeyValueStore::set(nil, "7766a7ae-11ff-42f4-84e4-5c27f939f4d8:#{Time.new.to_s[0, 10]}", JSON.generate(points))
    end

    # YouTubeVideoStream::metric()
    def self.metric()
        points = KeyValueStore::getOrDefaultValue(nil, "7766a7ae-11ff-42f4-84e4-5c27f939f4d8:#{Time.new.to_s[0, 10]}", "[]")
        points = JSON.parse(points)
        return 0.7 if points.empty?
        n = points.select{|point| (Time.new.to_i-point) < 3600*2 }.count
        0.7*Math.exp(-n.to_f/6)
    end

    # YouTubeVideoStream::videoFolderpathsAtFolder(folderpath)
    def self.videoFolderpathsAtFolder(folderpath)
        return [] if !File.exists?(folderpath)
        Dir.entries(folderpath)
            .select{|filename| filename[0,1] != "." }
            .map{|filename| "#{folderpath}/#{filename}" }
            .sort
    end

    # YouTubeVideoStream::calalystObjects()
    def self.calalystObjects()
        return [] if ENV["COMPUTERLUCILLENAME"] != "Lucille18"
        loop {
            break if YouTubeVideoStream::videoFolderpathsAtFolder(YouTubeVideoStream::spaceFolderpath()).size >= 40
            break if YouTubeVideoStream::videoFolderpathsAtFolder(YouTubeVideoStream::energyGridFolderpath()).size == 0
            filepath = YouTubeVideoStream::videoFolderpathsAtFolder(YouTubeVideoStream::energyGridFolderpath()).first
            filename = File.basename(filepath)
            targetFilepath = "#{YouTubeVideoStream::spaceFolderpath()}/#{filename}"
            FileUtils.mv(filepath, targetFilepath)
            break if !File.exists?(targetFilepath)
        }
        filepath = YouTubeVideoStream::videoFolderpathsAtFolder(YouTubeVideoStream::spaceFolderpath()).first
        return [] if filepath.nil?
        announce = "YouTube Video Stream"
        [
            {
                "uuid"                => "f7845869-e058-44cd-bfae-3412957c7dba",
                "contentItem"         => {
                    "type" => "line",
                    "line" => "YouTube Video Stream"
                },
                "metric"              => YouTubeVideoStream::metric(),
                "commands"            => [],
                "defaultCommand"      => "view",
                "shell-redirects" => {
                    "view"  => "/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/YouTubeVideoStream/catalyst-objects-processing view"
                }
            }
        ]
    end
end

