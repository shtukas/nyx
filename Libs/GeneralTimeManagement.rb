class GeneralTimeManagement

    # GeneralTimeManagement::bankTimeEstimationInSeconds(item)
    def self.bankTimeEstimationInSeconds(item)
        numbers = (-6..-1).map{|i| Bank::valueAtDate(item["uuid"], CommonUtils::nDaysInTheFuture(i), nil)}
        numbers.sum.to_f/6
    end

    # GeneralTimeManagement::manageSpeedOfLight(pendingTimeTodayInSeconds)
    def self.manageSpeedOfLight(pendingTimeTodayInSeconds)
        unixtime = CommonUtils::unixtimeAtComingMidnightAtGivenTimeZone(CommonUtils::getLocalTimeZone())
        timeToMidnight = unixtime - Time.new.to_i
        if pendingTimeTodayInSeconds > (timeToMidnight-3600*1) then
            TheSpeedOfLight::decrementLightSpeed()
        end
        if pendingTimeTodayInSeconds < (timeToMidnight-3600*2) then
            TheSpeedOfLight::incrementLightSpeed()
        end
    end

end
