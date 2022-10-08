# encoding: UTF-8

# create table _bank_ (_eventuuid_ text primary key, _setuuid_ text, _unixtime_ float, _date_ text, _weight_ float);

class Bank

    # Bank::pathToDatabase()
    def self.pathToDatabase()
        "#{Config::userHomeDirectory()}/Galaxy/DataBank/Stargate-Databases/bank.sqlite3"
    end

    # Bank::put(setuuid, weight: Float) # Used by regular activity. Emits events for the other computer,
    def self.put(setuuid, weight)
        db = SQLite3::Database.new(Bank::pathToDatabase())
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        db.execute "insert into _bank_ (_setuuid_, _unixtime_, _date_, _weight_) values (?, ?, ?, ?)", [setuuid, Time.new.to_i, CommonUtils::today(), weight]
        db.close
        SystemEvents::broadcast({
            "mikuType"  => "TxBankEvent",
            "setuuid"   => setuuid,
            "unixtime"  => Time.new.to_i,
            "date"      => CommonUtils::today(),
            "weight"    => weight
        })
    end

    # Bank::processEvent(event)
    def self.processEvent(event)
        if event["mikuType"] == "TxBankEvent" then
            FileSystemCheck::fsckTxBankEvent(event, SecureRandom.hex, false)
            setuuid  = event["event"]
            unixtime = event["unixtime"]
            date     = event["date"]
            weight   = event["weight"]
            db = SQLite3::Database.new(Bank::pathToDatabase())
            db.busy_timeout = 117
            db.busy_handler { |count| true }
            db.results_as_hash = true
            db.execute "insert into _bank_ (_setuuid_, _unixtime_, _date_, _weight_) values (?, ?, ?, ?)", [setuuid, unixtime, date, weight]
            db.close
            XCache::destroy("256e3994-7469-46a8-abd1-238bb25d5976:#{setuuid}:#{date}") # decaching the value for that date
        end
    end

    # Bank::valueAtDate(setuuid, date)
    def self.valueAtDate(setuuid, date)
        value = XCache::getOrNull("256e3994-7469-46a8-abd1-238bb25d5976:#{setuuid}:#{date}")
        return value.to_f if value

        db = SQLite3::Database.new(Bank::pathToDatabase())
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        value = 0
        db.execute("select * from _bank_ where _setuuid_=? and _date_=?", [setuuid, date]) do |row|
            value = value + row["_weight_"]
        end
        db.close
        value

        XCache::set("256e3994-7469-46a8-abd1-238bb25d5976:#{setuuid}:#{date}", value)

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
