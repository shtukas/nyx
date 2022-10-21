# encoding: UTF-8

class Bank

    # Bank::put(setuuid, weight: Float) # Used by regular activity. Emits events for the other computer,
    def self.put(setuuid, weight)
        variant = {
            "uuid"        => SecureRandom.uuid,
            "phage_uuid"  => SecureRandom.uuid,
            "phage_time"  => Time.new.to_f,
            "phage_alive" => true,
            "mikuType"    => "TxBankEvent",
            "unixtime"    => Time.new.to_i,
            "datetime"    => Time.new.utc.iso8601,
            "setuuid"     => setuuid,
            "date"        => CommonUtils::today(),
            "weight"      => weight
        }

        FileSystemCheck::fsck_MikuTypedItem(variant, SecureRandom.hex, false)

        filepath = "#{Config::pathToDataCenter()}/Bank/#{variant["setuuid"]}/#{variant["uuid"]}.json"
        if !File.exists?(File.dirname(filepath)) then
            FileUtils.mkpath(File.dirname(filepath))
        end
        File.open(filepath, "w"){|f| f.puts(JSON.pretty_generate(variant)) }

        XCache::destroy("256e3994-7469-46a8-abd2-238bb25d5976:#{setuuid}:#{CommonUtils::today()}")
    end

    # Bank::valueAtDate(setuuid, date)
    def self.valueAtDate(setuuid, date)
        value = XCache::getOrNull("256e3994-7469-46a8-abd2-238bb25d5976:#{setuuid}:#{CommonUtils::today()}")
        return value.to_f if value

        folderpath = "#{Config::pathToDataCenter()}/Bank/#{setuuid}"

        return 0 if !File.exists?(folderpath)

        value = LucilleCore::locationsAtFolder(folderpath)
                    .select{|filepath| filepath[-5, 5] == ".json" }
                    .map{|filepath| JSON.parse(IO.read(filepath)) }
                    .select{|item| item["setuuid"] == setuuid } # redundant
                    .select{|item| item["date"] == date }
                    .map{|item| item["weight"] }
                    .inject(0, :+)

        XCache::set("256e3994-7469-46a8-abd2-238bb25d5976:#{setuuid}:#{CommonUtils::today()}", value)

        value
    end

    # Bank::combinedValueOnThoseDays(setuuid, dates)
    def self.combinedValueOnThoseDays(setuuid, dates)
        dates.map{|date| Bank::valueAtDate(setuuid, date) }.inject(0, :+)
    end
end

class BankExtended

    # BankExtended::lastWeekHoursDone(setuuid)
    def self.lastWeekHoursDone(setuuid)
        (-6..0).map{|i| CommonUtils::nDaysInTheFuture(i) }.map{|date| Bank::valueAtDate(setuuid, date).to_f/3600 }
    end

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
