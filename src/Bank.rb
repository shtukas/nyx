
# encoding: UTF-8

class Bank

    # Bank::databaseFilepath()
    def self.databaseFilepath()
        "#{Miscellaneous::catalystDataCenterFolderpath()}/Bank-Accounts.sqlite3"
    end

    # Bank::getTimePackets(setuuid)
    def self.getTimePackets(setuuid)
        db = SQLite3::Database.new(Bank::databaseFilepath())
        db.results_as_hash = true
        answer = []
        db.execute( "select * from table2 where _setuuid_=?" , [setuuid] ) do |row|
            answer << JSON.parse(row['_object_'])
        end
        db.close
        answer
    end

    # Bank::put(setuuid, weight: Float)
    def self.put(setuuid, weight)
        uuid = Time.new.to_f.to_s
        packet = {
            "uuid" => uuid,
            "weight" => weight,
            "unixtime" => Time.new.to_f
        }
        db = SQLite3::Database.new(Bank::databaseFilepath())
        db.transaction 
        db.execute "delete from table2 where _setuuid_=? and _objectuuid_=?", [setuuid, uuid]
        db.execute "insert into table2 (_setuuid_, _objectuuid_, _object_) values ( ?, ?, ? )", [setuuid, uuid, JSON.generate(packet)]
        db.commit 
        db.close
        nil
    end

    # Bank::value(setuuid)
    def self.value(setuuid)
        unixtime = Time.new.to_f
        Bank::getTimePackets(setuuid)
            .map{|packet| packet["weight"] }
            .inject(0, :+)
    end

    # Bank::valueOverTimespan(setuuid, timespanInSeconds)
    def self.valueOverTimespan(setuuid, timespanInSeconds)
        unixtime = Time.new.to_f
        Bank::getTimePackets(setuuid)
                .select{|packet| (unixtime - packet["unixtime"]) <= timespanInSeconds }
                .map{|packet| packet["weight"] }
                .inject(0, :+)
    end
end

class BankExtended

    # BankExtended::best7SamplesTimeRatioOverPeriod(bankuuid, timespanInSeconds)
    def self.best7SamplesTimeRatioOverPeriod(bankuuid, timespanInSeconds)
        (1..7)
            .map{|i|
                lookupPeriodInSeconds = timespanInSeconds*(i.to_f/7)
                timedone = Bank::valueOverTimespan(bankuuid, lookupPeriodInSeconds)
                timedone.to_f/lookupPeriodInSeconds
            }
            .max
    end

    # BankExtended::recoveredDailyTimeInHours(bankuuid)
    def self.recoveredDailyTimeInHours(bankuuid)
        (BankExtended::best7SamplesTimeRatioOverPeriod(bankuuid, 86400*7)*86400).to_f/3600
    end
end