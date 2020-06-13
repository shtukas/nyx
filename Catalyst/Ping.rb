
# encoding: UTF-8

# require "/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/Catalyst/Ping.rb"
=begin 
    Ping::put(uuid, weight)
    Ping::totalOverTimespan(uuid, timespanInSeconds)
    Ping::totalToday(uuid)
=end

require "/Users/pascal/Galaxy/LucilleOS/Libraries/Ruby-Libraries/BTreeSets.rb"
=begin
    BTreeSets::values(repositorylocation or nil, uuid: String): Array[Value]
    BTreeSets::set(repositorylocation or nil, uuid: String, valueuuid: String, value)
    BTreeSets::getOrNull(repositorylocation or nil, uuid: String, valueuuid: String): nil | Value
    BTreeSets::destroy(repositorylocation, uuid: String, valueuuid: String)
=end

# -----------------------------------------------------------------

class Ping

    # Ping::put(uuid, weight: Float)
    def self.put(uuid, weight)
        packet = {
            "uuid" => uuid,
            "weight" => weight,
            "unixtime" => Time.new.to_f,
            "date" => Time.new.to_s[0, 10],
        }
        BTreeSets::set(nil, "42d8f699-64bf-4385-a069-60ab349d0684:#{uuid}", uuid, packet)
    end

    # Ping::totalToday(uuid)
    def self.totalToday(uuid)
        today = Time.new.to_s[0, 10]
        BTreeSets::values(nil, "42d8f699-64bf-4385-a069-60ab349d0684:#{uuid}")
            .select{|packet|  today == packet["date"]}
            .map{|packet| packet["weight"] }
            .inject(0, :+)
    end

    # Ping::totalOverTimespan(uuid, timespanInSeconds)
    def self.totalOverTimespan(uuid, timespanInSeconds)
        unixtime = Time.new.to_f
        BTreeSets::values(nil, "42d8f699-64bf-4385-a069-60ab349d0684:#{uuid}")
            .select{|packet| (unixtime- packet["unixtime"]) <= timespanInSeconds }
            .map{|packet| packet["weight"] }
            .inject(0, :+)
    end

    # Ping::totalWithTimeExponentialDecay(uuid, timeToMinusOneInSeconds)
    def self.totalWithTimeExponentialDecay(uuid, timeToMinusOneInSeconds)
        unixtime = Time.new.to_f
        BTreeSets::values(nil, "42d8f699-64bf-4385-a069-60ab349d0684:#{uuid}")
            .map{|packet| packet["weight"]*Math.exp(-(unixtime - packet["unixtime"]).to_f/timeToMinusOneInSeconds)}
            .inject(0, :+)
    end

end