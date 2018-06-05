
# encoding: UTF-8

# ----------------------------------------------------------------------
# TodayOrNotToday::notToday(uuid)
# TodayOrNotToday::todayOk(uuid)
# TodayOrNotToday::transform()

class TodayOrNotToday
    def self.notToday(uuid)
        DRbObject.new(nil, "druby://:18171").fKVStore_set("9e8881b5-3bf7-4a08-b454-6b8b827cd0e0:#{CommonsUtils::currentDay()}:#{uuid}", "!today")
    end
    def self.todayOk(uuid)
        DRbObject.new(nil, "druby://:18171").fKVStore_getOrNull("9e8881b5-3bf7-4a08-b454-6b8b827cd0e0:#{CommonsUtils::currentDay()}:#{uuid}").nil?
    end
    def self.transform()
        DRbObject.new(nil, "druby://:18171").flockOperator_flockObjects().each{|object|
            if !TodayOrNotToday::todayOk(object["uuid"]) and object["metric"]<=1 then
                # The second condition in case we start running an object that wasn't scheduled to be shown today (they can be found through search)
                object["metric"] = 0
            end
            DRbObject.new(nil, "druby://:18171").flockOperator_addOrUpdateObject(object)
        }
    end
end