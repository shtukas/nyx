
# encoding: UTF-8

class Metrics

    # Metrics::achieveDataComputedDailyExpectationInSecondsThenFall(basemetric, bankuuid, dailyExpectationInSeconds)
    def self.achieveDataComputedDailyExpectationInSecondsThenFall(basemetric, bankuuid, dailyExpectationInSeconds)
        recoveredTimeInHours = BankExtended::recoveredDailyTimeInHours(bankuuid)
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
