
# encoding: UTF-8
# GenericTimeTracking::status(uuid): [boolean, null or unixtime]
# GenericTimeTracking::start(uuid)
# GenericTimeTracking::stop(uuid)
# GenericTimeTracking::addTimeInSeconds(uuid, timespan)
# GenericTimeTracking::adaptedTimespanInSeconds(uuid)
# GenericTimeTracking::metric2(uuid, low, high, hourstoMinusOne)
# GenericTimeTracking::timings(uuid)

class GenericTimeTracking
    def self.status(uuid)
        JSON.parse(DRbObject.new(nil, "druby://:18171").fKVStore_getOrDefaultValue("status:d0742c76-b83a-4fa4-9264-cfb5b21f8dc4:#{uuid}", "[false, null]"))
    end

    def self.start(uuid)
        status = GenericTimeTracking::status(uuid)
        return if status[0]
        status = [true, Time.new.to_i]
        DRbObject.new(nil, "druby://:18171").fKVStore_set("status:d0742c76-b83a-4fa4-9264-cfb5b21f8dc4:#{uuid}", JSON.generate(status))
    end

    def self.stop(uuid)
        status = GenericTimeTracking::status(uuid)
        return if !status[0]
        timespan = Time.new.to_i - status[1]
        GenericTimeTracking::addTimeInSeconds(uuid, timespan)
        status = [false, nil]
        DRbObject.new(nil, "druby://:18171").fKVStore_set("status:d0742c76-b83a-4fa4-9264-cfb5b21f8dc4:#{uuid}", JSON.generate(status))
    end

    def self.addTimeInSeconds(uuid, timespan)
        MiniFIFOQ::push("timespans:f13bdb69-9313-4097-930c-63af0696b92d:#{uuid}", [Time.new.to_i, timespan])
    end

    def self.adaptedTimespanInSeconds(uuid)
        adaptedTimespanInSeconds = MiniFIFOQ::values("timespans:f13bdb69-9313-4097-930c-63af0696b92d:#{uuid}")
            .map{|pair|
                unixtime = pair[0]
                timespan = pair[1]
                ageInSeconds = Time.new.to_i - unixtime
                ageInDays = ageInSeconds.to_f/86400
                timespan * Math.exp(-ageInDays)
            }
            .inject(0, :+)
    end

    def self.metric2(uuid, low, high, hourstoMinusOne)
        adaptedTimespanInSeconds = GenericTimeTracking::adaptedTimespanInSeconds(uuid)
        adaptedTimespanInHours = adaptedTimespanInSeconds.to_f/3600
        low + (high-low)*Math.exp(-adaptedTimespanInHours.to_f/hourstoMinusOne)
    end

    def self.timings(uuid)
        MiniFIFOQ::values("timespans:f13bdb69-9313-4097-930c-63af0696b92d:#{uuid}")
    end
end