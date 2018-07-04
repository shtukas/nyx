
# encoding: UTF-8

# MetricsOfChronos::metric3(uuid, low, high, timeUnitInDays, timeCommitmentInHours)

class MetricsOfChronos
    def self.metric3(uuid, low, high, timeUnitInDays, timeCommitmentInHours)
        ratiodone = Chronos::ratioDone(uuid, timeUnitInDays, timeCommitmentInHours)
        return low if ratiodone >= 1 
        low + (high-low)*(1-ratiodone)
    end
end