#!/usr/bin/ruby

# encoding: UTF-8

require "/Galaxy/local-resources/Ruby-Libraries/KeyValueStore.rb"
require 'date'
require "/Galaxy/local-resources/Ruby-Libraries/LucilleCore.rb"
# -------------------------------------------------------------------------------------

# Kimchee::agentuuid()
# Kimchee::genesisDatetime()
# Kimchee::weeksValue()
# Kimchee::monthsValues()
# Kimchee::lastKnownweeksValueInteger()
# Kimchee::flockGeneralUpgrade(flock)

class Kimchee

    def self.agentuuid()
        "b343bc48-82db-4fa3-ac56-3b5a31ff214f"
    end

    def self.genesisDatetime()
        DateTime.parse(IO.read("#{CATALYST_COMMON_DATA_FOLDERPATH}/Agents-Data/kimchee-genesis-datetime")+" +0100")
    end

    def self.weeksValue()
        timespan = Time.new.to_i - Kimchee::genesisDatetime().to_time.to_i
        timespan.to_f/(86400*7)
    end

    def self.monthsValues()
        genesisDateTime = Kimchee::genesisDatetime()
        datetimes = LucilleCore::integerEnumerator()
            .take_while{|int| DateTime.now > genesisDateTime + int  }
            .map{|int| (genesisDateTime + int)  }
            .select{|datetime| datetime.to_s[8,2]=="11" }
        numberOfMonths = datetimes.count-1
        lastAnniversary = datetimes.last
        numberOfDaysSinceLastAnniversary = (Time.new.to_i - lastAnniversary.to_time.to_f).to_f/86400
        [ numberOfMonths, numberOfDaysSinceLastAnniversary ]
    end

    def self.lastKnownweeksValueInteger()
        KeyValueStore::getOrDefaultValue(CATALYST_COMMON_XCACHE_REPOSITORY, "F98F50E6-E076-40FB-8F91-C553153CA5CB", "0").to_i
    end

    def self.interface()
        
    end

    def self.flockGeneralUpgrade(flock)
        return [flock, []]
        objects = 
            if Kimchee::weeksValue().to_i > Kimchee::lastKnownweeksValueInteger() then
                weekValue = Kimchee::weeksValue()
                monthValues = Kimchee::monthsValues()
                [
                    {
                        "uuid"      => "46f97eb4",
                        "agent-uid" => self.agentuuid(),
                        "metric"    => 1-Jupiter::traceToMetricShift("1d510e86-c171-4964-a170-1bc61c6a3201"),
                        "announce"  => "Well done for making it to #{"%.3f" % weekValue} weeks { #{monthValues[0]} months and #{monthValues[1].to_i} days } (^_^) 💕",
                        "commands"  => ["love"]
                    }
                ]
            else
                [] 
            end
        flock["objects"] = flock["objects"] + objects
        [
            flock,
            objects.map{|o|  
                {
                    "event-type" => "Catalyst:Catalyst-Object:1",
                    "object"     => o
                }                
            }   
        ]
    end

    def self.upgradeFlockUsingObjectAndCommand(flock, object, command)
        return [flock, []]        
        if command=="love" then
            KeyValueStore::set(CATALYST_COMMON_XCACHE_REPOSITORY, "F98F50E6-E076-40FB-8F91-C553153CA5CB", Kimchee::weeksValue())
        end
    end
end
