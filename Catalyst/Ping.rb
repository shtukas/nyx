
# encoding: UTF-8

# require "/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/Catalyst/Ping.rb"
=begin 
    Ping::put(uuid, weight)
    Ping::total24hours(uuid)
    Ping::totalToday(uuid)
=end

require "/Users/pascal/Galaxy/LucilleOS/Libraries/Ruby-Libraries/BTreeSets.rb"
=begin
    BTreeSets::values(repositorylocation or nil, setuuid: String): Array[Value]
    BTreeSets::set(repositorylocation or nil, setuuid: String, valueuuid: String, value)
    BTreeSets::getOrNull(repositorylocation or nil, setuuid: String, valueuuid: String): nil | Value
    BTreeSets::destroy(repositorylocation, setuuid: String, valueuuid: String)
=end

# -----------------------------------------------------------------

class Ping

    # Ping::put(setuuid, weight: Float)
    def self.put(setuuid, weight)
        uuid = Time.new.to_f.to_s
        packet = {
            "uuid" => uuid,
            "weight" => weight,
            "unixtime" => Time.new.to_f,
            "date" => Time.new.to_s[0, 10],
        }
        BTreeSets::set(nil, "42d8f699-64bf-4385-a069-60ab349d0684:#{setuuid}", uuid, packet)
    end

    # Ping::total24hours(setuuid)
    def self.total24hours(setuuid)
        unixtime = Time.new.to_f
        BTreeSets::values(nil, "42d8f699-64bf-4385-a069-60ab349d0684:#{setuuid}")
            .select{|packet| (unixtime- packet["unixtime"]) <= 86400 }
            .map{|packet| packet["weight"] }
            .inject(0, :+)
    end

    # Ping::totalToday(setuuid)
    def self.totalToday(setuuid)
        today = Time.new.to_s[0, 10]
        BTreeSets::values(nil, "42d8f699-64bf-4385-a069-60ab349d0684:#{setuuid}")
            .select{|packet|  today == packet["date"]}
            .map{|packet| packet["weight"] }
            .inject(0, :+)
    end

end