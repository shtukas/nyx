
# encoding: UTF-8

class TimeProtonUtils

    # TimeProtonUtils::timeProtonsWithFilepaths(): [timeProton, filepath]
    def self.timeProtonsWithFilepaths()
        Dir.entries("#{CATALYST_COMMON_DATABANK_CATALYST_FOLDERPATH}/System-Data/Time-Protons")
            .select{|filename| filename[-5, 5]=='.json' }
            .map{|filename| "#{CATALYST_COMMON_DATABANK_CATALYST_FOLDERPATH}/System-Data/Time-Protons/#{filename}" }
            .map{|filepath| [JSON.parse(IO.read(filepath)), filepath] }
    end

    # TimeProtonUtils::dailyCommitmentInHours()
    def self.dailyCommitmentInHours()
        TimeProtonUtils::timeProtonsWithFilepaths()
            .map{|data| 
                timeProton = data[0]
                timeProton["time-commitment-every-20-hours-in-hours"]
            }
            .inject(0, :+)
    end

    # TimeProtonUtils::currentCollectivelyDoneInHours()
    def self.currentCollectivelyDoneInHours()
        TimeProtonUtils::timeProtonsWithFilepaths()
            .select{|data| 
                timeProton = data[0]
                ["active-paused", "active-runnning"].include?(timeProton["status"])
            }
            .map{|data| 
                timeProton = data[0]
                currentStatus = timeProton["status"]
                currentStatus[1]
            }
            .inject(0, :+)
            .to_f/3600
    end

    # TimeProtonUtils::commitTimeProtonToDisk(timeProton, filename)
    def self.commitTimeProtonToDisk(timeProton, filename)
        File.open("#{CATALYST_COMMON_DATABANK_CATALYST_FOLDERPATH}/System-Data/Time-Protons/#{filename}", "w") { |f| f.puts(JSON.pretty_generate(timeProton)) }
    end

    # TimeProtonUtils::makeNewTimeProton(description, timeCommitmentEvery20Hours, target)
    def self.makeNewTimeProton(description, timeCommitmentEvery20Hours, target)
        timeProton = {
            "uuid"           => SecureRandom.hex(4),
            "unixtime"       => Time.new.to_i,
            "description"    => description,
            "time-commitment-every-20-hours-in-hours" => timeCommitmentEvery20Hours,
            "target"         => target
        }
        TimeProtonUtils::commitTimeProtonToDisk(timeProton, "#{LucilleCore::timeStringL22()}.json")
        timeProton
    end

    # TimeProtonUtils::getTimeProtonByUUIDOrNull(timeprotonuuid)
    def self.getTimeProtonByUUIDOrNull(timeprotonuuid)
        TimeProtonUtils::timeProtonsWithFilepaths()
            .map{|pair| pair.first }
            .select{|timeProton| timeProton["uuid"]==timeprotonuuid }
            .first
    end

    # TimeProtonUtils::getTimeProtonFilepathFromItsUUIDOrNull(timeprotonuuid)
    def self.getTimeProtonFilepathFromItsUUIDOrNull(timeprotonuuid)
        TimeProtonUtils::timeProtonsWithFilepaths()
            .select{|pair| pair[0]["uuid"]==timeprotonuuid }
            .each{|pair|  
                return pair[1]
            }
        nil
    end

    # TimeProtonUtils::timeProton2Metric(timeProton)
    def self.timeProton2Metric(timeProton)
        # Logic: set to 0.9 and I let Cycles Operator deal with it.
        currentStatus = timeProton["status"]
        metric = 0.9
        metric = 0.1 if currentStatus[0] == "sleeping"
        metric = 2.0 if currentStatus[0] == "active-runnning"
        metric + CommonsUtils::traceToMetricShift(timeProton["uuid"])
    end

    # TimeProtonUtils::trueIfTimeProtonIsRunning(timeProton)
    def self.trueIfTimeProtonIsRunning(timeProton)
        timeProton["status"][0] == "active-runnning"
    end

    # TimeProtonUtils::makeCatalystObjectFromTimeProtonAndFilepath(timeProton, filepath)
    def self.makeCatalystObjectFromTimeProtonAndFilepath(timeProton, filepath)
        # There is a check we need to do here: whether or not the timeProton should be taken out of sleeping
        if timeProton["status"][0] == "sleeping" then
            timeSinceGoingToSleep = Time.new.to_i - timeProton["status"][1]
            if timeSinceGoingToSleep >= 20*3600 then
                # Here we need to get it out of sleep
                timeProton["status"] = ["active-paused", 0]
                TimeProtonUtils::commitTimeProtonToDisk(timeProton, File.basename(filepath))
            end
        end

        if timeProton["status"][0] == "active-paused" and TimeProtonUtils::timeProtonToLivePercentage(timeProton) > 100 then
            timeProton["status"] = ["sleeping", Time.new.to_i]
            TimeProtonUtils::commitTimeProtonToDisk(timeProton, File.basename(filepath))
        end

        if timeProton["status"][0] == "active-runnning" and TimeProtonUtils::timeProtonToLivePercentage(timeProton) > 100 then
            system("terminal-notifier -title 'Catalyst TimeProton' -message '#{timeProton["description"].gsub("'","")} is done'")
        end

        uuid = timeProton["uuid"]
        description = timeProton["description"]
        object              = {}
        object["uuid"]      = uuid # the catalyst object has the same uuid as the timeProton
        object["agent-uid"] = "201cac75-9ecc-4cac-8ca1-2643e962a6c6"
        object["metric"]    = TimeProtonUtils::timeProton2Metric(timeProton)
        object["announce"]  = TimeProtonUtils::timeProtonToString(timeProton)
        object["commands"]  = TimeProtonUtils::trueIfTimeProtonIsRunning(timeProton) ? ["stop"] : ["start", "time:", "list:", "edit", "destroy"]
        object["default-expression"] = TimeProtonUtils::trueIfTimeProtonIsRunning(timeProton) ? "stop" : "start"
        object["is-running"] = TimeProtonUtils::trueIfTimeProtonIsRunning(timeProton)
        object["item-data"] = {}
        object["item-data"]["filepath"] = filepath
        object["item-data"]["timeProton"] = timeProton
        object 
    end

    # TimeProtonUtils::getTimeProtonsByTargetListUUID()
    def self.getTimeProtonsByTargetListUUID(listuuid)
        TimeProtonUtils::timeProtonsWithFilepaths()
            .map{|pair| pair[0] }
            .select{|timeProton| timeProton["target"]==listuuid }
    end

    # TimeProtonUtils::startTimeProton(timeprotonuuid)
    def self.startTimeProton(timeprotonuuid)
        timeProton = TimeProtonUtils::getTimeProtonByUUIDOrNull(timeprotonuuid)
        return if timeProton.nil?
        currentStatus = timeProton["status"]
        return if currentStatus[0] == "active-runnning" 
        if currentStatus[0] == "active-paused" then
            status = ["active-runnning", currentStatus[1], Time.new.to_i] 
        end
        if currentStatus[0] == "sleeping" then
            status = ["active-runnning", 0, Time.new.to_i] 
        end 
        timeProton["status"] = status
        filepath = TimeProtonUtils::getTimeProtonFilepathFromItsUUIDOrNull(timeProton["uuid"])
        TimeProtonUtils::commitTimeProtonToDisk(timeProton, File.basename(filepath))
    end

    # TimeProtonUtils::stopTimeProton(timeprotonuuid)
    def self.stopTimeProton(timeprotonuuid)
        timeProton = TimeProtonUtils::getTimeProtonByUUIDOrNull(timeprotonuuid)
        return if timeProton.nil?
        currentStatus = timeProton["status"]
        return if currentStatus[0] == "sleeping"
        return if currentStatus[0] == "active-paused"
        lastStartedRunningTime = currentStatus[2]
        timeDoneInSeconds = Time.new.to_i - lastStartedRunningTime
        status =
            if timeDoneInSeconds < timeProton["time-commitment-every-20-hours-in-hours"]*3600 then
                ["active-paused", timeDoneInSeconds]
            else
                ["sleeping", Time.new.to_i]
            end
        timeProton["status"] = status
        filepath = TimeProtonUtils::getTimeProtonFilepathFromItsUUIDOrNull(timeProton["uuid"])
        TimeProtonUtils::commitTimeProtonToDisk(timeProton, File.basename(filepath))

        # Admin for the day
        TimeProtonDailyTimeTracking::addTimespanForTimeProton(timeProton["uuid"], timeDoneInSeconds)
    end

    # TimeProtonUtils::timeProtonAddTime(timeprotonuuid, timeInHours)
    def self.timeProtonAddTime(timeprotonuuid, timeInHours)
        timeProton = TimeProtonUtils::getTimeProtonByUUIDOrNull(timeprotonuuid)
        return if timeProton.nil?
        filepath = TimeProtonUtils::getTimeProtonFilepathFromItsUUIDOrNull(timeprotonuuid)
        return if filepath.nil?
        if timeProton["status"][0] == "sleeping" then
            timeProton["status"] = ["active-paused", 0]
        end
        timeProton["status"][1] = timeProton["status"][1] + timeInHours*3600
        TimeProtonUtils::commitTimeProtonToDisk(timeProton, File.basename(filepath))

        # Admin for the day
        TimeProtonDailyTimeTracking::addTimespanForTimeProton(timeProton["uuid"], timeInHours*3600)
    end

    # TimeProtonUtils::timeProtonToLiveDoneTimeSpan(timeProton)
    def self.timeProtonToLiveDoneTimeSpan(timeProton)
        status = timeProton["status"]
        return 0 if status[0]=="sleeping"
        return status[1] if status[0]=="active-paused"
        status[1] + (Time.new.to_i-status[2])
    end

    # TimeProtonUtils::timeProtonToLivePercentage(timeProton)
    def self.timeProtonToLivePercentage(timeProton)
        100*TimeProtonUtils::timeProtonToLiveDoneTimeSpan(timeProton).to_f/(3600*timeProton["time-commitment-every-20-hours-in-hours"])
    end

    # TimeProtonUtils::timeProtonToString(timeProton)
    def self.timeProtonToString(timeProton)
        uuid = timeProton["uuid"]
        status = timeProton["status"]
        if status[0]=="sleeping" then
            percentageAsString = "sleeping / "
        end
        if status[0]=="active-paused" then
            percentageAsString = "#{TimeProtonUtils::timeProtonToLivePercentage(timeProton).round(2)}% of "
        end
        if status[0]=="active-runnning" then
            percentageAsString = "#{TimeProtonUtils::timeProtonToLivePercentage(timeProton).round(2)}% of "
        end
        timeAsString = "(#{percentageAsString}#{timeProton["time-commitment-every-20-hours-in-hours"].round(2)} hours)"
        timeProtonTargetString =
            if timeProton["target"] then
                list = ListsOperator::getListByUUIDOrNull(timeProton["target"])
                if list.nil? then
                    ""
                else
                    "list: #{list["description"]} (#{list["catalyst-object-uuids"].size} objects)"
                end
            else
                ""
            end
        "timeProton: #{timeProton["description"]} #{timeAsString} #{timeProtonTargetString}"
    end

    # TimeProtonUtils::interactivelySelectTimeProtonOrNull()
    def self.interactivelySelectTimeProtonOrNull()
        timeProtons = TimeProtonUtils::timeProtonsWithFilepaths()
            .map{|data| data[0] }
        timeProton = LucilleCore::selectEntityFromListOfEntitiesOrNull("timeProton:", timeProtons, lambda{|timeProton| TimeProtonUtils::timeProtonToString(timeProton) })  
        timeProton    
    end

    # -----------------------------------------------
    # UI Utils

    # TimeProtonUtils::timeProtonDive(timeProton)
    def self.timeProtonDive(timeProton)
        loop {
            puts "-> #{TimeProtonUtils::timeProtonToString(timeProton)}"
            puts "-> timeProton uuid: #{timeProton["uuid"]}"
            operation = LucilleCore::selectEntityFromListOfEntitiesOrNull("operation:", ["start", "stop", "time:", "set new time commitment", "destroy"])
            break if operation.nil?
            if operation=="start" then
                TimeProtonUtils::startTimeProton(timeProton)
            end
            if operation=="stop" then
                TimeProtonUtils::stopTimeProton(timeProton)
            end
            if operation=="time:" then
                timeInHours = LucilleCore::askQuestionAnswerAsString("Time in hours: ").to_f
                TimeProtonUtils::timeProtonAddTime(timeprotonuuid, timeInHours)
            end
            if operation=="set new time commitment" then
                timeCommitmentEvery20Hours = LucilleCore::askQuestionAnswerAsString("time commitment every day (every 20 hours): ").to_f
                timeProton["time-commitment-every-20-hours-in-hours"] = timeCommitmentEvery20Hours
                TimeProtonUtils::commitTimeProtonToDisk(timeProton, File.basename(TimeProtonUtils::getTimeProtonFilepathFromItsUUIDOrNull(timeProton["uuid"])))
            end
            if operation=="destroy" then
                next if !LucilleCore::askQuestionAnswerAsBoolean("Do you really want to destroy timeProton '#{timeProton["description"]}' ? ")
                if timeProton["target"] then
                    listuuid = timeProton["target"]
                    if ListsOperator::getLists().any?{|list| list["list-uuid"]==listuuid } then
                        puts "-> You are attempting to destroy a timeProton pointing to a list"
                        puts "-> I am going to destroy the list and then the timeProton"
                        if LucilleCore::askQuestionAnswerAsBoolean("Confirm deletion? ") then
                            ListsOperator::destroyList(listuuid)
                        else
                            next    
                        end
                    end
                end
                timeprotonfilepath = TimeProtonUtils::getTimeProtonFilepathFromItsUUIDOrNull(timeProton["uuid"])
                if File.exists?(timeprotonfilepath) then
                    FileUtils.rm(timeprotonfilepath)
                end
                break
            end
        }
    end

    # TimeProtonUtils::timeProtonsDive()
    def self.timeProtonsDive()
        loop {
            timeProton = TimeProtonUtils::interactivelySelectTimeProtonOrNull()
            return if timeProton.nil?
            TimeProtonUtils::timeProtonDive(timeProton)
        }
    end

    # TimeProtonUtils::setInteractivelySelectedTargetForTimeProton(timeprotonuuid)
    def self.setInteractivelySelectedTargetForTimeProton(timeprotonuuid)
        timeProton = TimeProtonUtils::getTimeProtonByUUIDOrNull(timeprotonuuid)
        return if timeProton.nil?
        targetType = LucilleCore::selectEntityFromListOfEntitiesOrNull("timeProton target type", ["list"])
        return if targetType.nil?
        if targetType == "list" then
            list = ListsOperator::ui_interactivelySelectListOrNull()
            return if list.nil?
            timeProton["target"] = list["list-uuid"]
            timeprotonfilepath = TimeProtonUtils::getTimeProtonFilepathFromItsUUIDOrNull(timeprotonuuid)
            return if timeprotonfilepath.nil?
            TimeProtonUtils::commitTimeProtonToDisk(timeProton, File.basename(timeprotonfilepath))
        end
    end

end