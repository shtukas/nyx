
# encoding: UTF-8

# require "/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/Catalyst/Bank.rb"
=begin 
    Bank::put(uuid, weight, validityTimespan)
    Bank::total(uuid)
=end

require "/Users/pascal/Galaxy/LucilleOS/Software-Common/Ruby-Libraries/BTreeSets.rb"
=begin
    BTreeSets::values(repositorylocation or nil, setuuid: String): Array[Value]
    BTreeSets::set(repositorylocation or nil, setuuid: String, valueuuid: String, value)
    BTreeSets::getOrNull(repositorylocation or nil, setuuid: String, valueuuid: String): nil | Value
    BTreeSets::destroy(repositorylocation, setuuid: String, valueuuid: String)
=end

# -----------------------------------------------------------------

class Bank

    # Bank::put(setuuid, weight: Float, timespan: Float)
    def self.put(setuuid, weight, timespan)
        uuid = Time.new.to_f.to_s
        packet = {
            "uuid" => uuid,
            "weight" => weight,
            "deathtime" => Time.new.to_i + timespan
        }
        BTreeSets::set(nil, "3621f4d3:#{setuuid}", uuid, packet)
    end

    # Bank::total(setuuid)
    def self.total(setuuid)
        BTreeSets::values(nil, "3621f4d3:#{setuuid}")
            .select{|packet| Time.new.to_i < packet["deathtime"] }
            .map{|packet| packet["weight"] }
            .inject(0, :+)
    end
end