#!/usr/bin/ruby

# encoding: UTF-8

require "/Galaxy/local-resources/Ruby-Libraries/KeyValueStore.rb"
=begin
    KeyValueStore::set(repositorypath or nil, key, value)
    KeyValueStore::getOrNull(repositorypath or nil, key)
    KeyValueStore::getOrDefaultValue(repositorypath or nil, key, defaultValue)
    KeyValueStore::destroy(repositorypath or nil, key)
=end

require 'date'

# -------------------------------------------------------------------------------------

# Kimchee::agentuuid()
# Kimchee::getCatalystObjects()

class Kimchee

    def self.agentuuid()
        "b343bc48-82db-4fa3-ac56-3b5a31ff214f"
    end

    def self.processObject(object, command)
        if command=="love" then
            KeyValueStore::set(nil, "F98F50E6-E076-40FB-8F91-C553153CA5C9:#{Time.new.to_s[0,10]}", "done")
            return Saturn::deathObject(object["uuid"])
        end
        nil
    end

    def self.getCatalystObjects()
        if Time.new.wday!=0 then
            []
        else
            if KeyValueStore::getOrNull(nil, "F98F50E6-E076-40FB-8F91-C553153CA5C9:#{Time.new.to_s[0,10]}").nil? then
                genesisUnixtime = DateTime.parse(IO.read("/Galaxy/DataBank/Catalyst/kimchee-genesis-datetime")).to_time.to_i
                timespan = Time.new.to_i - genesisUnixtime
                [
                    {
                        "uuid"                => "46f97eb4",
                        "metric"              => 1-Saturn::traceToMetricShift("1d510e86-c171-4964-a170-1bc61c6a3201"),
                        "announce"            => "Well done for making it to #{timespan.to_f/(86400*7)} weeks (^_^) 💕",
                        "commands"            => ["love"],
                        "agent-uid" => self.agentuuid()
                    }
                ]
            else
                []
            end
        end
    end
end

# -------------------------------------------------------------------------------------