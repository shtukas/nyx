
# encoding: UTF-8

# MetricsOfTimeStructures::metric2(uuid, donemetric, lowmetric, highmetric, timestructure)

class MetricsOfTimeStructures
    def self.metric2(uuid, donemetric, lowmetric, highmetric, timestructure)
        return highmetric if Chronos::isRunning(uuid)
        return donemetric if Chronos::ratioDone(uuid, timestructure["time-unit-in-days"], timestructure["time-commitment-in-hours"]) >= 1
        metric1 = MetricsOfChronos::metric3(uuid, lowmetric, highmetric, timestructure["time-unit-in-days"], timestructure["time-commitment-in-hours"])
        metric2 = MetricsOfChronos::metric3(uuid, lowmetric, highmetric, 1, timestructure["time-commitment-in-hours"].to_f/timestructure["time-unit-in-days"]) 
        [ metric1, metric2 ].min
    end
end