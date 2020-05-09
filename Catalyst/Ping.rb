
# encoding: UTF-8

# require "/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/Catalyst/Ping.rb"
=begin 
    Ping::ping(uuid, weight, validityTimespan)
    Ping::pong(uuid)
=end

require "/Users/pascal/Galaxy/LucilleOS/Software-Common/Ruby-Libraries/BTreeSets.rb"
=begin
    BTreeSets::values(repositorylocation or nil, setuuid: String): Array[Value]
    BTreeSets::set(repositorylocation or nil, setuuid: String, valueuuid: String, value)
    BTreeSets::getOrNull(repositorylocation or nil, setuuid: String, valueuuid: String): nil | Value
    BTreeSets::destroy(repositorylocation, setuuid: String, valueuuid: String)
=end

# -----------------------------------------------------------------

class Ping

    # Ping::ping(setuuid, weight: Float, timespan: Float)
    def self.ping(setuuid, weight, timespan)
        uuid = Time.new.to_f.to_s
        packet = {
            "uuid" => uuid,
            "weight" => weight,
            "deathtime" => Time.new.to_i + timespan
        }
        BTreeSets::set(nil, "3621f4d3:#{setuuid}", uuid, packet)
    end

    # Ping::pong(setuuid)
    def self.pong(setuuid)
        BTreeSets::values(nil, "3621f4d3:#{setuuid}")
            .select{|packet| Time.new.to_i < packet["deathtime"] }
            .map{|packet| packet["weight"] }
            .inject(0, :+)
    end
end