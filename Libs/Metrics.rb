
# encoding: UTF-8

class Metrics

    # Metrics::levelToFloat(level)
    def self.levelToFloat(level)
        mapping = {
            "running" => 1.0,
            "today"   => 0.7,
            "zone"    => 0.4
        }
        raise "23835313-fa4b-442c-8ec2-a77ecf4f3073" if !mapping.keys.include?(level)
        mapping[level]
    end

    # Metrics::metric(level, unit or nil, indx or nil)
    def self.metric(level, unit = nil, indx = nil)
        unit = unit ? unit : 0.5
        indx = indx ? indx.to_f/1000 : 0
        Metrics::levelToFloat(level) + unit - indx
    end
end