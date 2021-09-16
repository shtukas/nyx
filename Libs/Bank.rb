
# encoding: UTF-8

$BankInMemorySetuuidDateToValueStore = {}

class Bank

    # Bank::databaseFilepath()
    def self.databaseFilepath()
        "#{Utils::catalystDataCenterFolderpath()}/Bank.sqlite3"
    end

    # Bank::put(setuuid, weight: Float)
    def self.put(setuuid, weight)
        operationuuid = SecureRandom.uuid
        unixtime = Time.new.to_i
        date = Utils::today()
        db = SQLite3::Database.new(Bank::databaseFilepath())
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.execute "insert into _operations2_ (_setuuid_, _operationuuid_ , _unixtime_, _date_, _weight_) values (?,?,?,?,?)", [setuuid, operationuuid, unixtime, date, weight]
        db.close

        $BankInMemorySetuuidDateToValueStore["#{Utils::today()}-#{setuuid}-#{Utils::today()}"] = Bank::valueAtDateUseTheForce(setuuid, Utils::today())

        nil
    end

    # Bank::value(setuuid)
    def self.value(setuuid)
        db = SQLite3::Database.new(Bank::databaseFilepath())
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        answer = 0
        db.execute( "select sum(_weight_) as _sum_ from _operations2_ where _setuuid_=?" , [setuuid] ) do |row|
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
        answer = 0
        db.execute( "select sum(_weight_) as _sum_ from _operations2_ where _setuuid_=? and _unixtime_ > ?" , [setuuid, horizon] ) do |row|
            answer = (row["_sum_"] || 0)
        end
        db.close
        answer
    end

    # Bank::valueAtDateUseTheForce(setuuid, date)
    def self.valueAtDateUseTheForce(setuuid, date)
        db = SQLite3::Database.new(Bank::databaseFilepath())
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        answer = 0
        db.execute( "select sum(_weight_) as _sum_ from _operations2_ where _setuuid_=? and _date_=?" , [setuuid, date] ) do |row|
            answer = (row["_sum_"] || 0)
        end
        db.close
        answer
    end

    # Bank::valueAtDate(setuuid, date)
    def self.valueAtDate(setuuid, date)

        computationCore = lambda{|setuuid, date|
            db = SQLite3::Database.new(Bank::databaseFilepath())
            db.busy_timeout = 117
            db.busy_handler { |count| true }
            db.results_as_hash = true
            answer = 0
            db.execute( "select sum(_weight_) as _sum_ from _operations2_ where _setuuid_=? and _date_=?" , [setuuid, date] ) do |row|
                answer = (row["_sum_"] || 0)
            end
            db.close
            answer
        }

        if $BankInMemorySetuuidDateToValueStore["#{Utils::today()}-#{setuuid}-#{date}"].nil? then
            $BankInMemorySetuuidDateToValueStore["#{Utils::today()}-#{setuuid}-#{date}"] = Bank::valueAtDateUseTheForce(setuuid, date)
        end
        
        $BankInMemorySetuuidDateToValueStore["#{Utils::today()}-#{setuuid}-#{date}"]
    end
end

class BankExtended

    # BankExtended::timeRatioOverDayCount(setuuid, daysCount)
    def self.timeRatioOverDayCount(setuuid, daysCount)
        value = (0..(daysCount-1))
                    .map{|i| Utils::nDaysInTheFuture(-i) }
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
        (BankExtended::bestTimeRatioWithinDayCount(setuuid, 7)*86400).to_f/3600
    end
end

class Beatrice

    # Beatrice::timeRatioOverHoursCount(setuuid, hoursCount)
    def self.timeRatioOverHoursCount(setuuid, hoursCount)
        Bank::valueOverTimespan(setuuid, 3600*hoursCount).to_f/(3600*hoursCount)
    end

    # Beatrice::bestTimeRatioWithinHoursCount(setuuid, hoursCount)
    def self.bestTimeRatioWithinHoursCount(setuuid, hoursCount)
        (1..hoursCount).map{|i| Beatrice::timeRatioOverHoursCount(setuuid, i) }.max
    end

    # Beatrice::stdRecoveredHourlyTimeInHours(setuuid)
    def self.stdRecoveredHourlyTimeInHours(setuuid)
        Beatrice::bestTimeRatioWithinHoursCount(setuuid, 6)
    end
end

class NxBalls

    # NxBalls::makeNxBall(accounts)
    def self.makeNxBall(accounts)
        start = Time.new.to_f
        nxball = {
            "versionId"      => SecureRandom.hex,
            "startUnixtime"  => start,
            "cursorUnixtime" => start,
            "bankAccounts"   => accounts
        }
        #puts "make, returning"
        #puts JSON.pretty_generate(nxball)
        nxball
    end

    # NxBalls::upgradeNxBall(nxball, verbose)
    def self.upgradeNxBall(nxball, verbose)
        #puts "upgrade, receiving"
        #puts JSON.pretty_generate(nxball)
        timespan = Time.new.to_f - nxball["cursorUnixtime"]
        timespan = [timespan, 3600*2].min
        nxball["bankAccounts"].each{|account|
            puts "#{Time.new.to_s} putting #{timespan} seconds into account: #{account}" if verbose
            Bank::put(account, timespan)
        }
        nxball["cursorUnixtime"] = Time.new.to_i
        nxball["versionId"] = SecureRandom.hex
        #puts "upgrade, returning"
        #puts JSON.pretty_generate(nxball)
        nxball
    end

    # NxBalls::closeNxBall(nxball, verbose)
    def self.closeNxBall(nxball, verbose)
        #puts "close, receiving"
        #puts JSON.pretty_generate(nxball)
        puts "#{Time.new.to_s} Running for #{((Time.new.to_i-nxball["startUnixtime"]).to_f/3600).round(2)} hours" if verbose
        timespan = Time.new.to_f - nxball["cursorUnixtime"]
        timespan = [timespan, 3600*2].min
        nxball["bankAccounts"].each{|account|
            puts "#{Time.new.to_s} putting #{timespan} seconds into account: #{account}" if verbose
            Bank::put(account, timespan)
        }
        nil
    end

    # NxBalls::runningTimeString(nxball)
    def self.runningTimeString(nxball)
        "running for #{((Time.new.to_i-nxball["startUnixtime"]).to_f/3600).round(2)} hours"
    end
end