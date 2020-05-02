
# encoding: UTF-8

require "/Users/pascal/Galaxy/LucilleOS/Software-Common/Ruby-Libraries/Mercury.rb"
=begin
    Mercury::postValue(channel, value)

    Mercury::discardFirstElementsToEnforeQueueSize(channel, size)
    Mercury::discardFirstElementsToEnforceTimeHorizon(channel, unixtime)

    Mercury::getQueueSize(channel)
    Mercury::getAllValues(channel)

    Mercury::getFirstValueOrNull(channel)
    Mercury::deleteFirstValue(channel)
=end

# -----------------------------------------------------------------

class TwentyFourHoursCounterMetricHelper

    # TwentyFourHoursCounterMetricHelper::ping(uuid)
    def self.ping(uuid)
        Mercury::postValue(uuid, nil)
    end

    # TwentyFourHoursCounterMetricHelper::metricshift(uuid, targetNumber, shiftAtTarget)
    def self.metricshift(uuid, targetNumber, shiftAtTarget) # [hasReachedTarget: Boolean, metricshift: Float]
        Mercury::discardFirstElementsToEnforceTimeHorizon(uuid, Time.new.to_i - 86400)
        pingsize = Mercury::getQueueSize(uuid)
        pingratio = pingsize.to_f/targetNumber
        metricshift = pingratio * shiftAtTarget
        [ pingsize >= targetNumber, metricshift ]
    end
end
