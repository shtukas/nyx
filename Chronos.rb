
# encoding: UTF-8
# Chronos::status(uuid): [boolean, null or unixtime]
# Chronos::isRunning(uuid)
# Chronos::start(uuid)
# Chronos::stop(uuid)
# Chronos::addTimeInSeconds(uuid, timespan)
# Chronos::timings(uuid)
# Chronos::summedTimespansInSeconds(uuid)
# Chronos::summedTimespansInSecondsLiveValue(uuid)
# Chronos::summedTimespansWithDecayInSeconds(uuid, timeUnitInDays)
# Chronos::metric3(uuid, low, high, timeUnitInDays, timeCommitmentInHours)

class Chronos

    def self.status(uuid)
        JSON.parse(FKVStore::getOrDefaultValue("status:d0742c76-b83a-4fa4-9264-cfb5b21f8dc4:#{uuid}", "[false, null]"))
    end

    def self.isRunning(uuid)
        status = Chronos::status(uuid)
        status[0]
    end

    def self.start(uuid)
        status = Chronos::status(uuid)
        return if status[0]
        status = [true, Time.new.to_i]
        FKVStore::set("status:d0742c76-b83a-4fa4-9264-cfb5b21f8dc4:#{uuid}", JSON.generate(status))
    end

    def self.stop(uuid)
        status = Chronos::status(uuid)
        return if !status[0]
        timespan = Time.new.to_i - status[1]
        Chronos::addTimeInSeconds(uuid, timespan)
        status = [false, nil]
        FKVStore::set("status:d0742c76-b83a-4fa4-9264-cfb5b21f8dc4:#{uuid}", JSON.generate(status))
    end

    def self.addTimeInSeconds(uuid, timespan)
        MiniFIFOQ::push("timespans:f13bdb69-9313-4097-930c-63af0696b92d:#{uuid}", [Time.new.to_i, timespan])
    end

    def self.summedTimespansInSeconds(uuid)
        MiniFIFOQ::values("timespans:f13bdb69-9313-4097-930c-63af0696b92d:#{uuid}")
            .map{|pair| pair[1] }
            .inject(0, :+)
    end

    def self.summedTimespansInSecondsLiveValue(uuid)
        time_weight_in_seconds = Chronos::summedTimespansInSeconds(uuid)
        status = Chronos::status(uuid)
        live_timespan = status[0] ? Time.new.to_i - status[1] : 0
        time_weight_in_seconds + live_timespan
    end

    def self.summedTimespansWithDecayInSeconds(uuid, timeUnitInDays)
        # The timeUnitInDays controls the rate of decay, we want the time of daily project to decay faster than the time for weekly projects
        MiniFIFOQ::values("timespans:f13bdb69-9313-4097-930c-63af0696b92d:#{uuid}")
            .map{|pair|
                unixtime = pair[0]
                timespan = pair[1]
                ageInSeconds = Time.new.to_i - unixtime
                ageInDays = ageInSeconds.to_f/86400
                ageInTimeUnit = ageInDays.to_f/timeUnitInDays
                timespan * Math.exp(-ageInDays)
            }
            .inject(0, :+)
    end

    def self.summedTimespansWithDecayInSecondsLiveValue(uuid, timeUnitInDays)
        # The timeUnitInDays controls the rate of decay, we want the time of daily project to decay faster than the time for weekly projects
        time_weight_in_seconds = Chronos::summedTimespansWithDecayInSeconds(uuid, timeUnitInDays)
        status = Chronos::status(uuid)
        live_timespan = status[0] ? Time.new.to_i - status[1] : 0
        time_weight_in_seconds + live_timespan
    end

    def self.metric3(uuid, low, high, timeUnitInDays, timeCommitmentInHours)
        return low if timeCommitmentInHours==0 # This happens sometimes
        summedTimeSpanInSeconds = Chronos::summedTimespansWithDecayInSeconds(uuid, timeUnitInDays)
        summedTimeSpanInHours = summedTimeSpanInSeconds.to_f/3600
        ratiodone = summedTimeSpanInHours.to_f/timeCommitmentInHours
        if ratiodone >= 0.9 then
            ratiodone = 0.1*(1-Math.exp(-(ratiodone-0.9)))+0.9
        end
        low + (high-low)*(1-ratiodone)
    end

    def self.timings(uuid)
        MiniFIFOQ::values("timespans:f13bdb69-9313-4097-930c-63af0696b92d:#{uuid}")
    end
end