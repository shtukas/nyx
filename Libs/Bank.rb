# encoding: UTF-8

# create table _bank_ (_eventuuid_ text primary key, _setuuid_ text, _unixtime_ float, _date_ text, _weight_ float);

class Bank

    # Bank::pathToBank()
    def self.pathToBank()
        "/Users/pascal/Galaxy/DataBank/Stargate/bank.sqlite3"
    end

    # Bank::putNoEvent(eventuuid, setuuid, unixtime, date, weight) # Used by regular activity. Emits events for the other computer,
    def self.putNoEvent(eventuuid, setuuid, unixtime, date, weight)
        $database_semaphore.synchronize {
            db = SQLite3::Database.new(Bank::pathToBank())
            db.busy_timeout = 117
            db.busy_handler { |count| true }
            db.execute "delete from _bank_ where _eventuuid_=?", [eventuuid] # (1)
            db.execute "insert into _bank_ (_eventuuid_, _setuuid_, _unixtime_, _date_, _weight_) values (?, ?, ?, ?, ?)", [eventuuid, setuuid, unixtime, date, weight]
            db.close
        }

        # (1) In principle this is not needed because the eventuuids are unique, but
        # I once copied a bank file from one computer to the other before the events
        # propagated and we were trying to insert eventuuids that already existed.
    end

    # Bank::put(setuuid, weight: Float) # Used by regular activity. Emits events for the other computer,
    def self.put(setuuid, weight)
        eventuuid = SecureRandom.uuid
        unixtime  = Time.new.to_f
        date      = CommonUtils::today()
        Bank::putNoEvent(eventuuid, setuuid, unixtime, date, weight)

        event = {
          "uuid"     => eventuuid,
          "mikuType" => "NxBankEvent",
          "setuuid"  => setuuid,
          "unixtime" => unixtime,
          "date"     => date,
          "weight"   => weight
        }
        EventsToAWSQueue::publish(event)
    end

    # Bank::incomingEvent(event)
    def self.incomingEvent(event)
        return if event["mikuType"] != "NxBankEvent"
        eventuuid = event["uuid"]
        setuuid   = event["setuuid"]
        unixtime  = event["unixtime"]
        date      = event["date"]
        weight    = event["weight"]
        Bank::putNoEvent(eventuuid, setuuid, unixtime, date, weight)
    end

    # Bank::valueAtDate(setuuid, date)
    def self.valueAtDate(setuuid, date)
        value = 0
        $database_semaphore.synchronize {
            db = SQLite3::Database.new(Bank::pathToBank())
            db.busy_timeout = 117
            db.busy_handler { |count| true }
            db.results_as_hash = true
            db.execute("select * from _bank_ where _setuuid_=? and _date_=?", [setuuid, date]) do |row|
                value = value + row['_weight_']
            end
        }
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
