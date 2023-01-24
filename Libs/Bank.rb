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

    # Bank::put(setuuid, weight: Float) # Used by regular activity. Emits events for the other computer,
    def self.put(setuuid, weight)
        instanceId = Config::thisInstanceId()
        filepath = Bank::databaseFilepath(instanceId)
        db = SQLite3::Database.new(filepath)
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        db.execute "insert into _bank_ (_recorduuid_, _setuuid_, _unixtime_, _date_, _weight_) values (?, ?, ?, ?, ?)", [SecureRandom.uuid, setuuid, Time.new.to_i, CommonUtils::today(), weight]
        db.close
    end

    # Bank::valueAtDate(setuuid, date, unrealisedTimespan = nil)
    def self.valueAtDate(setuuid, date, unrealisedTimespan = nil)
        unrealisedTimespan = 
            if date == CommonUtils::today() and unrealisedTimespan then
                unrealisedTimespan
            else
                0
            end
        prefix = Config::allInstanceIds()
                    .map{|instanceId| Bank::databaseFilepath(instanceId) }
                    .map{|filepath| File.mtime(filepath).to_s }
                    .join(":")

        cachekey = "#{prefix}:#{setuuid}:#{date}"
        value = XCache::getOrNull(cachekey)
        if value then
            return value.to_f + unrealisedTimespan
        end

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
        value + unrealisedTimespan
    end

    # Bank::combinedValueOnThoseDays(setuuid, dates, unrealisedTimespan = nil)
    def self.combinedValueOnThoseDays(setuuid, dates, unrealisedTimespan = nil)
        dates.map{|date| Bank::valueAtDate(setuuid, date, unrealisedTimespan)}.inject(0, :+)
    end
end

class BankExtended

    # BankExtended::lastWeekHoursDone(setuuid)
    def self.lastWeekHoursDone(setuuid)
        (-6..0).map{|i| CommonUtils::nDaysInTheFuture(i) }.map{|date| Bank::valueAtDate(setuuid, date).to_f/3600 }
    end

    # BankExtended::timeRatioOverDayCount(setuuid, daysCount, unrealisedTimespan = nil)
    def self.timeRatioOverDayCount(setuuid, daysCount, unrealisedTimespan = nil)
        value = (0..(daysCount-1))
                    .map{|i| CommonUtils::nDaysInTheFuture(-i) }
                    .map{|date| Bank::valueAtDate(setuuid, date, unrealisedTimespan)}
                    .inject(0, :+)
        value.to_f/(daysCount*86400)
    end

    # BankExtended::bestTimeRatioWithinDayCount(setuuid, daysCount, unrealisedTimespan = nil)
    def self.bestTimeRatioWithinDayCount(setuuid, daysCount, unrealisedTimespan = nil)
        (1..daysCount).map{|i| BankExtended::timeRatioOverDayCount(setuuid, i, unrealisedTimespan) }.max
    end

    # BankExtended::stdRecoveredDailyTimeInHours(setuuid, unrealisedTimespan = nil)
    def self.stdRecoveredDailyTimeInHours(setuuid, unrealisedTimespan = nil)
        (BankExtended::bestTimeRatioWithinDayCount(setuuid, 7, unrealisedTimespan)*86400).to_f/3600
    end
end

class BankEstimations

    # BankEstimations::itemsEstimationInSeconds(item)
    def self.itemsEstimationInSeconds(item)
        numbers = (-6..-1).map{|i| Bank::valueAtDate(item["uuid"], CommonUtils::nDaysInTheFuture(i), nil)}
        numbers.sum.to_f/6
    end
end
