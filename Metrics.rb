
# encoding: UTF-8

class Metrics

    # Metrics::best7SamplesTimeRatioOverPeriod(bankuuid, timespanInSeconds)
    def self.best7SamplesTimeRatioOverPeriod(bankuuid, timespanInSeconds)
        (1..7)
            .map{|i|
                lookupPeriodInSeconds = timespanInSeconds*(i.to_f/7)
                timedone = Bank::valueOverTimespan(bankuuid, lookupPeriodInSeconds)
                timedone.to_f/lookupPeriodInSeconds
            }
            .max
    end

    # Metrics::recoveredDailyTimeInHours(bankuuid)
    def self.recoveredDailyTimeInHours(bankuuid)
        (Metrics::best7SamplesTimeRatioOverPeriod(bankuuid, 86400*7)*86400).to_f/3600
    end

    # Metrics::achieveDataComputedDailyExpectationInSecondsThenFall(basemetric, bankuuid, dailyExpectationInSeconds)
    def self.achieveDataComputedDailyExpectationInSecondsThenFall(basemetric, bankuuid, dailyExpectationInSeconds)
        recoveredTimeInHours = Metrics::recoveredDailyTimeInHours(bankuuid)
        expectedTimeInHours = dailyExpectationInSeconds.to_f/3600
        if recoveredTimeInHours < expectedTimeInHours then
            basemetric
        else
            extraTimeInMultipleOf10Mins = 6*(recoveredTimeInHours-expectedTimeInHours)
            0.2 + (basemetric-0.2)*Math.exp(-extraTimeInMultipleOf10Mins)
        end
    end

    # Metrics::noMoreThanBankValueOverPeriodOtherwiseFall(basemetric, bankuuid, thresholdInSeconds, lookupPeriodInSeconds)
    def self.noMoreThanBankValueOverPeriodOtherwiseFall(basemetric, bankuuid, thresholdInSeconds, lookupPeriodInSeconds)
        doneInSeconds = Bank::valueOverTimespan(bankuuid, lookupPeriodInSeconds)
        if doneInSeconds < thresholdInSeconds then
            basemetric
        else
            extraTimeInMultipleOf10Mins = (doneInSeconds-thresholdInSeconds).to_f/(10*60)
            0.2 + (basemetric-0.2)*Math.exp(-extraTimeInMultipleOf10Mins)
        end
    end
end
