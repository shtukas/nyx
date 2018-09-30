
# encoding: UTF-8

class LightThreadUtils

    # LightThreadUtils::lightThreadsWithFilepaths(): [timeProton, filepath]
    def self.lightThreadsWithFilepaths()
        Dir.entries("#{CATALYST_COMMON_DATABANK_CATALYST_FOLDERPATH}/System-Data/Light-Threads")
            .select{|filename| filename[-5, 5]=='.json' }
            .map{|filename| "#{CATALYST_COMMON_DATABANK_CATALYST_FOLDERPATH}/System-Data/Light-Threads/#{filename}" }
            .map{|filepath| [JSON.parse(IO.read(filepath)), filepath] }
    end

    # LightThreadUtils::totalDailyCommitmentInHours()
    def self.totalDailyCommitmentInHours()
        LightThreadUtils::lightThreadsWithFilepaths()
            .map{|data| 
                timeProton = data[0]
                timeProton["time-commitment-every-20-hours-in-hours"]
            }
            .inject(0, :+)
    end

    # LightThreadUtils::currentTotalDoneInHours()
    def self.currentTotalDoneInHours()
        LightThreadUtils::lightThreadsWithFilepaths()
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

    # LightThreadUtils::commitLightThreadToDisk(timeProton, filename)
    def self.commitLightThreadToDisk(timeProton, filename)
        File.open("#{CATALYST_COMMON_DATABANK_CATALYST_FOLDERPATH}/System-Data/Light-Threads/#{filename}", "w") { |f| f.puts(JSON.pretty_generate(timeProton)) }
    end

    # LightThreadUtils::makeNewLightThread(description, timeCommitmentEvery20Hours, target)
    def self.makeNewLightThread(description, timeCommitmentEvery20Hours, target)
        timeProton = {
            "uuid"           => SecureRandom.hex(4),
            "unixtime"       => Time.new.to_i,
            "description"    => description,
            "time-commitment-every-20-hours-in-hours" => timeCommitmentEvery20Hours,
            "status"         => ["sleeping", 0]
        }
        LightThreadUtils::commitLightThreadToDisk(timeProton, "#{LucilleCore::timeStringL22()}.json")
        timeProton
    end

    # LightThreadUtils::getLightThreadByUUIDOrNull(timeprotonuuid)
    def self.getLightThreadByUUIDOrNull(timeprotonuuid)
        LightThreadUtils::lightThreadsWithFilepaths()
            .map{|pair| pair.first }
            .select{|timeProton| timeProton["uuid"]==timeprotonuuid }
            .first
    end

    # LightThreadUtils::getLightThreadFilepathFromItsUUIDOrNull(timeprotonuuid)
    def self.getLightThreadFilepathFromItsUUIDOrNull(timeprotonuuid)
        LightThreadUtils::lightThreadsWithFilepaths()
            .select{|pair| pair[0]["uuid"]==timeprotonuuid }
            .each{|pair|  
                return pair[1]
            }
        nil
    end

    # LightThreadUtils::lightThread2Metric(timeProton)
    def self.lightThread2Metric(timeProton)
        # Logic: set to 0.9 and I let Cycles Operator deal with it.
        currentStatus = timeProton["status"]
        metric = 0.9
        metric = 0.1 if currentStatus[0] == "sleeping"
        metric = 2.0 if currentStatus[0] == "active-runnning"
        metric + CommonsUtils::traceToMetricShift(timeProton["uuid"])
    end

    # LightThreadUtils::trueIfLightThreadIsRunning(timeProton)
    def self.trueIfLightThreadIsRunning(timeProton)
        timeProton["status"][0] == "active-runnning"
    end

    # LightThreadUtils::makeCatalystObjectFromLightThreadAndFilepath(timeProton, filepath)
    def self.makeCatalystObjectFromLightThreadAndFilepath(timeProton, filepath)
        # There is a check we need to do here: whether or not the timeProton should be taken out of sleeping
        if timeProton["status"][0] == "sleeping" then
            timeSinceGoingToSleep = Time.new.to_i - timeProton["status"][1]
            if timeSinceGoingToSleep >= 20*3600 then
                # Here we need to get it out of sleep
                timeProton["status"] = ["active-paused", 0]
                LightThreadUtils::commitLightThreadToDisk(timeProton, File.basename(filepath))
            end
        end

        if timeProton["status"][0] == "active-paused" and LightThreadUtils::lightThreadToLivePercentage(timeProton) > 100 then
            timeProton["status"] = ["sleeping", Time.new.to_i]
            LightThreadUtils::commitLightThreadToDisk(timeProton, File.basename(filepath))
        end

        if timeProton["status"][0] == "active-runnning" and LightThreadUtils::lightThreadToLivePercentage(timeProton) > 100 then
            system("terminal-notifier -title 'Catalyst TimeProton' -message '#{timeProton["description"].gsub("'","")} is done'")
        end

        uuid = timeProton["uuid"]
        description = timeProton["description"]
        object              = {}
        object["uuid"]      = uuid # the catalyst object has the same uuid as the timeProton
        object["agent-uid"] = "201cac75-9ecc-4cac-8ca1-2643e962a6c6"
        object["metric"]    = LightThreadUtils::lightThread2Metric(timeProton)
        object["announce"]  = LightThreadUtils::timeProtonToString(timeProton)
        object["commands"]  = LightThreadUtils::trueIfLightThreadIsRunning(timeProton) ? ["stop"] : ["start", "time:", "dive"]
        object["default-expression"] = LightThreadUtils::trueIfLightThreadIsRunning(timeProton) ? "stop" : "start"
        object["is-running"] = LightThreadUtils::trueIfLightThreadIsRunning(timeProton)
        object["item-data"] = {}
        object["item-data"]["filepath"] = filepath
        object["item-data"]["timeProton"] = timeProton
        object 
    end

    # LightThreadUtils::startLightThread(timeprotonuuid)
    def self.startLightThread(timeprotonuuid)
        timeProton = LightThreadUtils::getLightThreadByUUIDOrNull(timeprotonuuid)
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
        filepath = LightThreadUtils::getLightThreadFilepathFromItsUUIDOrNull(timeProton["uuid"])
        LightThreadUtils::commitLightThreadToDisk(timeProton, File.basename(filepath))
    end

    # LightThreadUtils::stopLightThread(timeprotonuuid)
    def self.stopLightThread(timeprotonuuid)
        timeProton = LightThreadUtils::getLightThreadByUUIDOrNull(timeprotonuuid)
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
        filepath = LightThreadUtils::getLightThreadFilepathFromItsUUIDOrNull(timeProton["uuid"])
        LightThreadUtils::commitLightThreadToDisk(timeProton, File.basename(filepath))

        # Admin for the day
        LightThreadDailyTimeTracking::addTimespanForTimeProton(timeProton["uuid"], timeDoneInSeconds)
    end

    # LightThreadUtils::lightThreadAddTime(timeprotonuuid, timeInHours)
    def self.lightThreadAddTime(timeprotonuuid, timeInHours)
        timeProton = LightThreadUtils::getLightThreadByUUIDOrNull(timeprotonuuid)
        return if timeProton.nil?
        filepath = LightThreadUtils::getLightThreadFilepathFromItsUUIDOrNull(timeprotonuuid)
        return if filepath.nil?
        if timeProton["status"][0] == "sleeping" then
            timeProton["status"] = ["active-paused", 0]
        end
        timeProton["status"][1] = timeProton["status"][1] + timeInHours*3600
        LightThreadUtils::commitLightThreadToDisk(timeProton, File.basename(filepath))

        # Admin for the day
        LightThreadDailyTimeTracking::addTimespanForTimeProton(timeProton["uuid"], timeInHours*3600)
    end

    # LightThreadUtils::lightThreadToLiveDoneTimeSpan(timeProton)
    def self.lightThreadToLiveDoneTimeSpan(timeProton)
        status = timeProton["status"]
        return 0 if status[0]=="sleeping"
        return status[1] if status[0]=="active-paused"
        status[1] + (Time.new.to_i-status[2])
    end

    # LightThreadUtils::lightThreadToLivePercentage(timeProton)
    def self.lightThreadToLivePercentage(timeProton)
        100*LightThreadUtils::lightThreadToLiveDoneTimeSpan(timeProton).to_f/(3600*timeProton["time-commitment-every-20-hours-in-hours"])
    end

    # LightThreadUtils::timeProtonToString(timeProton)
    def self.timeProtonToString(timeProton)
        status = timeProton["status"]
        if status[0]=="sleeping" then
            percentageAsString = "sleeping / "
        end
        if status[0]=="active-paused" then
            percentageAsString = "#{LightThreadUtils::lightThreadToLivePercentage(timeProton).round(2)}% of "
        end
        if status[0]=="active-runnning" then
            percentageAsString = "#{LightThreadUtils::lightThreadToLivePercentage(timeProton).round(2)}% of "
        end
        timeAsString = "(#{percentageAsString}#{timeProton["time-commitment-every-20-hours-in-hours"].round(2)} hours)"
        itemsAsString = "(#{MetadataInterface::lightThreadCatalystObjectsUUIDs(timeProton["uuid"]).size} objects)"
        "timeProton: #{timeProton["description"]} #{timeAsString} #{itemsAsString}"
    end

    # LightThreadUtils::interactivelySelectLightThreadOrNull()
    def self.interactivelySelectLightThreadOrNull()
        timeProtons = LightThreadUtils::lightThreadsWithFilepaths()
            .map{|data| data[0] }
        timeProton = LucilleCore::selectEntityFromListOfEntitiesOrNull("timeProton:", timeProtons, lambda{|timeProton| LightThreadUtils::timeProtonToString(timeProton) })  
        timeProton    
    end

    # -----------------------------------------------
    # UI Utils

    # LightThreadUtils::lightThreadDive(timeProton)
    def self.lightThreadDive(timeProton)
        loop {
            puts "-> #{LightThreadUtils::timeProtonToString(timeProton)}"
            puts "-> timeProton uuid: #{timeProton["uuid"]}"
            operation = LucilleCore::selectEntityFromListOfEntitiesOrNull("operation:", ["start", "stop", "time:", "show items", "remove items", "time commitment:", "edit object", "destroy"])
            break if operation.nil?
            if operation=="start" then
                LightThreadUtils::startLightThread(timeProton)
            end
            if operation=="stop" then
                LightThreadUtils::stopLightThread(timeProton)
            end
            if operation=="time:" then
                timeInHours = LucilleCore::askQuestionAnswerAsString("Time in hours: ").to_f
                LightThreadUtils::lightThreadAddTime(timeprotonuuid, timeInHours)
            end
            if operation == "show items" then
                loop {
                    lightThreadCatalystObjectsUUIDs = MetadataInterface::lightThreadCatalystObjectsUUIDs(timeProton["uuid"])
                    objects = CatalystObjectsOperator::getObjects().select{ |object| lightThreadCatalystObjectsUUIDs.include?(object["uuid"]) }
                    selectedobject = LucilleCore::selectEntityFromListOfEntitiesOrNull("object", objects, lambda{ |object| CommonsUtils::objectToString(object) })
                    break if selectedobject.nil?
                    CommonsUtils::doPresentObjectInviteAndExecuteCommand(selectedobject)
                }
            end
            if operation == "remove items" then
                loop {
                    lightThreadCatalystObjectsUUIDs = MetadataInterface::lightThreadCatalystObjectsUUIDs(timeProton["uuid"])
                    objects = CatalystObjectsOperator::getObjects().select{ |object| lightThreadCatalystObjectsUUIDs.include?(object["uuid"]) }
                    selectedobject = LucilleCore::selectEntityFromListOfEntitiesOrNull("object", objects, lambda{ |object| CommonsUtils::objectToString(object) })
                    break if selectedobject.nil?
                    MetadataInterface::unSetTimeProtonObjectLink(timeProton["uuid"], selectedobject["uuid"])
                }
            end
            if operation=="time commitment:" then
                timeCommitmentEvery20Hours = LucilleCore::askQuestionAnswerAsString("time commitment every day (every 20 hours): ").to_f
                timeProton["time-commitment-every-20-hours-in-hours"] = timeCommitmentEvery20Hours
                LightThreadUtils::commitLightThreadToDisk(timeProton, File.basename(LightThreadUtils::getLightThreadFilepathFromItsUUIDOrNull(timeProton["uuid"])))
            end
            if operation=="edit object" then
                filepath = LightThreadUtils::getLightThreadFilepathFromItsUUIDOrNull(timeProton["uuid"])
                system("open '#{filepath}'")
            end
            if operation=="destroy" then
                answer = LucilleCore::askQuestionAnswerAsBoolean("You are about to destroy this Time Proton, are you sure you want to do that ? ")
                if answer then
                    timeprotonfilepath = LightThreadUtils::getLightThreadFilepathFromItsUUIDOrNull(timeProton["uuid"])
                    if File.exists?(timeprotonfilepath) then
                        FileUtils.rm(timeprotonfilepath)
                    end
                end
                break
            end
        }
    end

    # LightThreadUtils::lightThreadsDive()
    def self.lightThreadsDive()
        loop {
            timeProton = LightThreadUtils::interactivelySelectLightThreadOrNull()
            return if timeProton.nil?
            LightThreadUtils::lightThreadDive(timeProton)
        }
    end

end