# encoding: UTF-8

class Metrics

    # Metrics::lift1(ns16s, starting)
    def self.lift1(ns16s, starting)
        cursor = -1
        ns16s.map{|ns16|
            cursor = cursor + 1
            ns16["metric"] = starting + cursor.to_f/1000
            ns16
        }
    end

    # Metrics::baseMetric1(currentRT, targetRT)
    def self.baseMetric1(currentRT, targetRT)
        0.7 * (currentRT.to_f/targetRT)
    end

    # Metrics::baseMetric2(accountId, targetRT)
    def self.baseMetric2(accountId, targetRT)
        rt = BankExtended::stdRecoveredDailyTimeInHours(accountId)
        Metrics::baseMetric1(rt, targetRT)
    end
end
