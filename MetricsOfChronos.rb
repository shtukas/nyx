
# encoding: UTF-8

# MetricsOfMetricsOfChronos::metric3(uuid, low, high, timeUnitInDays, timeCommitmentInHours)

class MetricsOfChronos
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
end