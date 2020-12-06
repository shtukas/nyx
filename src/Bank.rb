
# encoding: UTF-8

class Bank

    # Bank::databaseFilepath()
    def self.databaseFilepath()
        "#{Miscellaneous::catalystDataCenterFolderpath()}/Bank-Accounts.sqlite3"
    end

    # Bank::put(setuuid, weight: Float)
    def self.put(setuuid, weight)
        operationuuid = SecureRandom.hex
        unixtime = Time.new.to_i
        db = SQLite3::Database.new(Bank::databaseFilepath())
        db.busy_timeout = 117  
        db.busy_handler { |count| true }
        db.execute "insert into _operations_ (_setuuid_, _operationuuid_ , _unixtime_, _weight_) values (?, ?, ?, ?)", [setuuid, operationuuid, unixtime, weight]
        db.close
        nil
    end

    # Bank::value(setuuid)
    def self.value(setuuid)
        db = SQLite3::Database.new(Bank::databaseFilepath())
        db.busy_timeout = 117  
        db.busy_handler { |count| true }
        db.results_as_hash = true
        answer = []
        db.execute( "select sum(_weight_) as _sum_ from _operations_ where _setuuid_=?" , [setuuid] ) do |row|
            answer = row["_sum_"]
        end
        db.close
        answer
    end

    # Bank::valueOverTimespan(setuuid, timespanInSeconds)
    def self.valueOverTimespan(setuuid, timespanInSeconds)
        horizon = Time.new.to_i - timespanInSeconds
        db = SQLite3::Database.new(Bank::databaseFilepath())
        db.busy_timeout = 117  
        db.busy_handler { |count| true }
        db.results_as_hash = true
        answer = []
        db.execute( "select sum(_weight_) as _sum_ from _operations_ where _setuuid_=? and _unixtime_ > ?" , [setuuid, horizon] ) do |row|
            answer = row["_sum_"]
        end
        db.close
        answer
    end

    # Bank::valueOverTimespanWithConnection(db, setuuid, timespanInSeconds)
    def self.valueOverTimespanWithConnection(db, setuuid, timespanInSeconds)
        horizon = Time.new.to_i - timespanInSeconds
        answer = []
        db.execute( "select sum(_weight_) as _sum_ from _operations_ where _setuuid_=? and _unixtime_ > ?" , [setuuid, horizon] ) do |row|
            answer = row["_sum_"]
        end
        answer
    end
end

class BankExtended

    # BankExtended::best7SamplesTimeRatioOverPeriod(bankuuid, timespanInSeconds)
    def self.best7SamplesTimeRatioOverPeriod(bankuuid, timespanInSeconds)
        db = SQLite3::Database.new(Bank::databaseFilepath())
        db.busy_timeout = 117  
        db.busy_handler { |count| true }
        db.results_as_hash = true
        value = (1..7)
                    .map{|i|
                        lookupPeriodInSeconds = timespanInSeconds*(i.to_f/7)
                        timedone = Bank::valueOverTimespanWithConnection(db, bankuuid, lookupPeriodInSeconds)
                        timedone.to_f/lookupPeriodInSeconds
                    }
                    .max
        db.close
        value
    end

    # BankExtended::recoveredDailyTimeInHours(bankuuid)
    def self.recoveredDailyTimeInHours(bankuuid)
        (BankExtended::best7SamplesTimeRatioOverPeriod(bankuuid, 86400*7)*86400).to_f/3600
    end
end