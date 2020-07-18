
# encoding: UTF-8

class Bank

    # Bank::getTimePackets(setuuid)
    def self.getTimePackets(setuuid)
        packets = KeyToJsonNSerialisbleValueInMemoryAndOnDiskStore::getOrNull("13db7087-828d-4f99-b712-5ca42665d2a7:#{setuuid}")
        return packets if packets
        packets = BTreeSets::values(nil, "42d8f699-64bf-4385-a069-60ab349d0684:#{setuuid}")
        KeyToJsonNSerialisbleValueInMemoryAndOnDiskStore::set("13db7087-828d-4f99-b712-5ca42665d2a7:#{setuuid}", packets)
        packets
    end

    # Bank::put(setuuid, weight: Float)
    def self.put(setuuid, weight)
        uuid = Time.new.to_f.to_s
        packet = {
            "uuid" => uuid,
            "weight" => weight,
            "unixtime" => Time.new.to_f
        }
        BTreeSets::set(nil, "42d8f699-64bf-4385-a069-60ab349d0684:#{setuuid}", uuid, packet)
        KeyToJsonNSerialisbleValueInMemoryAndOnDiskStore::delete("13db7087-828d-4f99-b712-5ca42665d2a7:#{setuuid}")
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