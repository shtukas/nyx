
# encoding: UTF-8

class Metrics

    # Metrics::levelToFloat(level)
    def self.levelToFloat(level)
        mapping = {
            "ns:running"    => 0.1,
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
        level, domainRT, itemRT, indx = data
        domainRT = domainRT || 0
        itemRT = itemRT || 0
        Metrics::levelToFloat(level) - domainRT.to_f/100 - itemRT.to_f/100 - indx.to_f/1000
    end
end

