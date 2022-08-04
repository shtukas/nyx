=begin
    XCacheSets::values(setuuid: String): Array[Value]
    XCacheSets::set(setuuid: String, valueuuid: String, value)
    XCacheSets::getOrNull(setuuid: String, valueuuid: String): nil | Value
    XCacheSets::destroy(setuuid: String, valueuuid: String)
=end

class DailySlots

    # DailySlots::dataset()
    def self.dataset()
        XCacheSets::values("851563eb-74ea-477d-8b39-e8d28f43f5e6:#{CommonUtils::today()}")
    end

    # DailySlots::removeNoEvent(objectuuid)
    def self.removeNoEvent(objectuuid)
        DailySlots::dataset().each{|entry|
            if entry["objectuuid"] == objectuuid then
                XCacheSets::destroy("851563eb-74ea-477d-8b39-e8d28f43f5e6:#{CommonUtils::today()}", entry["uuid"])
            end
        }
    end

    # DailySlots::remove(objectuuid)
    def self.remove(objectuuid)
        DailySlots::removeNoEvent(objectuuid)
        SystemEvents::broadcast({
            "mikuType"   => "Daily Slots: Unregister",
            "objectuuid" => objectuuid,
        })
    end

    # DailySlots::registerNoEvent(hour, objectuuid)
    def self.registerNoEvent(hour, objectuuid)
        DailySlots::removeNoEvent(objectuuid)
        value = {
            "uuid"       => SecureRandom.uuid,
            "mikuType"   => "NxCalendarItem1",
            "hour"       => hour,
            "objectuuid" => objectuuid
        }
        XCacheSets::set("851563eb-74ea-477d-8b39-e8d28f43f5e6:#{CommonUtils::today()}", value["uuid"], value)
    end

    # DailySlots::register(hour, objectuuid)
    def self.register(hour, objectuuid)
        DailySlots::registerNoEvent(hour, objectuuid)
        SystemEvents::broadcast({
            "mikuType"   => "Daily Slots: Register",
            "hour"       => hour,
            "objectuuid" => objectuuid,
        })
    end

    # DailySlots::section()
    def self.section()
        DailySlots::dataset()
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
            .select{|entry| DoNotShowUntil::isVisible(entry["item"]["uuid"]) }
            .select{|entry| InternetStatus::itemShouldShow(entry["item"]["uuid"]) }
    end

    # DailySlots::internalEventProcessing(event)
    def self.internalEventProcessing(event)

        if event["mikuType"] == "Daily Slots: Unregister" then
            objectuuid = event["objectuuid"]
            DailySlots::removeNoEvent(objectuuid)
        end

        if event["mikuType"] == "Daily Slots: Register" then
            hour = event["hour"]
            objectuuid = event["objectuuid"]
            DailySlots::registerNoEvent(hour, objectuuid)
        end
    end
end
