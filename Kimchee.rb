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

class Kimchee
    # Kimchee::getCatalystObjects()
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
                        "metric"              => 1,
                        "announce"            => "Well done for making it to #{timespan.to_f/(86400*7)} weeks (^_^) 💕",
                        "commands"            => ["love"],
                        "command-interpreter" => lambda{ |object, command| 
                            if command=="love" then
                                KeyValueStore::set(nil, "F98F50E6-E076-40FB-8F91-C553153CA5C9:#{Time.new.to_s[0,10]}", "done")
                                return [nil, false]
                            end
                            [nil, false]
                        }
                    }
                ]
            else
                []
            end
        end
    end
end

# -------------------------------------------------------------------------------------
