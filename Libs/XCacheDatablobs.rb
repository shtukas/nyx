class XCacheDatablobs

    # XCacheDatablobs::putBlob(blob)
    def self.putBlob(blob)
        nhash = "SHA256-#{Digest::SHA256.hexdigest(blob)}"
        XCache::set(nhash, blob)
        nhash
    end

    # XCacheDatablobs::getBlobOrNull(nhash)
    def self.getBlobOrNull(nhash)
        blob = XCache::getOrNull(nhash)
        if (blob and nhash != "SHA256-#{Digest::SHA256.hexdigest(blob)}") then # better safe than sorry
            puts "(critical: 83b9e24c-8a05-4eff-ada4-70dbf58a0f75) the extracted blob #{nhash} from XCache using XCacheDatablobs::getBlobOrNull did not validate."
            return nil
        end
        blob
    end
end