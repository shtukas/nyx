
# encoding: UTF-8

class Metrics

    # Metrics::levelToFloat(level)
    def self.levelToFloat(level)
        mapping = {
            "ns:running"      => 1.0,
            "ns:admin"        => 0.8,
            "ns:wave"         => 0.6,
            "ns:time-target"  => 0.4,
            "ns:zone"         => 0.2,
            "ns:zero"         => 0.0
        }
        raise "23835313-fa4b-442c-8ec2-a77ecf4f3073" if !mapping.keys.include?(level)
        mapping[level]
    end

    # Metrics::metricDataToFloat(data)
    def self.metricDataToFloat(data)
        level, itemRT = data
        itemRT = itemRT || 0
        Metrics::levelToFloat(level) - itemRT.to_f/1000
    end
end

