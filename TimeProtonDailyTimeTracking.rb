
# encoding: UTF-8

require "/Galaxy/local-resources/Ruby-Libraries/KeyValueStore.rb"
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

class TimeProtonDailyTimeTracking

    # TimeProtonDailyTimeTracking::currentDay()
    def self.currentDay()
        Time.now.utc.iso8601[0,10]
    end

    # TimeProtonDailyTimeTracking::getDailyStructure()
    def self.getDailyStructure()
        currentday = TimeProtonDailyTimeTracking::currentDay()
        structure = KeyValueStore::getOrNull(nil, "a30bdedc-4f71-4837-bec6-efb648864dce:#{currentday}")
        if structure.nil? then
            structure = {}
            # First call of the day
            TimeProtonUtils::timeProtonsWithFilepaths().each{|pair|
                timeProton = pair[0]
                structure[timeProton["uuid"]] = [timeProton["time-commitment-every-20-hours-in-hours"]*3600, 0]
            }
        else
            structure = JSON.parse(structure)
        end
        structure
    end

    # TimeProtonDailyTimeTracking::putDailyStucture(structure)
    def self.putDailyStucture(structure)
        currentday = TimeProtonDailyTimeTracking::currentDay()
        KeyValueStore::set(nil, "a30bdedc-4f71-4837-bec6-efb648864dce:#{currentday}", JSON.generate(structure))        
    end

    # TimeProtonDailyTimeTracking::addTimespanForTimeProton(timeProtonUUID, timespan)
    def self.addTimespanForTimeProton(timeProtonUUID, timespan)
        structure = TimeProtonDailyTimeTracking::getDailyStructure()
        structure[timeProtonUUID][1] = structure[timeProtonUUID][1] + timespan
        TimeProtonDailyTimeTracking::putDailyStucture(structure)
    end

    # TimeProtonDailyTimeTracking::numbersDayTotalAndPercentage()
    def self.numbersDayTotalAndPercentage()
        structure = TimeProtonDailyTimeTracking::getDailyStructure()
        expected = structure.keys.map{|uuid| structure[uuid][0] }.inject(0, :+)
        done = structure.keys.map{|uuid| structure[uuid][1] }.inject(0, :+)
        [expected, 100*done.to_f/expected]
    end

end