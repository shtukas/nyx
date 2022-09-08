
# encoding: UTF-8

class Stargate
    # Stargate::formatTypeForToString(type)
    def self.formatTypeForToString(type)
        "(#{type})".ljust(15)
    end
end
