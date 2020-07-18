
# encoding: UTF-8

class DateTimeZ

    # DateTimeZ::make(datetime)
    def self.make(datetime)
        raise "[DateTimeZ errror 4E5352A4]" if !Miscellaneous::isProperDateTime_utc_iso8601(datetime)
        {
            "uuid"            => SecureRandom.uuid,
            "nyxNxSet"        => "1bc9b712-09be-44da-9551-f22d70a3f15d",
            "unixtime"        => Time.new.to_f,
            "targetuuid"      => targetuuid,
            "datetimeISO8601" => datetime
        }
    end

    # DateTimeZ::issue(datetime)
    def self.issue(datetime)
        object = DateTimeZ::make(datetime)
        NyxObjects::put(object)
        object
    end

    # DateTimeZ::datetimez()
    def self.datetimez()
        NyxObjects::getSet("1bc9b712-09be-44da-9551-f22d70a3f15d")
    end

    # DateTimeZ::getDateTimeZForSourceInTimeOrder(source)
    def self.getDateTimeZForSourceInTimeOrder(source)
        Arrows::getTargetsOfGivenSetsForSource(source, ["1bc9b712-09be-44da-9551-f22d70a3f15d"])
            .sort{|n1, n2| n1["unixtime"] <=> n2["unixtime"] }
    end

    # DateTimeZ::getLastDateTimeISO8601ForSourceOrNull(source)
    def self.getLastDateTimeISO8601ForSourceOrNull(source)
        dtzs = DateTimeZ::getDateTimeZForSourceInTimeOrder(source)
        return nil if dtzs.size == 0
        dtzs.last["datetimeISO8601"]
    end

    # DateTimeZ::destroy(object)
    def self.destroy(object)
        NyxObjects::destroy(object)
    end
end
