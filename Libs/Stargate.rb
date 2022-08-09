
# encoding: UTF-8

class Stargate
    # Stargate::resetCachePrefix()
    def self.resetCachePrefix()
        XCache::destroy("StargateGlobalCache:de0991c3-7148-4c61-a976-ba92b1536789")
    end

    # Stargate::cachePrefix()
    def self.cachePrefix()
        prefix = XCache::getOrNull("StargateGlobalCache:de0991c3-7148-4c61-a976-ba92b1536789")
        if prefix.nil? then
            prefix = SecureRandom.hex
            XCache::set("StargateGlobalCache:de0991c3-7148-4c61-a976-ba92b1536789", prefix)
        end
        prefix
    end
end
