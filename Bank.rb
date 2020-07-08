
# encoding: UTF-8

require_relative "BTreeSets.rb"
=begin
    BTreeSets::values(repositorylocation or nil, setuuid: String): Array[Value]
    BTreeSets::set(repositorylocation or nil, setuuid: String, valueuuid: String, value)
    BTreeSets::getOrNull(repositorylocation or nil, setuuid: String, valueuuid: String): nil | Value
    BTreeSets::destroy(repositorylocation or nil, setuuid: String, valueuuid: String)
=end

# -----------------------------------------------------------------

class Bank

    # Bank::put(setuuid, weight: Float)
    def self.put(setuuid, weight)
        uuid = Time.new.to_f.to_s
        packet = {
            "uuid" => uuid,
            "weight" => weight,
            "unixtime" => Time.new.to_f
        }
        BTreeSets::set(nil, "42d8f699-64bf-4385-a069-60ab349d0684:#{setuuid}", uuid, packet)
    end

    # Bank::value(setuuid)
    def self.value(setuuid)
        unixtime = Time.new.to_f
        BTreeSets::values(nil, "42d8f699-64bf-4385-a069-60ab349d0684:#{setuuid}")
            .map{|packet| 
                if (unixtime - packet["unixtime"]) > 30*86400 then
                    BTreeSets::destroy(nil, "42d8f699-64bf-4385-a069-60ab349d0684:#{setuuid}", packet["uuid"])
                end
                packet
            }
            .map{|packet| packet["weight"] }
            .inject(0, :+)
    end

    # Bank::valueOverTimespan(setuuid, timespanInSeconds)
    def self.valueOverTimespan(setuuid, timespanInSeconds)
        unixtime = Time.new.to_f
        BTreeSets::values(nil, "42d8f699-64bf-4385-a069-60ab349d0684:#{setuuid}")
            .select{|packet| (unixtime - packet["unixtime"]) <= timespanInSeconds }
            .map{|packet| packet["weight"] }
            .inject(0, :+)
    end
end
