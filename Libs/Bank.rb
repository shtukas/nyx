
# encoding: UTF-8

class Bank

    # Bank::put(setuuid, weight: Float)
    def self.put(setuuid, weight)
        date = CommonUtils::today()

        item = {
          "uuid"     => SecureRandom.uuid,
          "variant"  => SecureRandom.uuid,
          "mikuType" => "NxBankOp",
          "setuuid"  => setuuid,
          "unixtime" => Time.new.to_i,
          "date"     => date,
          "weight"   => weight
        }

        Librarian::commit(item)

        value = Bank::valueAtDate(setuuid, date)
        value = value + weight
        XCache::set("d8feea21-ff06-46b2-b68d-b1d4e23e9a47:#{setuuid}:#{date}", value)
    end

    # Bank::incomingEvent(event)
    def self.incomingEvent(event)
        return if event["mikuType"] != "NxBankOp"
        setuuid = event["setuuid"]
        date = event["date"]
        weight = event["weight"]
        value = Bank::valueAtDate(setuuid, date)
        value = value + weight
        XCache::set("d8feea21-ff06-46b2-b68d-b1d4e23e9a47:#{setuuid}:#{date}", value)
    end

    # Bank::valueAtDate(setuuid, date)
    def self.valueAtDate(setuuid, date)
        value = XCache::getOrNull("d8feea21-ff06-46b2-b68d-b1d4e23e9a47:#{setuuid}:#{date}")
        if value then
            return value.to_f
        end

        #puts "Bank::valueAtDate(#{setuuid}, #{date})"

        value = Librarian::getObjectsByMikuType("NxBankOp")
                    .select{|item| item["setuuid"] == setuuid }
                    .select{|item| item["date"] == date }
                    .map{|item| item["weight"] }
                    .inject(0, :+)

        XCache::set("d8feea21-ff06-46b2-b68d-b1d4e23e9a47:#{setuuid}:#{date}", value)

        value
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
