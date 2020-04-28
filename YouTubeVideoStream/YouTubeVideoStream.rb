
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

require "/Users/pascal/Galaxy/LucilleOS/Software-Common/Ruby-Libraries/DoNotShowUntil.rb"
#    DoNotShowUntil::setUnixtime(uid, unixtime)
#    DoNotShowUntil::isVisible(uid)

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

    # YouTubeVideoStream::videoFolderpathsAtFolder(folderpath)
    def self.videoFolderpathsAtFolder(folderpath)
        return [] if !File.exists?(folderpath)
        Dir.entries(folderpath)
            .select{|filename| filename[0,1] != "." }
            .map{|filename| "#{folderpath}/#{filename}" }
            .sort
    end

    # YouTubeVideoStream::filepathToVideoUUID(filepath)
    def self.filepathToVideoUUID(filepath)
        Digest::SHA1.hexdigest("cec985f2-3287-4d3a-b4f8-a05f30a6cc52:#{filepath}")
    end

    # YouTubeVideoStream::getVideoFilepathByUUIDOrNull(uuid)
    def self.getVideoFilepathByUUIDOrNull(uuid)
        YouTubeVideoStream::videoFolderpathsAtFolder(YouTubeVideoStream::spaceFolderpath())
            .select{|filepath| YouTubeVideoStream::filepathToVideoUUID(filepath) == uuid }
            .first
    end
end

