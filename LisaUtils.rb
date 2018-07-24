
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

end