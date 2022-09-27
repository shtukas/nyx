class XCacheValuesWithExpiry

    # XCacheValuesWithExpiry::set(key, value, timespanInSecond)
    def self.set(key, value, timespanInSecond)
        # if timespanInSecond is null then we set expiryunixtime to null
        # which then means that the caching doesn't expire
        packet =
            if timespanInSecond then
                {
                    "value" => value,
                    "expiryunixtime" => Time.new.to_i + timespanInSecond
                }
            else
                {
                    "value" => value,
                    "expiryunixtime" => nil
                }
            end
        XCache::set(key, JSON.generate(packet))
    end

    # XCacheValuesWithExpiry::getOrNull(key)
    def self.getOrNull(key)
        packet = XCache::getOrNull(key)
        return nil if packet.nil?
        packet = JSON.parse(packet)
        if packet["expiryunixtime"] then
            if Time.new.to_i < packet["expiryunixtime"] then
                return packet["value"]
            else
                return nil
            end
        else
            return packet["value"]
        end
    end

    # XCacheValuesWithExpiry::decache(key)
    def self.decache(key)
        XCache::destroy(key)
    end
end