
# encoding: UTF-8

=begin
    This is a copy of Lisa and TimeStructure

    TimeStructure { 
        :time-commitment-in-hours  : Float
        :time-unit-in-days         : Float
    }
    LisaTarget:
        null
        ["list", <listuuid>]
    lisa { 
        :uuid           : String
        :unixtime       : Integer
        :description    : String
        :time-structure : TimeStructure
        :repeat         : Boolean
        :target         : LisaTarget 
    }
=end

class LisaUtils

    # lisa: { :uuid, :unixtime :description, :timestructure, :repeat, :target }
    # LisaTarget: null or ["list", <listuuid>]

    # LisaUtils::lisasWithFilepaths(): [lisa, filepath]
    def self.lisasWithFilepaths()
        Dir.entries("#{CATALYST_COMMON_DATABANK_CATALYST_FOLDERPATH}/System-Data/Lisa")
            .select{|filename| filename[-5, 5]=='.json' }
            .map{|filename| "#{CATALYST_COMMON_DATABANK_CATALYST_FOLDERPATH}/System-Data/Lisa/#{filename}" }
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

    # LisaUtils::commitLisaToDisk(lisa, filename)
    def self.commitLisaToDisk(lisa, filename)
        File.open("#{CATALYST_COMMON_DATABANK_CATALYST_FOLDERPATH}/System-Data/Lisa/#{filename}", "w") { |f| f.puts(JSON.pretty_generate(lisa)) }
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

    # LisaUtils::spawnNewLisa(description, timestructure, repeat, target)
    # arguments
    #    description   : String
    #    timestructure : TimeStructure
    #    repeat        : Boolean
    #    target        : LisaTarget    
    def self.spawnNewLisa(description, timestructure, repeat, target)
        lisa = {
            "uuid"           => SecureRandom.hex(4),
            "unixtime"       => Time.new.to_i,
            "description"    => description,
            "time-structure" => timestructure,
            "repeat"         => repeat,
            "target"         => target
        }
        LisaUtils::commitLisaToDisk(lisa, "#{LucilleCore::timeStringL22()}.json")
        lisa
    end

    # LisaUtils::metricsForTimeStructure(uuid, timestructure) # [timedoneInHours, timetodoInHours, ratio], [0, 0, nil]
    def self.metricsForTimeStructure(uuid, timestructure)
        if timestructure["time-commitment-in-hours"]==0 then
            return [0, 0, nil]
        end
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

        lisaTargetToString = lambda{|target|
            return "" if target.nil?
            if target[0]=="list" then
                listuuid = target[1]
                list = ListsOperator::getListByUUIDOrNull(listuuid)
                if list.nil? then
                    return " [target: non existent list]"
                else
                    return " [target: list: #{list["description"]}]"
                end
            end
            " [target: #{JSON.generate(target)}]"
        }
        # lisa: { :uuid, :unixtime :description, :timestructure, :repeat }
        uuid = lisa["uuid"]
        description = lisa["description"]
        timestructure = lisa["time-structure"]
        repeat = lisa["repeat"]
        timedoneInHours, timetodoInHours, ratio = LisaUtils::metricsForTimeStructure(uuid, timestructure)
        metric = 0.9 + CommonsUtils::traceToMetricShift(uuid)
        if Chronos::isRunning(uuid) then
            metric = 2 + CommonsUtils::traceToMetricShift(uuid)
        end
        object              = {}
        object["uuid"]      = uuid # the catalyst object has the same uuid as the lisa
        object["agent-uid"] = "201cac75-9ecc-4cac-8ca1-2643e962a6c6"
        object["metric"]    = metric 
        object["announce"]  = LisaUtils::lisaToString_v1(lisa, 40, 50)
        object["commands"]  = Chronos::isRunning(uuid) ? ["stop"] : ["start", "add-time", "set-target", "edit", "destroy"]
        object["default-expression"] = Chronos::isRunning(uuid) ? "stop" : "start"
        object["is-running"] = Chronos::isRunning(uuid)
        object["item-data"] = {}
        object["item-data"]["filepath"] = filepath
        object["item-data"]["lisa"] = lisa
        object["item-data"]["ratio"] = ratio
        object 
    end

    # LisaUtils::getLisasByTargetListUUID()
    def self.getLisasByTargetListUUID(listuuid)
        LisaUtils::lisasWithFilepaths()
            .map{|pair| pair[0] }
            .select{|lisa| lisa["target"] and lisa["target"][0]=="list" and lisa["target"][1]==listuuid }
    end

    # LisaUtils::startLisa(lisa)
    def self.startLisa(lisa)
        Chronos::start(lisa["uuid"])
        # If a starting lisa is targetting a list, that list should become the default display
        if lisa["target"] then
            if lisa["target"][0] == "list" then
                list = ListsOperator::getListByUUIDOrNull(lisa["target"][1])
                # --------------------------------------------------------------------------
                # Marker: a53eb0fc-b557-4265-a13b-a6e4a397cf87
                # And now we are attempting a reverse look up so that CommonsUtils::flockObjectsUpdatedForDisplay()
                # ... knows this came from a Lisa
                FKVStore::set("lisauuid:50047ec7-3a7d-4d55-a191-708ae19e9d9f", lisa["uuid"])
                # --------------------------------------------------------------------------
            end
        end
    end

    # LisaUtils::stopLisa(lisa)
    def self.stopLisa(lisa)
        Chronos::stop(lisa["uuid"])
        if !lisa["repeat"] then
            lisauuid = lisa["uuid"]
            timestructure = lisa["time-structure"]
            if Chronos::summedTimespansInSecondsLiveValue(lisauuid).to_f/3600 >= timestructure["time-commitment-in-hours"] then
                puts "lisa is done and is non repeat: #{LisaUtils::lisaToString_v1(lisa, 0, 0)}"
                puts "Destroying..."
                LucilleCore::pressEnterToContinue()
                filepath = LisaUtils::getLisaFilepathFromLisaUUIDOrNull(lisauuid)
                return if filepath.nil?
                puts "Deleting: #{filepath}"
                FileUtils.rm(filepath)
            end
        end
    end

    # LisaUtils::lisaToString_v1(lisa, descriptionFragmentLJustSize, targetFragmentLJustSize)
    def self.lisaToString_v1(lisa, descriptionFragmentLJustSize, targetFragmentLJustSize)
        uuid = lisa["uuid"]
        timestructure = lisa["time-structure"]
        timedoneInHours, timetodoInHours, ratio = LisaUtils::metricsForTimeStructure(uuid, timestructure)
        if ratio.nil? then
            ratio = 0
        end
        timeAsString = "[ #{"%6.2f" % (100*ratio)} % of #{"%.2f" % (timestructure["time-commitment-in-hours"].to_f/timestructure["time-unit-in-days"])} h today, #{"%5.2f" % timestructure["time-commitment-in-hours"]} / #{timestructure["time-unit-in-days"]} ]"
        lisaTargetString =
            if lisa["target"] then
                if lisa["target"][0] == "list" then
                    list = ListsOperator::getListByUUIDOrNull(lisa["target"][1])
                    if list.nil? then
                        ""
                    else
                        "list: #{list["description"]} (#{list["catalyst-object-uuids"].size})"
                    end
                else
                    ""
                end
            else
                ""
            end
        lisaRepeatString = 
            if lisa["repeat"] then
                "[repeat]" 
            else
                ""
            end 
        descriptionFragmentLJustSize = [ descriptionFragmentLJustSize, lisa["description"].size+1 ].max
        "lisa: #{lisa["description"].ljust(descriptionFragmentLJustSize)}#{timeAsString} #{lisaTargetString.ljust(targetFragmentLJustSize)} #{lisaRepeatString}"
    end

    # LisaUtils::interactivelySelectLisaOrNull()
    def self.interactivelySelectLisaOrNull()
        lisas = LisaUtils::lisasWithFilepaths()
            .map{|data| data[0] }
        lisa = LucilleCore::selectEntityFromListOfEntitiesOrNull("lisa:", lisas, lambda{|lisa| LisaUtils::lisaToString_v1(lisa, 40, 50) })  
        lisa    
    end

    # -----------------------------------------------
    # UI Utils

    # LisaUtils::ui_lisaDive(lisa)
    def self.ui_lisaDive(lisa)
        loop {
            puts "-> #{LisaUtils::lisaToString_v1(lisa, 0, 0)}"
            puts "-> lisa uuid: #{lisa["uuid"]}"
            operation = LucilleCore::selectEntityFromListOfEntitiesOrNull("operation:", ["start", "stop", "add-time", "cast new time structure", "destroy"])
            break if operation.nil?
            if operation=="start" then
                LisaUtils::startLisa(lisa)
            end
            if operation=="stop" then
                LisaUtils::stopLisa(lisa)
            end
            if operation=="add-time" then
                timeInHours = LucilleCore::askQuestionAnswerAsString("Time in hours: ").to_f
                Chronos::addTimeInSeconds(lisa["uuid"], timeInHours*3600)
            end
            if operation=="cast new time structure" then
                timeCommitmentInHours = LucilleCore::askQuestionAnswerAsString("time commitment in hours: ").to_f
                timeUnitInDays = LucilleCore::askQuestionAnswerAsString("time unit in days: ").to_f
                timestructure = { "time-commitment-in-hours"=> timeCommitmentInHours.to_f, "time-unit-in-days" => timeUnitInDays.to_f }
                lisa["time-structure"] = timestructure
                LisaUtils::commitLisaToDisk(lisa, File.basename(LisaUtils::getLisaFilepathFromLisaUUIDOrNull(lisa["uuid"])))
            end
            if operation=="destroy" then
                next if !LucilleCore::askQuestionAnswerAsBoolean("Do you really want to destroy lisa '#{lisa["description"]}' ? ")
                if lisa["target"] then
                    if lisa["target"][0] == "list" then
                        listuuid = lisa["target"][1]
                        if ListsOperator::getLists().any?{|list| list["list-uuid"]==listuuid } then
                            puts "-> You are attempting to destroy a lisa pointing to a list"
                            puts "-> I am going to destroy the list and then the lisa"
                            if LucilleCore::askQuestionAnswerAsBoolean("Confirm deletion? ") then
                                ListsOperator::destroyList(listuuid)
                            else
                                next    
                            end
                        end
                    end
                end
                lisafilepath = LisaUtils::getLisaFilepathFromLisaUUIDOrNull(lisa["uuid"])
                if File.exists?(lisafilepath) then
                    FileUtils.rm(lisafilepath)
                end
                break
            end
        }
    end

    # LisaUtils::ui_lisasDive()
    def self.ui_lisasDive()
        loop {
            lisa = LisaUtils::interactivelySelectLisaOrNull()
            return if lisa.nil?
            LisaUtils::ui_lisaDive(lisa)
        }
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