
# encoding: UTF-8

class ProgrammableBooleans

    # ProgrammableBooleans::resetTrueNoMoreOften(uuid)
    def self.resetTrueNoMoreOften(uuid)
        XCache::set(uuid, Time.new.to_f)
    end

    # ProgrammableBooleans::trueNoMoreOftenThanEveryNSeconds(uuid, n)
    def self.trueNoMoreOftenThanEveryNSeconds(uuid, n)
        lastTimestamp = XCache::getOrDefaultValue(uuid, "0").to_f
        return false if (Time.new.to_f - lastTimestamp) < n
        XCache::set(uuid, Time.new.to_f)
        true
    end
end
