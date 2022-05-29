# encoding: UTF-8

require "/Users/pascal/Galaxy/LucilleOS/Libraries/Ruby-Libraries/XCache.rb"
=begin
    XCache::setFlagTrue(key)
    XCache::setFlagFalse(key)
    XCache::flagIsTrue(key)

    XCache::set(key, value)
    XCache::getOrNull(key)
    XCache::getOrDefaultValue(key, defaultValue)
    XCache::destroy(key)
=end

class XCacheDatablobs

    # XCacheDatablobs::putBlob(blob)
    def self.putBlob(blob)
        nhash = "SHA256-#{Digest::SHA256.hexdigest(blob)}"
        XCache::set("FAF57B05-2EF0-4F49-B1C8-9E73D03939DE:#{nhash}", blob)
        nhash
    end

    # XCacheDatablobs::getBlobOrNull(nhash)
    def self.getBlobOrNull(nhash)
        XCache::getOrNull("FAF57B05-2EF0-4F49-B1C8-9E73D03939DE:#{nhash}")
    end
end

class XCacheElizabeth

    def initialize()
    end

    def filepathToContentHash(filepath)
        "SHA256-#{Digest::SHA256.file(filepath).hexdigest}"
    end

    def commitBlob(blob)
        XCacheDatablobs::putBlob(blob)
    end

    def getBlobOrNull(nhash)
        XCacheDatablobs::getBlobOrNull(nhash)
    end

    def readBlobErrorIfNotFound(nhash)
        blob = XCacheDatablobs::getBlobOrNull(nhash)
        return blob if blob
        puts "(error: c052116a-dd92-47a8-88e4-22d7516863d1) could not find blob, nhash: #{nhash}"
        raise "(error: 521d8f17-a958-44ba-97c2-ffacbbca9724, nhash: #{nhash})" if blob.nil?
    end

    def datablobCheck(nhash)
        begin
            blob = readBlobErrorIfNotFound(nhash)
            status = ("SHA256-#{Digest::SHA256.hexdigest(blob)}" == nhash)
            if !status then
                puts "(error: 4a667893-8d05-4bae-8ea8-d415066ac443) incorrect blob, exists but doesn't have the right nhash: #{nhash}"
            end
            return status
        rescue
            false
        end
    end
end
