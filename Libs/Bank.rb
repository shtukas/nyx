
# encoding: UTF-8

class BankDataCenter

    def initialize()
        @data = nil
    end

    def reset()
        @data = []
    end

    def incoming(item)
        @data << item
    end

    def rebuild()
        reset()
        Librarian::getObjectsByMikuType("NxBankOp").each{|item|
            incoming(item)
        }
    end

    def data()
        if @data.nil? then
            rebuild()
        end
        @data
    end
end

$BankDataCenter = BankDataCenter.new()

class Bank

    # Bank::put(setuuid, weight: Float)
    def self.put(setuuid, weight)
        item = {
          "uuid"     => SecureRandom.uuid,
          "mikuType" => "NxBankOp",
          "setuuid"  => setuuid,
          "unixtime" => Time.new.to_i,
          "date"     => CommonUtils::today(),
          "weight"   => weight
        }
        Librarian::commit(item)
    end

    # Bank::value(setuuid)
    def self.value(setuuid)
        $BankDataCenter.data()
            .select{|item| item["setuuid"] == setuuid }
            .map{|item| item["weight"] }
            .inject(0, :+)
    end

    # Bank::valueOverTimespan(setuuid, timespanInSeconds)
    def self.valueOverTimespan(setuuid, timespanInSeconds)
        horizon = Time.new.to_i - timespanInSeconds
        $BankDataCenter.data()
            .select{|item| item["setuuid"] == setuuid }
            .select{|item| item["unixtime"] >= horizon }
            .map{|item| item["weight"] }
            .inject(0, :+)
    end

    # Bank::valueAtDate(setuuid, date)
    def self.valueAtDate(setuuid, date)
        $BankDataCenter.data()
            .select{|item| item["setuuid"] == setuuid }
            .select{|item| item["date"] == date }
            .map{|item| item["weight"] }
            .inject(0, :+)
    end

    # Bank::combinedValueOnThoseDays(setuuid, dates)
    def self.combinedValueOnThoseDays(setuuid, dates)
        dates.map{|date| Bank::valueAtDate(setuuid, date) }.inject(0, :+)
    end
end

class BankExtended

    # BankExtended::timeRatioOverDayCount(setuuid, daysCount)
    def self.timeRatioOverDayCount(setuuid, daysCount)
        value = (0..(daysCount-1))
                    .map{|i| CommonUtils::nDaysInTheFuture(-i) }
                    .map{|date| Bank::valueAtDate(setuuid, date) }
                    .inject(0, :+)
        value.to_f/(daysCount*86400)
    end

    # BankExtended::bestTimeRatioWithinDayCount(setuuid, daysCount)
    def self.bestTimeRatioWithinDayCount(setuuid, daysCount)
        (1..daysCount).map{|i| BankExtended::timeRatioOverDayCount(setuuid, i) }.max
    end

    # BankExtended::stdRecoveredDailyTimeInHours(setuuid)
    def self.stdRecoveredDailyTimeInHours(setuuid)
        return 0 if setuuid.nil?
        (BankExtended::bestTimeRatioWithinDayCount(setuuid, 7)*86400).to_f/3600
    end
end
