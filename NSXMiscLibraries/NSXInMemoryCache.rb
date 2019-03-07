
# encoding: UTF-8

$EC1F029EC254E9A9C15343128D73CC6 = {}

class NSXInMemoryCache

    # NSXInMemoryCache::set(key, value, expirationTimeInSeconds)
    def self.set(key, value, expirationTimeInSeconds)
        $EC1F029EC254E9A9C15343128D73CC6[key] = [value, Time.new.to_f, expirationTimeInSeconds]
    end

    # NSXInMemoryCache::getOrNull(key)
    def self.getOrNull(key)
        entry = $EC1F029EC254E9A9C15343128D73CC6[key]
        return nil if entry.nil?
        return nil if (entry[1] + entry[2]) < Time.new.to_f
        entry[0]
    end

    # NSXInMemoryCache::invalidate(key)
    def self.invalidate(key)
        $EC1F029EC254E9A9C15343128D73CC6.delete(key)
    end
end
