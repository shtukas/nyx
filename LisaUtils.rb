
# encoding: UTF-8

class LisaUtils

    # lisa: { :uuid, :unixtime :description, :timestructure, :repeat }

    # LisaUtils::lisasWithFilepaths(): [lisa, filepath]
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

    # LisaUtils::commitLisaToDisk(lisa, filepath)
    def self.commitLisaToDisk(lisa, filepath)
        File.open("/Galaxy/DataBank/Catalyst/Agents-Data/lisas/#{filepath}", "w") { |f| f.puts(JSON.pretty_generate(lisa)) }
    end
    
    # LisaUtils::issueNew(description, timestructure)
    def self.issueNew(description, timestructure)
        lisa = {
            "uuid" => SecureRandom.hex(4),
            "unixtime" => Time.new.to_i,
            "description" => description,
            "time-structure" => timestructure
        }
        LisaUtils::commitLisaToDisk(lisa, "#{LucilleCore::timeStringL22()}.json")
        lisa
    end

    # LisaUtils::metricsForTimeStructure(uuid, timestructure) # [timedoneInHours, timetodoInHours, ratio]
    def self.metricsForTimeStructure(uuid, timestructure)
        timedoneInHours = Chronos::summedTimespansWithDecayInSecondsLiveValue(uuid, timestructure["time-unit-in-days"]).to_f/3600
        timetodoInHours = timestructure["time-commitment-in-hours"].to_f/timestructure["time-unit-in-days"]
        ratio = timetodoInHours>0 ? timedoneInHours.to_f/timetodoInHours : nil
        [timedoneInHours, timetodoInHours, ratio]
    end

    # LisaUtils::getLisaByUUIDOrNull(lisauuid)
    def self.getLisaByUUIDOrNull(lisauuid)
        LisaUtils::lisasWithFilepaths()
            .map{|pair| pair.first }
            .select{|lisa| lisa["uuid"]==lisauuid }
            .first
    end

    # LisaUtils::getLisaFilepathFromLisaUUIDOrNull(lisauuid)
    def self.getLisaFilepathFromLisaUUIDOrNull(lisauuid)
        LisaUtils::lisasWithFilepaths()
            .select{|pair| pair[0]["uuid"]==lisauuid }
            .each{|pair|  
                return pair[1]
            }
        nil
    end

    # LisaUtils::makeCatalystObjectFromLisaAndFilepath(lisa, filepath)
    def self.makeCatalystObjectFromLisaAndFilepath(lisa, filepath)
        ratioToMetric = lambda{|ratio|  
            ratio = [ratio, 1].min
            0.5 + 0.35*(1-ratio)            
        }
        # lisa: { :uuid, :unixtime :description, :timestructure, :repeat }
        uuid = lisa["uuid"]
        description = lisa["description"]
        timestructure = lisa["time-structure"]
        repeat = lisa["repeat"]
        timedoneInHours, timetodoInHours, ratio = LisaUtils::metricsForTimeStructure(uuid, timestructure)
        metric = ratioToMetric.call(ratio) + CommonsUtils::traceToMetricShift(uuid)
        if ratio>1 then
            metric = 0.1 + CommonsUtils::traceToMetricShift(uuid)
        end
        if Chronos::isRunning(uuid) then
            metric = 2 + CommonsUtils::traceToMetricShift(uuid)
        end
        object              = {}
        object["uuid"]      = uuid # the catalyst object has the same uuid as the lisa
        object["agent-uid"] = "201cac75-9ecc-4cac-8ca1-2643e962a6c6"
        object["metric"]    = metric 
        object["announce"]  = "lisa: #{description}#{repeat ? " [repeat]" : ""}#{lisa["target"] ? " #{JSON.generate(lisa["target"])}" : "" } ( #{(100*ratio).round(2)} % of #{timestructure["time-commitment-in-hours"]} hours )"
        object["commands"]  = Chronos::isRunning(uuid) ? ["stop"] : ["start", "add-time", "set-target", "destroy"]
        object["default-expression"] = Chronos::isRunning(uuid) ? "stop" : "start"
        object["is-running"] = Chronos::isRunning(uuid)
        object["item-data"] = {}
        object["item-data"]["filepath"] = filepath
        object["item-data"]["lisa"] = lisa
        object["item-data"]["ratio"] = ratio
        object 
    end

    # LisaUtils::ui_listing()
    def self.ui_listing()
        LisaUtils::lisasWithFilepaths()
            .each{|data|
                lisa, filepath = data
                puts JSON.generate(lisa)        
            }
        LucilleCore::pressEnterToContinue()
    end

    # LisaUtils::ui_setInteractivelySelectedTargetForLisa(lisauuid)
    def self.ui_setInteractivelySelectedTargetForLisa(lisauuid)
        lisa = LisaUtils::getLisaByUUIDOrNull(lisauuid)
        return if lisa.nil?
        targetType = LucilleCore::selectEntityFromListOfEntitiesOrNull("lisa target type", ["list"])
        return if targetType.nil?
        if targetType == "list" then
            list = ListsOperator::ui_interactivelySelectListOrNull()
            return if list.nil?
            lisa["target"] = ["list", list["list-uuid"]]
            lisafilepath = LisaUtils::getLisaFilepathFromLisaUUIDOrNull(lisauuid)
            return if lisafilepath.nil?
            LisaUtils::commitLisaToDisk(lisa, File.basename(lisafilepath))
        end
    end

end