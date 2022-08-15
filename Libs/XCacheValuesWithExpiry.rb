class XCacheValuesWithExpiry

    # XCacheValuesWithExpiry::set(key, value, timespanInSecond)
    def self.set(key, value, timespanInSecond)
        packet = {
            "value" => value,
            "expiryunixtime" => Time.new.to_i + timespanInSecond
        }
        XCache::set(key, JSON.generate(packet))
    end

    # XCacheValuesWithExpiry::getOrNull(key)
    def self.getOrNull(key)
        packet = XCache::getOrNull(key)
        return nil if packet.nil?
        packet = JSON.parse(packet)
        return nil if Time.new.to_i > packet["expiryunixtime"]
        packet["value"]
    end
end