
# encoding: UTF-8

class LisaUtils

    # lisa: { :uuid, :unixtime :description, :timestructure }

    # LisaUtils::lisasWithFilepaths()
    def self.lisasWithFilepaths()
        Dir.entries("/Galaxy/DataBank/Catalyst/Agents-Data/lisas")
            .select{|filename| filename[-5, 5]=='.json' }
            .map{|filename| "/Galaxy/DataBank/Catalyst/Agents-Data/lisas/#{filename}" }
            .map{|filepath| [JSON.parse(IO.read(filepath)), filepath] }
    end

    # LisaUtils::dailyCommitmentInHours()
    def self.dailyCommitmentInHours()
        LisaUtils::lisasWithFilepaths()
            .map{|data| 
                lisa = data[0]
                lisa["time-structure"] 
            }
            .map{|timestructure| timestructure["time-commitment-in-hours"].to_f/timestructure["time-unit-in-days"] }
            .inject(0, :+)
    end

    # LisaUtils::currentCollectivelyDoneInHours()
    def self.currentCollectivelyDoneInHours()
        LisaUtils::lisasWithFilepaths()
            .map{|data| 
                lisa = data[0]
                uuid = lisa["uuid"]
                timeUnitInDays = lisa["time-structure"]["time-unit-in-days"]
                Chronos::summedTimespansWithDecayInSecondsLiveValue(uuid, timeUnitInDays) 
            }
            .inject(0, :+)
            .to_f/3600
    end
    
    # LisaUtils::issueNew(description, timestructure)
    def self.issueNew(description, timestructure)
        data = {
            "uuid" => SecureRandom.hex(4),
            "unixtime" => Time.new.to_i,
            "description" => description,
            "time-structure" => timestructure
        }
        File.open("/Galaxy/DataBank/Catalyst/Agents-Data/lisas/#{LucilleCore::timeStringL22()}.json", "w") { |f| f.puts(JSON.pretty_generate(data)) }
        data
    end

    # LisaUtils::metricsForTimeStructure(uuid, timestructure) # [timedoneInHours, timetodoInHours, ratio]
    def self.metricsForTimeStructure(uuid, timestructure)
        timedoneInHours = Chronos::summedTimespansWithDecayInSecondsLiveValue(uuid, timestructure["time-unit-in-days"]).to_f/3600
        timetodoInHours = timestructure["time-commitment-in-hours"].to_f/timestructure["time-unit-in-days"]
        ratio = timetodoInHours>0 ? timedoneInHours.to_f/timetodoInHours : nil
        [timedoneInHours, timetodoInHours, ratio]
    end

    # LisaUtils::ui_listing()
    def self.ui_listing()
        LisaUtils::lisasWithFilepaths()
            .each{|data|
                lisa, filepath = data
                # lisa: { :uuid, :unixtime :description, :timestructure }
                puts JSON.generate(lisa)        
            }
        LucilleCore::pressEnterToContinue()
    end

end