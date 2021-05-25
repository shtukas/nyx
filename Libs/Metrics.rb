
# encoding: UTF-8

class Metrics

    # Metrics::levelToFloat(level)
    def self.levelToFloat(level)
        mapping = {
            "ns:running"    => 1.0,
            "ns:wave"       => 0.8,
            "ns:work"       => 0.6,
            "ns:important"  => 0.4,
            "ns:zone"       => 0.2
        }
        raise "23835313-fa4b-442c-8ec2-a77ecf4f3073" if !mapping.keys.include?(level)
        mapping[level]
    end

    # Metrics::metricDataToFloat(data)
    def self.metricDataToFloat(data)
        level, itemRT, indx = data
        itemRT = itemRT || 0
        indx = indx || 0
        Metrics::levelToFloat(level) - itemRT.to_f/100 - indx.to_f/100
    end
end

