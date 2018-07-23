
# encoding: UTF-8

class Lisa

    # lisa: { :uuid, :unixtime :description, :time-structure }
    
    # Lisa::issueNew(description, timestructure)

    def self.issueNew(description, timestructure)
        data = {
            "uuid" => SecureRandom.hex(4),
            "unixtime" => Time.new.to_i,
            "description" => description,
            "time-struture" => timestructure
        }
        File.open("/Galaxy/DataBank/Catalyst/Agents-Data/lisas/#{LucilleCore::timeStringL22()}.json", "w") { |f| f.puts(JSON.pretty_generate(data)) }
        data
    end

    # Lisa::metricsForTimeStructure(uuid, timestructure) # [timedoneInHours, timetodoInHours, ratio]

    def self.metricsForTimeStructure(uuid, timestructure)
        timedoneInHours = Chronos::summedTimespansWithDecayInSecondsLiveValue(uuid, timestructure["time-unit-in-days"]).to_f/3600
        timetodoInHours = timestructure["time-commitment-in-hours"].to_f/timestructure["time-unit-in-days"]
        ratio = timetodoInHours>0 ? timedoneInHours.to_f/timetodoInHours : nil
        [timedoneInHours, timetodoInHours, ratio]
    end
end
