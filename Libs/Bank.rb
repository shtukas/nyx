
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

class NxBallsInternal

    # NxBallsInternal::makeNxBall(accounts)
    def self.makeNxBall(accounts)
        start = Time.new.to_f
        nxball = {
            "versionId"      => SecureRandom.hex,
            "startUnixtime"  => start,
            "cursorUnixtime" => start,
            "bankAccounts"   => accounts,
            "ownerCount"     => 1
        }
        #puts "make, returning"
        #puts JSON.pretty_generate(nxball)
        nxball
    end

    # NxBallsInternal::marginCall(nxball, verbose)
    def self.marginCall(nxball, verbose)
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

    # NxBallsInternal::close(nxball, verbose)
    def self.close(nxball, verbose)
        #puts "close, receiving"
        #puts JSON.pretty_generate(nxball)
        puts "(#{Time.new.to_s}) Running for #{((Time.new.to_i-nxball["startUnixtime"]).to_f/3600).round(2)} hours" if verbose
        timespan = Time.new.to_f - nxball["cursorUnixtime"]
        timespan = [timespan, 3600*2].min
        nxball["bankAccounts"].each{|account|
            puts "(#{Time.new.to_s}) putting #{timespan} seconds into account: #{account}" if verbose
            Bank::put(account, timespan)
        }
        nil
    end

    # NxBallsInternal::runningTimeString(nxball)
    def self.runningTimeString(nxball)
        "running for #{((Time.new.to_i-nxball["startUnixtime"]).to_f/3600).round(2)} hours"
    end
end

class NxBallsService

    # Operations

    # NxBallsService::issueOrIncreaseOwnerCount(uuid, accounts)
    def self.issueOrIncreaseOwnerCount(uuid, accounts)
        nxball = KeyValueStore::getOrNull(nil, "6ef1ba9a-b607-41cc-afbb-bf8e2ddadffe:#{uuid}")
        if nxball then
            nxball = JSON.parse(nxball)
            nxball["ownerCount"] = nxball["ownerCount"] + 1
        else
            nxball = NxBallsInternal::makeNxBall(accounts)
        end
        KeyValueStore::set(nil, "6ef1ba9a-b607-41cc-afbb-bf8e2ddadffe:#{uuid}", JSON.generate(nxball))
        nxball
    end

    # NxBallsService::isRunning(uuid)
    def self.isRunning(uuid)
        !KeyValueStore::getOrNull(nil, "6ef1ba9a-b607-41cc-afbb-bf8e2ddadffe:#{uuid}").nil?
    end

    # NxBallsService::marginCall(uuid, verbose)
    def self.marginCall(uuid, verbose)
        nxball = KeyValueStore::getOrNull(nil, "6ef1ba9a-b607-41cc-afbb-bf8e2ddadffe:#{uuid}")
        return if nxball.nil?
        nxball = JSON.parse(nxball)
        nxball = NxBallsInternal::marginCall(nxball, verbose)
        KeyValueStore::set(nil, "6ef1ba9a-b607-41cc-afbb-bf8e2ddadffe:#{uuid}", JSON.generate(nxball))
    end

    # NxBallsService::decreaseOwnerCountOrClose(uuid, verbose)
    def self.decreaseOwnerCountOrClose(uuid, verbose)
        nxball = KeyValueStore::getOrNull(nil, "6ef1ba9a-b607-41cc-afbb-bf8e2ddadffe:#{uuid}")
        return if nxball.nil?
        nxball = JSON.parse(nxball)
        if nxball["ownerCount"] > 1 then
            nxball["ownerCount"] = nxball["ownerCount"] - 1
            KeyValueStore::set(nil, "6ef1ba9a-b607-41cc-afbb-bf8e2ddadffe:#{uuid}", JSON.generate(nxball))
        else
            NxBallsInternal::close(nxball, verbose)
            KeyValueStore::destroy(nil, "6ef1ba9a-b607-41cc-afbb-bf8e2ddadffe:#{uuid}")
        end
    end

    # Information

    # NxBallsService::cursorUnixtimeOrNow(uuid)
    def self.cursorUnixtimeOrNow(uuid)
        nxball = KeyValueStore::getOrNull(nil, "6ef1ba9a-b607-41cc-afbb-bf8e2ddadffe:#{uuid}")
        return Time.new.to_i if nxball.nil?
        nxball = JSON.parse(nxball)
        nxball["cursorUnixtime"]
    end

    # NxBallsService::startUnixtimeOrNow(uuid)
    def self.startUnixtimeOrNow(uuid)
        nxball = KeyValueStore::getOrNull(nil, "6ef1ba9a-b607-41cc-afbb-bf8e2ddadffe:#{uuid}")
        return Time.new.to_i if nxball.nil?
        nxball = JSON.parse(nxball)
        nxball["startUnixtime"]
    end

    # NxBallsService::runningStringOrEmptyString(leftSide, uuid, rightSide)
    def self.runningStringOrEmptyString(leftSide, uuid, rightSide)
        nxball = KeyValueStore::getOrNull(nil, "6ef1ba9a-b607-41cc-afbb-bf8e2ddadffe:#{uuid}")
        return "" if nxball.nil?
        nxball = JSON.parse(nxball)
        "#{leftSide}#{NxBallsInternal::runningTimeString(nxball)}#{rightSide}"
    end
end