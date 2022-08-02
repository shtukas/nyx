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

    # Calendar::remove(objectuuid)
    def self.remove(objectuuid)
        Calendar::dataset().each{|entry|
            if entry["objectuuid"] == objectuuid then
                XCacheSets::destroy("851563eb-74ea-477d-8b39-e8d28f43f5e6:#{CommonUtils::today()}", entry["uuid"])
            end
        }
    end

    # Calendar::register(hour, objectuuid)
    def self.register(hour, objectuuid)
        Calendar::remove(objectuuid)
        value = {
            "uuid"       => SecureRandom.uuid,
            "mikuType"   => "NxCalendarItem1",
            "hour"       => hour,
            "objectuuid" => objectuuid
        }
        XCacheSets::set("851563eb-74ea-477d-8b39-e8d28f43f5e6:#{CommonUtils::today()}", value["uuid"], value)
    end

    # Calendar::section()
    def self.section()
        Calendar::dataset()
            .map{|entry|
                entry["item"] = Fx18::itemOrNull(entry["objectuuid"])
                if entry["hour"].size == 2 then
                    entry["hour"] = "#{entry["hour"]}:00"
                end
                entry
            }
            .select{|entry|
                !entry["item"].nil?
            }
            .sort{|e1, e2| e1["hour"] <=> e2["hour"] }
    end
end
