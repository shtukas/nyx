
# encoding: UTF-8

require "/Users/pascal/Galaxy/LucilleOS/Software-Common/Ruby-Libraries/KeyValueStore.rb"
=begin
    KeyValueStore::setFlagTrue(repositorylocation or nil, key)
    KeyValueStore::setFlagFalse(repositorylocation or nil, key)
    KeyValueStore::flagIsTrue(repositorylocation or nil, key)

    KeyValueStore::set(repositorylocation or nil, key, value)
    KeyValueStore::getOrNull(repositorylocation or nil, key)
    KeyValueStore::getOrDefaultValue(repositorylocation or nil, key, defaultValue)
    KeyValueStore::destroy(repositorylocation or nil, key)
=end

require "/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/Catalyst/Common.rb"

class NSXMiscUtils

    # NSXMiscUtils::timeStringL22()
    def self.timeStringL22()
        "#{Time.new.strftime("%Y%m%d-%H%M%S-%6N")}"
    end

    def self.traceToRealInUnitInterval(trace)
        ( '0.'+Digest::SHA1.hexdigest(trace).gsub(/[^\d]/, '') ).to_f
    end

    # NSXMiscUtils::traceToMetricShift(trace)
    def self.traceToMetricShift(trace)
        0.001*NSXMiscUtils::traceToRealInUnitInterval(trace)
    end

    # NSXMiscUtils::isLucille18()
    def self.isLucille18()
        ENV["COMPUTERLUCILLENAME"] == "Lucille18"
    end
end
