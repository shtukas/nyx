
# encoding: UTF-8

class NSXOrdinal
    # NSXOrdinal::ordinalToMetric(ordinal)
    def self.ordinalToMetric(ordinal)
        1.5 + Math.exp(-ordinal).to_f/10
    end
end