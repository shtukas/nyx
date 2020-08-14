
# encoding: UTF-8

BankDatabaseFilepath = "/Users/pascal/Galaxy/DataBank/Catalyst/bank-numbers.sqlite3"

$X4F0E7A2B = Dionysus2::getDatabaseProxy(BankDatabaseFilepath)

class Bank

    # Bank::getTimePackets(setuuid)
    def self.getTimePackets(setuuid)
        Dionysus2::sets_getObjects($X4F0E7A2B, setuuid)
    end

    # Bank::put(setuuid, weight: Float)
    def self.put(setuuid, weight)
        uuid = Time.new.to_f.to_s
        packet = {
            "uuid" => uuid,
            "weight" => weight,
            "unixtime" => Time.new.to_f
        }
        Dionysus2::sets_putObject($X4F0E7A2B, setuuid, uuid, packet)
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

    # BankExtended::hasReachedDailyTimeTargetInHours(bankuuid, timeTargetInHours)
    def self.hasReachedDailyTimeTargetInHours(bankuuid, timeTargetInHours)
        BankExtended::recoveredDailyTimeInHours(bankuuid) >= timeTargetInHours
    end
end