
# encoding: UTF-8

class TimeEstimations

    # TimeEstimations::timesForItem(item)
    def self.timesForItem(item)
        (-6..-1).map{|i| Bank::valueAtDate(item["uuid"], CommonUtils::nDaysInTheFuture(i)) }
    end

    # TimeEstimations::itemToEstimationInSeconds(item)
    def self.itemToEstimationInSeconds(item)
        return 0 if item["mikuType"] == "Wave" and item["priority"] == "ns:beach"
        return 0 if item["mikuType"] == "NxTodo" # The General Time Commitment, already took care of that, it's in the { time commitment pending }
        return NxOTimeCommitments::itemPendingTimeInSeconds(item) if item["mikuType"] == "NxOTimeCommitment"
        return NxWTCTodayTimeLoads::itemPendingTimeInSeconds(item) if item["mikuType"] == "NxWTimeCommitment"
        TimeEstimations::timesForItem(item).inject(0, :+)
    end

    # TimeEstimations::manageSpeedOfLight(totalEstimatedTimeInSeconds)
    def self.manageSpeedOfLight(totalEstimatedTimeInSeconds)
        unixtime = CommonUtils::unixtimeAtComingMidnightAtGivenTimeZone(CommonUtils::getLocalTimeZone())
        timeToMidnight = unixtime - Time.new.to_i
        if totalEstimatedTimeInSeconds > (timeToMidnight-3600) then
            TheSpeedOfLight::decrementLightSpeed()
        end
        if totalEstimatedTimeInSeconds < (timeToMidnight-3600*3) then
            TheSpeedOfLight::incrementLightSpeed()
        end
    end
end
