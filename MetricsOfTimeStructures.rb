
# encoding: UTF-8

# MetricsOfTimeStructures::metric(uuid, low, high, timestructure)

class MetricsOfTimeStructures
    def self.metric(uuid, low, high, timestructure)
        metric1 = MetricsOfChronos::metric3(uuid, low, high, timestructure["time-unit-in-days"], timestructure["time-commitment-in-hours"])
        metric2 = MetricsOfChronos::metric3(uuid, low, high, 1, timestructure["time-commitment-in-hours"].to_f/timestructure["time-unit-in-days"]) 
        [ metric1, metric2 ].min
    end
end