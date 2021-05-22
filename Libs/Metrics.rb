
# encoding: UTF-8

class Metrics

    # Metrics::levelToFloat(level)
    def self.levelToFloat(level)
        mapping = {
            "running" => 1.0,
            "wave"    => 0.8,
            "today"   => 0.7,
            "zone"    => 0.4
        }
        raise "23835313-fa4b-442c-8ec2-a77ecf4f3073" if !mapping.keys.include?(level)
        mapping[level]
    end

    # Metrics::metric(level, unit or nil, indx or nil): [metric, level, unit, indx]
    def self.metric(level, unit = nil, indx = nil)
        unit2 = unit ? unit : 0.5
        indx2 = indx ? indx.to_f/1000 : 0
        [level, unit, indx, Metrics::levelToFloat(level) + 0.1*unit2 - indx2]
    end
end

class GeneralMetricHelpers

    # GeneralMetricHelpers::AirTrafficControlAgentToMetricLevel(agent)
    def self.AirTrafficControlAgentToMetricLevel(agent)
        "today"
    end

    # GeneralMetricHelpers::quarkIdToMetricLevel(uuid)
    def self.quarkIdToMetricLevel(uuid)
        agent = AirTrafficControl::agentForUUID(uuid)
        GeneralMetricHelpers::AirTrafficControlAgentToMetricLevel(agent)
    end
end