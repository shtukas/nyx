# encoding: UTF-8

class BankUtils

    # BankUtils::averageHoursPerDayOverThePastNDays(uuid, n)
    # n = 0 corresponds to today
    def self.averageHoursPerDayOverThePastNDays(uuid, n)
        totalInSeconds = (-(n-1)..0).map{|indx| BankCore::getValueAtDate(uuid, CommonUtils::nDaysInTheFuture(indx)) }.inject(0, :+)
        totalInHours = totalInSeconds.to_f/3600
        average = totalInSeconds.to_f/(n+1)
        average
    end

    # BankUtils::recoveredAverageHoursPerDay(uuid)
    def self.recoveredAverageHoursPerDay(uuid)
        (0..6).map{|n| BankUtils::averageHoursPerDayOverThePastNDays(uuid, n) }.max
    end

end
