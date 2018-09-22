
# encoding: UTF-8

class LisaUtils

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
                lisa["time-commitment-every-20-hours"]
            }
            .inject(0, :+)
    end

    # LisaUtils::currentCollectivelyDoneInHours()
    def self.currentCollectivelyDoneInHours()
        LisaUtils::lisasWithFilepaths()
            .select{|data| 
                lisa = data[0]
                ["active-paused", "active-runnning"].include?(lisa["current-status"])
            }
            .map{|data| 
                lisa = data[0]
                currentStatus = lisa["current-status"]
                currentStatus[1]
            }
            .inject(0, :+)
            .to_f/3600
    end

    # LisaUtils::commitLisaToDisk(lisa, filename)
    def self.commitLisaToDisk(lisa, filename)
        File.open("#{CATALYST_COMMON_DATABANK_CATALYST_FOLDERPATH}/System-Data/Lisa/#{filename}", "w") { |f| f.puts(JSON.pretty_generate(lisa)) }
    end
 
    def self.spawnNewLisa(description, timeCommitmentEvery20Hours, target)
        lisa = {
            "uuid"           => SecureRandom.hex(4),
            "unixtime"       => Time.new.to_i,
            "description"    => description,
            "time-commitment-every-20-hours" => timeCommitmentEvery20Hours,
            "target"         => target
        }
        LisaUtils::commitLisaToDisk(lisa, "#{LucilleCore::timeStringL22()}.json")
        lisa
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

    def self.lisa2Metric(lisa)
        # Logic: set to 0.9 and I let Cycles Operator deal with it.
        currentStatus = lisa["current-status"]
        metric = 0.9
        metric = 0.1 if ( currentStatus[0] == "sleeping" )
        metric + CommonsUtils::traceToMetricShift(uuid)
    end

    def self.trueIfLisaIsRunning(lisa)
        lisa["current-status"][0] == "active-runnning"
    end

    # LisaUtils::makeCatalystObjectFromLisaAndFilepath(lisa, filepath)
    def self.makeCatalystObjectFromLisaAndFilepath(lisa, filepath)
        uuid = lisa["uuid"]
        description = lisa["description"]
        object              = {}
        object["uuid"]      = uuid # the catalyst object has the same uuid as the lisa
        object["agent-uid"] = "201cac75-9ecc-4cac-8ca1-2643e962a6c6"
        object["metric"]    = LisaUtils::lisa2Metric(lisa)
        object["announce"]  = LisaUtils::lisaToString_v1(lisa, 40, 50)
        object["commands"]  = LisaUtils::trueIfLisaIsRunning(lisa) ? ["stop"] : ["start", "add-time", "set-target", "edit", "destroy"]
        object["default-expression"] = LisaUtils::trueIfLisaIsRunning(lisa) ? "stop" : "start"
        object["is-running"] = LisaUtils::trueIfLisaIsRunning(lisa)
        object["item-data"] = {}
        object["item-data"]["filepath"] = filepath
        object["item-data"]["lisa"] = lisa
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
        currentStatus = lisa["current-status"]
        return if currentStatus[0] == "active-runnning" 
        if currentStatus[0] == "active-paused" then
            status = ["active-runnning", currentStatus[1], Time.new.to_i] 
        end
        if currentStatus[0] == "sleeping" then
            status = ["active-runnning", 0, Time.new.to_i] 
        end 
        lisa["status"] = status
        filepath = LisaUtils::getLisaFilepathFromLisaUUIDOrNull(lisa["uuid"])
        LisaUtils::commitLisaToDisk(lisa, File.basename(filepath))
    end

    # LisaUtils::stopLisa(lisa)
    def self.stopLisa(lisa)
        currentStatus = lisa["current-status"]
        return if currentStatus[0] == "sleeping"
        return if currentStatus[0] == "active-paused"
        lastStartedRunningTime = currentStatus[2]
        timeDoneInSeconds = Time.new.to_i - lastStartedRunningTime
        status =
            if timeDoneInSeconds < lisa["time-commitment-every-20-hours"]*3600 then
                ["active-paused", timeDoneInSeconds]
            else
                ["sleeping", Time.new.to_i]
            end
        lisa["status"] = status
        filepath = LisaUtils::getLisaFilepathFromLisaUUIDOrNull(lisa["uuid"])
        LisaUtils::commitLisaToDisk(lisa, File.basename(filepath))
    end

    # LisaUtils::lisaToString_v1(lisa, descriptionFragmentLJustSize, targetFragmentLJustSize)
    def self.lisaToString_v1(lisa, descriptionFragmentLJustSize, targetFragmentLJustSize)
        uuid = lisa["uuid"]
        timeAsString = "[ #{lisa["time-commitment-every-20-hours"]} ]"
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
            operation = LucilleCore::selectEntityFromListOfEntitiesOrNull("operation:", ["start", "stop", "add-time", "set new time commitment", "destroy"])
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
            if operation=="set new time commitment" then
                timeCommitmentEvery20Hours = LucilleCore::askQuestionAnswerAsString("time commitment every day (every 20 hours): ").to_f
                lisa["time-commitment-every-20-hours"] = timeCommitmentEvery20Hours
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