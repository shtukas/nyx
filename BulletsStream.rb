
# encoding: UTF-8

# BulletsStream::register(uuid)
# BulletsStream::metric(uuid, timeUnitInDays, countForMinusOne)
    # The timeUnitInDays controls how fast the events decay in value. 
    # The countForMinusOne controls how many of them we want for exp(-1)

# MiniFIFOQ::size(queueuuid)
# MiniFIFOQ::values(queueuuid)
# MiniFIFOQ::push(queueuuid, value)
# MiniFIFOQ::getFirstOrNull(queueuuid)
# MiniFIFOQ::takeFirstOrNull(queueuuid)
# MiniFIFOQ::takeWhile(queueuuid, xlambda)

class BulletsStream

    def self.register(uuid)
        MiniFIFOQ::push("2c359a03-49b4-4262-8d08-72496f72b09e:#{uuid}", Time.new.to_i)
    end

    def self.sumWithDecay(uuid, timeUnitInDays)
        MiniFIFOQ::values("2c359a03-49b4-4262-8d08-72496f72b09e:#{uuid}")
            .map{|unixtime|
                ageInSeconds = Time.new.to_i - unixtime
                ageInDays = ageInSeconds.to_f/86400
                ageInTimeUnit = ageInDays.to_f/timeUnitInDays
                Math.exp(-ageInDays)
            }
            .inject(0, :+)
            # In esssence, each register counts for 1, but the individual events decay in importance
    end

    def self.metric(uuid, timeUnitInDays, countForMinusOne)
        # The timeUnitInDays controls how fast the events decay in value. 
        # The countForMinusOne controls how many of them we want for exp(-1)
        sum = BulletsStream::sumWithDecay(uuid, timeUnitInDays)
        Math.exp(-sum.to_f/countForMinusOne)
    end
end