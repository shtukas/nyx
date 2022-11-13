# encoding: UTF-8

class Bank

    # Bank::databaseFilepath(instanceId)
    def self.databaseFilepath(instanceId)
        filepath = "#{Config::pathToDataCenter()}/Bank/bank-#{instanceId}.sqlite"
        if !File.exists?(filepath) then
            db = SQLite3::Database.new(filepath)
            db.busy_timeout = 117
            db.busy_handler { |count| true }
            db.results_as_hash = true
            db.execute "create table _bank_ (_recorduuid_ text primary key, _setuuid_ text, _unixtime_ float, _date_ text, _weight_ float);", []
            db.close
        end
        filepath
    end

    # Bank::put_direct_no_loan_accountancy(setuuid, weight: Float)
    def self.put_direct_no_loan_accountancy(setuuid, weight)
        instanceId = Config::thisInstanceId()
        filepath = Bank::databaseFilepath(instanceId)
        db = SQLite3::Database.new(filepath)
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        db.execute "insert into _bank_ (_recorduuid_, _setuuid_, _unixtime_, _date_, _weight_) values (?, ?, ?, ?, ?)", [SecureRandom.uuid, setuuid, Time.new.to_i, CommonUtils::today(), weight]
        db.close
    end

    # Bank::put(setuuid, weight: Float) # Used by regular activity. Emits events for the other computer,
    def self.put(setuuid, weight)
        Bank::put_direct_no_loan_accountancy(setuuid, weight)
    end

    # Bank::valueAtDate(setuuid, date)
    def self.valueAtDate(setuuid, date)
        prefix = Config::allInstanceIds()
                    .map{|instanceId| Bank::databaseFilepath(instanceId) }
                    .map{|filepath| File.mtime(filepath).to_s }
                    .join(":")

        cachekey = "#{prefix}:#{setuuid}:#{date}"
        value = XCache::getOrNull(cachekey)
        return value.to_f if value

        value = 0

        Config::allInstanceIds().each{|instanceId|
            filepath = Bank::databaseFilepath(instanceId)
            db = SQLite3::Database.new(filepath)
            db.busy_timeout = 117
            db.busy_handler { |count| true }
            db.results_as_hash = true
            db.execute("select * from _bank_ where _setuuid_=? and _date_=?", [setuuid, date]) do |row|
                value = value + row["_weight_"]
            end
            db.close
        }

        XCache::set(cachekey, value)
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
