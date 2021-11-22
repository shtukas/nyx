
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

=begin

NxBallStatus 
    {
        "type" : "running",
        "startUnixtime"  => start,
        "cursorUnixtime" => start,
    }
    {
        "type" : "paused",
    }

NxBall {
    "uuid"        => String,
    "NS198"       => "NxBall.v1",
    "description" => description,
    "status"      => NxBallStatus 
    "accounts"    => accounts
}

=end

class NxBallsService

    # Operations

    # NxBallsService::issue(uuid, description, accounts)
    def self.issue(uuid, description, accounts)
        return if BTreeSets::getOrNull(nil, "a69583a5-8a13-46d9-a965-86f95feb6f68", uuid)
        start = Time.new.to_f
        nxball = {
            "uuid" => uuid,
            "NS198" => "NxBall.v2",
            "description" => description,
            "status" => {
                "type" => "running",
                "startUnixtime" => start,
                "cursorUnixtime" => start,
            },
            "accounts" => accounts
        }
        BTreeSets::set(nil, "a69583a5-8a13-46d9-a965-86f95feb6f68", uuid, nxball)
    end

    # NxBallsService::isRunning(uuid)
    def self.isRunning(uuid)
        nxball = BTreeSets::getOrNull(nil, "a69583a5-8a13-46d9-a965-86f95feb6f68", uuid)
        return false if nxball.nil?
        nxball["status"]["type"] == "running"
    end

    # NxBallsService::marginCall(uuid)
    def self.marginCall(uuid)
        nxball = BTreeSets::getOrNull(nil, "a69583a5-8a13-46d9-a965-86f95feb6f68", uuid)
        return if nxball.nil?
        return if nxball["status"]["type"] != "running"
        timespan = Time.new.to_f - nxball["status"]["cursorUnixtime"]
        timespan = [timespan, 3600*2].min
        nxball["accounts"].each{|account|
            Bank::put(account, timespan)
        }
        nxball["status"]["cursorUnixtime"] = Time.new.to_i
        BTreeSets::set(nil, "a69583a5-8a13-46d9-a965-86f95feb6f68", uuid, nxball)
    end

    # NxBallsService::pursue(uuid)
    def self.pursue(uuid)
        nxball = BTreeSets::getOrNull(nil, "a69583a5-8a13-46d9-a965-86f95feb6f68", uuid)
        return if nxball.nil?
        NxBallsService::close(uuid, true)
        NxBallsService::issue(uuid, nxball["description"], nxball["accounts"])
    end

    # NxBallsService::pause(uuid)
    def self.pause(uuid)
        nxball = BTreeSets::getOrNull(nil, "a69583a5-8a13-46d9-a965-86f95feb6f68", uuid)
        return if nxball.nil?
        NxBallsService::close(uuid, true)
        nxball = {
            "uuid" => nxball["uuid"],
            "NS198" => "NxBall.v2",
            "description" => nxball["description"],
            "status" => {
                "type" => "paused",
            },
            "accounts" => nxball["accounts"]
        }
        BTreeSets::set(nil, "a69583a5-8a13-46d9-a965-86f95feb6f68", uuid, nxball)

    end

    # NxBallsService::close(uuid, verbose)
    def self.close(uuid, verbose)
        nxball = BTreeSets::getOrNull(nil, "a69583a5-8a13-46d9-a965-86f95feb6f68", uuid)
        return if nxball.nil?
        if nxball["status"]["type"] == "running" then
            if verbose then
                puts "(#{Time.new.to_s}) Running for #{((Time.new.to_i-nxball["status"]["startUnixtime"]).to_f/3600).round(2)} hours"
            end
            timespan = Time.new.to_f - nxball["status"]["cursorUnixtime"]
            timespan = [timespan, 3600*2].min
            nxball["accounts"].each{|account|
                puts "(#{Time.new.to_s}) putting #{timespan} seconds into account: #{account}" if verbose
                Bank::put(account, timespan)
            }
        end
        if nxball["status"]["type"] == "paused" then
            if verbose then
                puts "(#{Time.new.to_s}) Closing paused NxBall"
            end
        end
        BTreeSets::destroy(nil, "a69583a5-8a13-46d9-a965-86f95feb6f68", uuid)
    end

    # NxBallsService::closeWithAsking(uuid)
    def self.closeWithAsking(uuid)
        nxball = BTreeSets::getOrNull(nil, "a69583a5-8a13-46d9-a965-86f95feb6f68", uuid)
        return if nxball.nil?
        if !LucilleCore::askQuestionAnswerAsBoolean("(#{Time.new.to_s}) Running '#{nxball["description"]}'. Continue ? ") then
            NxBallsService::close(uuid, true)
        end
    end

    # Information

    # NxBallsService::cursorUnixtimeOrNow(uuid)
    def self.cursorUnixtimeOrNow(uuid)
        nxball = BTreeSets::getOrNull(nil, "a69583a5-8a13-46d9-a965-86f95feb6f68", uuid)
        if nxball.nil? then
            return Time.new.to_i 
        end
        if nxball["status"]["type"] == "paused" then
            return Time.new.to_i 
        end
        nxball["status"]["cursorUnixtime"]
    end

    # NxBallsService::startUnixtimeOrNow(uuid)
    def self.startUnixtimeOrNow(uuid)
        nxball = BTreeSets::getOrNull(nil, "a69583a5-8a13-46d9-a965-86f95feb6f68", uuid)
        if nxball.nil? then
            return Time.new.to_i 
        end
        if nxball["status"]["type"] == "paused" then
            return Time.new.to_i 
        end
        nxball["status"]["startUnixtime"]
    end

    # NxBallsService::runningStringOrEmptyString(leftSide, uuid, rightSide)
    def self.runningStringOrEmptyString(leftSide, uuid, rightSide)
        nxball = BTreeSets::getOrNull(nil, "a69583a5-8a13-46d9-a965-86f95feb6f68", uuid)
        if nxball.nil? then
            return ""
        end
        if nxball["status"]["type"] == "paused" then
            return "#{leftSide}paused#{rightSide}"
        end
        "#{leftSide}running for #{((Time.new.to_i-nxball["status"]["startUnixtime"]).to_f/3600).round(2)} hours#{rightSide}"
    end
end

Thread.new {
    loop {
        sleep 60

        BTreeSets::values(nil, "a69583a5-8a13-46d9-a965-86f95feb6f68").each{|nxball|
            uuid = nxball["uuid"]
            next if (Time.new.to_i - NxBallsService::cursorUnixtimeOrNow(uuid)) < 600
            NxBallsService::marginCall(uuid)
        }

        BTreeSets::values(nil, "a69583a5-8a13-46d9-a965-86f95feb6f68").each{|nxball|
            uuid = nxball["uuid"]
            next if (Time.new.to_i - NxBallsService::startUnixtimeOrNow(uuid)) < 3600
            Utils::onScreenNotification("Catalyst", "NxBall running for more than an hour")
        }
        
    }
}
