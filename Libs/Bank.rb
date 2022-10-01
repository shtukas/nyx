# encoding: UTF-8

# create table _bank_ (_eventuuid_ text primary key, _setuuid_ text, _unixtime_ float, _date_ text, _weight_ float);

class Bank

    # Bank::pathToBank()
    def self.pathToBank()
        "#{Config::userHomeDirectory()}/Galaxy/DataBank/Stargate/bank.sqlite3"
    end

    # Bank::insertRecord(row)
    def self.insertRecord(row)
        $bank_database_semaphore.synchronize {
            db = SQLite3::Database.new(Bank::pathToBank())
            db.busy_timeout = 117
            db.busy_handler { |count| true }
            db.execute "delete from _bank_ where _eventuuid_=?", [row["_eventuuid_"]] # (1)
            db.execute "insert into _bank_ (_eventuuid_, _setuuid_, _unixtime_, _date_, _weight_) values (?, ?, ?, ?, ?)", [row["_eventuuid_"], row["_setuuid_"], row["_unixtime_"], row["_date_"], row["_weight_"]]
            db.close
        }
    end

    # Bank::putLibrarianOnly(eventuuid, setuuid, unixtime, date, weight) # Used by regular activity. Emits events for the other computer,
    def self.putLibrarianOnly(eventuuid, setuuid, unixtime, date, weight)
        eventTime = Time.new.to_f
        event = {
            "mikuType"  => "TxBankEvent",
            "eventuuid" => eventuuid,
            "eventTime" => eventTime,
            "setuuid"   => setuuid,
            "unixtime"  => unixtime,
            "date"      => date,
            "weight"    => weight,
        }
        TheLibrarian::processEvent(event)
        event
    end

    # Bank::put(setuuid, weight: Float) # Used by regular activity. Emits events for the other computer,
    def self.put(setuuid, weight)
        eventuuid = SecureRandom.uuid
        unixtime  = Time.new.to_f
        date      = CommonUtils::today()
        event     = Bank::putLibrarianOnly(eventuuid, setuuid, unixtime, date, weight)
        XCache::destroy("256e3994-7469-46a8-abd1-238bb25d5976:#{setuuid}:#{date}") # decaching the value for that date
        SystemEvents::broadcast(event)
        SystemEvents::processAndBroadcast({
            "mikuType" => "(bank account has been updated)",
            "setuuid"  => setuuid,
        })
    end

    # Bank::processEvent(event)
    def self.processEvent(event)
        if event["mikuType"] == "TxBankEvent" then
            TheLibrarian::processEvent(event)
            setuuid   = event["setuuid"]
            date      = event["date"]
            XCache::destroy("256e3994-7469-46a8-abd1-238bb25d5976:#{setuuid}:#{date}") # decaching the value for that date
        end
    end

    # Bank::valueAtDate(setuuid, date)
    def self.valueAtDate(setuuid, date)
        value = XCache::getOrNull("256e3994-7469-46a8-abd1-238bb25d5976:#{setuuid}:#{date}")
        return value.to_f if value

        #{
        #    "mikuType"  => "TxBankEvent",
        #    "eventuuid" => eventuuid,
        #    "eventTime" => Float,
        #    "setuuid"   => setuuid,
        #    "unixtime"  => unixtime,
        #    "date"      => date,
        #    "weight"    => weight
        #}

        value = TheLibrarian::getBankingObjectArrayEventsForSet(setuuid)
                    .select{|event| event["date"] == date }
                    .map{|event| event["weight"] }
                    .inject(0, :+)

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
