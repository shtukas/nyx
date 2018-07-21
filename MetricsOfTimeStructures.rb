
# encoding: UTF-8

# MetricsOfTimeStructures::metric1(low, high, ratiodone)
# MetricsOfTimeStructures::metric2(uuid, low, high, timeUnitInDays, timeCommitmentInHours)
# MetricsOfTimeStructures::metric4(uuid, donemetric, lowmetric, highmetric, timestructure)

class MetricsOfTimeStructures
    def self.metric1(low, high, ratiodone)
        return low if ratiodone >= 1 
        low + (high-low)*(1-ratiodone)
    end

    def self.metric2(uuid, low, high, timestructure)
        ratiodone1 = Chronos::ratioDone(uuid, timestructure["time-unit-in-days"], timestructure["time-commitment-in-hours"])
        ratiodone2 = Chronos::ratioDone(uuid, 1, timestructure["time-commitment-in-hours"].to_f/timestructure["time-unit-in-days"])
        MetricsOfTimeStructures::metric1(low, high, [ratiodone1, ratiodone2].max)
    end

    def self.metric4(uuid, donemetric, lowmetric, highmetric, timestructure)
        return highmetric if Chronos::isRunning(uuid)
        return donemetric if Chronos::ratioDone(uuid, timestructure["time-unit-in-days"], timestructure["time-commitment-in-hours"]) >= 1
        MetricsOfTimeStructures::metric2(uuid, lowmetric, highmetric, timestructure)
    end
end