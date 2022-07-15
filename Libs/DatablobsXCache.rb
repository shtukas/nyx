class DatablobsXCache

    # DatablobsXCache::putBlob(blob)
    def self.putBlob(blob)
        nhash = "SHA256-#{Digest::SHA256.hexdigest(blob)}"
        XCache::set(nhash, blob)
        nhash
    end

    # DatablobsXCache::getBlobOrNull(nhash)
    def self.getBlobOrNull(nhash)
        XCache::getOrNull(nhash)
    end
end