
# encoding: UTF-8

class DateTimeZ

    # DateTimeZ::make(targetuuid, datetime)
    def self.make(targetuuid, datetime)
        raise "[DateTimeZ errror 4E5352A4]" if !Miscellaneous::isProperDateTime_utc_iso8601(datetime)
        {
            "uuid"            => SecureRandom.uuid,
            "nyxNxSet"        => "1bc9b712-09be-44da-9551-f22d70a3f15d",
            "unixtime"        => Time.new.to_f,
            "targetuuid"      => targetuuid,
            "datetimeISO8601" => datetime
        }
    end

    # DateTimeZ::issue(targetuuid, datetime)
    def self.issue(targetuuid, datetime)
        object = DateTimeZ::make(targetuuid, datetime)
        NyxObjects::put(object)
        object
    end

    # DateTimeZ::getDateTimeZsForTargetInTimeOrder(targetuuid)
    def self.getDateTimeZsForTargetInTimeOrder(targetuuid)
        NyxObjects::getSet("1bc9b712-09be-44da-9551-f22d70a3f15d")
            .select{|object| object["targetuuid"] == targetuuid }
            .sort{|o1, o2| o1["unixtime"] <=> o2["unixtime"] }
    end

    # DateTimeZ::destroy(object)
    def self.destroy(object)
        NyxObjects::destroy(object["uuid"])
    end
end
