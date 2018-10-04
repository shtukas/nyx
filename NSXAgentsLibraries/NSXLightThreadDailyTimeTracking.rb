
# encoding: UTF-8

require "/Galaxy/Software/Misc-Common/Ruby-Libraries/KeyValueStore.rb"
=begin
    KeyValueStore::set(repositorylocation or nil, key, value)
    KeyValueStore::getOrNull(repositorylocation or nil, key)
    KeyValueStore::getOrDefaultValue(repositorylocation or nil, key, defaultValue)
    KeyValueStore::destroy(repositorylocation or nil, key)
=end

# ---------------------------------------------------------

=begin

DailyStructure: Map[TimeProtonUUID, (ExpectedTime: Float, Done:Time; Float) 

=end

class NSXLightThreadDailyTimeTracking

    # NSXLightThreadDailyTimeTracking::currentDay()
    def self.currentDay()
        Time.now.utc.iso8601[0,10]
    end

    # NSXLightThreadDailyTimeTracking::getDailyStructure()
    def self.getDailyStructure()
        currentday = NSXLightThreadDailyTimeTracking::currentDay()
        structure = KeyValueStore::getOrNull(nil, "a30bdedc-4f71-4837-bec6-efb648864dce:#{currentday}")
        if structure.nil? then
            structure = {}
            # First call of the day
            NSXLightThreadUtils::lightThreadsWithFilepaths().each{|pair|
                lightThread = pair[0]
                structure[lightThread["uuid"]] = [lightThread["time-commitment-every-20-hours-in-hours"]*3600, 0]
            }
        else
            structure = JSON.parse(structure)
        end
        structure
    end

    # NSXLightThreadDailyTimeTracking::putDailyStucture(structure)
    def self.putDailyStucture(structure)
        currentday = NSXLightThreadDailyTimeTracking::currentDay()
        KeyValueStore::set(nil, "a30bdedc-4f71-4837-bec6-efb648864dce:#{currentday}", JSON.generate(structure))        
    end

    # NSXLightThreadDailyTimeTracking::addTimespanForTimeProton(lightThreadUUID, timespan)
    def self.addTimespanForTimeProton(lightThreadUUID, timespan)
        structure = NSXLightThreadDailyTimeTracking::getDailyStructure()
        structure[lightThreadUUID][1] = structure[lightThreadUUID][1] + timespan
        NSXLightThreadDailyTimeTracking::putDailyStucture(structure)
    end

    # NSXLightThreadDailyTimeTracking::numbersDayTotalAndPercentage()
    def self.numbersDayTotalAndPercentage()
        structure = NSXLightThreadDailyTimeTracking::getDailyStructure()
        expected = structure.keys.map{|uuid| structure[uuid][0] }.inject(0, :+)
        done = structure.keys.map{|uuid| structure[uuid][1] }.inject(0, :+)
        [expected, 100*done.to_f/expected]
    end

end