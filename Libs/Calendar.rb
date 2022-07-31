=begin
    XCacheSets::values(setuuid: String): Array[Value]
    XCacheSets::set(setuuid: String, valueuuid: String, value)
    XCacheSets::getOrNull(setuuid: String, valueuuid: String): nil | Value
    XCacheSets::destroy(setuuid: String, valueuuid: String)
=end

# case class CalendarRegistration(uuid, hour: String, length 2, objectuuid)

class Calendar

    # Calendar::dataset()
    def self.dataset()
        XCacheSets::values("851563eb-74ea-477d-8b39-e8d28f43f5e6:#{CommonUtils::today()}")
    end

    # Calendar::register(hour, objectuuid)
    def self.register(hour, objectuuid)
        value = {
            "uuid" => SecureRandom.uuid,
            "hour" => hour,
            "objectuuid" => objectuuid
        }
        XCacheSets::set("851563eb-74ea-477d-8b39-e8d28f43f5e6:#{CommonUtils::today()}", valueuuid: String, value)
    end
end
