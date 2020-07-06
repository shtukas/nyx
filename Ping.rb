
# encoding: UTF-8

# require_relative "Ping.rb"
=begin 
    Ping::put(uuid, weight)
    Ping::totalOverTimespan(uuid, timespanInSeconds)
    Ping::totalToday(uuid)
=end

require 'securerandom'
# SecureRandom.hex    #=> "eb693ec8252cd630102fd0d0fb7c3485"
# SecureRandom.hex(4) #=> "eb693123"
# SecureRandom.uuid   #=> "2d931510-d99f-494a-8c67-87feb05e1594"

require_relative "BTreeSets.rb"
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
            "uuid" => SecureRandom.hex,
            "weight" => weight,
            "unixtime" => Time.new.to_f,
            "date" => Time.new.to_s[0, 10],
        }
        BTreeSets::set(nil, "42d8f699-64bf-4385-a069-60ab349d0684:#{uuid}", packet["uuid"], packet)
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
            .select{|packet| (unixtime - packet["unixtime"]) <= timespanInSeconds }
            .map{|packet| packet["weight"] }
            .inject(0, :+)
    end

    # Ping::bestTimeRatioOverPeriod7Samples(pinguuid, timespanInSeconds)
    def self.bestTimeRatioOverPeriod7Samples(pinguuid, timespanInSeconds)
        (1..7)
            .map{|i|
                lookupPeriodInSeconds = timespanInSeconds*(i.to_f/7)
                timedone = Ping::totalOverTimespan(pinguuid, lookupPeriodInSeconds)
                timedone.to_f/lookupPeriodInSeconds
            }
            .max
    end
end