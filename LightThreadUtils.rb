
# encoding: UTF-8

class LightThreadUtils

    # LightThreadUtils::lightThreadsWithFilepaths(): [lightThread, filepath]
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
                lightThread = data[0]
                lightThread["time-commitment-every-20-hours-in-hours"]
            }
            .inject(0, :+)
    end

    # LightThreadUtils::currentTotalDoneInHours()
    def self.currentTotalDoneInHours()
        LightThreadUtils::lightThreadsWithFilepaths()
            .select{|data| 
                lightThread = data[0]
                ["active-paused", "active-runnning"].include?(lightThread["status"])
            }
            .map{|data| 
                lightThread = data[0]
                currentStatus = lightThread["status"]
                currentStatus[1]
            }
            .inject(0, :+)
            .to_f/3600
    end

    # LightThreadUtils::commitLightThreadToDisk(lightThread, filename)
    def self.commitLightThreadToDisk(lightThread, filename)
        File.open("#{CATALYST_COMMON_DATABANK_CATALYST_FOLDERPATH}/System-Data/Light-Threads/#{filename}", "w") { |f| f.puts(JSON.pretty_generate(lightThread)) }
    end

    # LightThreadUtils::makeNewLightThread(description, timeCommitmentEvery20Hours, target)
    def self.makeNewLightThread(description, timeCommitmentEvery20Hours, target)
        lightThread = {
            "uuid"           => SecureRandom.hex(4),
            "unixtime"       => Time.new.to_i,
            "description"    => description,
            "time-commitment-every-20-hours-in-hours" => timeCommitmentEvery20Hours,
            "status"         => ["sleeping", 0]
        }
        LightThreadUtils::commitLightThreadToDisk(lightThread, "#{LucilleCore::timeStringL22()}.json")
        lightThread
    end

    # LightThreadUtils::getLightThreadByUUIDOrNull(lightThreadUUID)
    def self.getLightThreadByUUIDOrNull(lightThreadUUID)
        LightThreadUtils::lightThreadsWithFilepaths()
            .map{|pair| pair.first }
            .select{|lightThread| lightThread["uuid"]==lightThreadUUID }
            .first
    end

    # LightThreadUtils::getLightThreadFilepathFromItsUUIDOrNull(lightThreadUUID)
    def self.getLightThreadFilepathFromItsUUIDOrNull(lightThreadUUID)
        LightThreadUtils::lightThreadsWithFilepaths()
            .select{|pair| pair[0]["uuid"]==lightThreadUUID }
            .each{|pair|  
                return pair[1]
            }
        nil
    end

    # LightThreadUtils::lightThread2Metric(lightThread)
    def self.lightThread2Metric(lightThread)
        # Logic: set to 0.9 and I let Cycles Operator deal with it.
        currentStatus = lightThread["status"]
        metric = 0.9
        metric = 0.1 if currentStatus[0] == "sleeping"
        metric = 2.0 if currentStatus[0] == "active-runnning"
        metric + CommonsUtils::traceToMetricShift(lightThread["uuid"])
    end

    # LightThreadUtils::trueIfLightThreadIsRunning(lightThread)
    def self.trueIfLightThreadIsRunning(lightThread)
        lightThread["status"][0] == "active-runnning"
    end

    # LightThreadUtils::makeCatalystObjectFromLightThreadAndFilepath(lightThread, filepath)
    def self.makeCatalystObjectFromLightThreadAndFilepath(lightThread, filepath)
        # There is a check we need to do here: whether or not the lightThread should be taken out of sleeping
        if lightThread["status"][0] == "sleeping" then
            timeSinceGoingToSleep = Time.new.to_i - lightThread["status"][1]
            if timeSinceGoingToSleep >= 20*3600 then
                # Here we need to get it out of sleep
                lightThread["status"] = ["active-paused", 0]
                LightThreadUtils::commitLightThreadToDisk(lightThread, File.basename(filepath))
            end
        end

        if lightThread["status"][0] == "active-paused" and LightThreadUtils::lightThreadToLivePercentage(lightThread) > 100 then
            lightThread["status"] = ["sleeping", Time.new.to_i]
            LightThreadUtils::commitLightThreadToDisk(lightThread, File.basename(filepath))
        end

        if lightThread["status"][0] == "active-runnning" and LightThreadUtils::lightThreadToLivePercentage(lightThread) > 100 then
            system("terminal-notifier -title 'Catalyst TimeProton' -message '#{lightThread["description"].gsub("'","")} is done'")
        end

        uuid = lightThread["uuid"]
        description = lightThread["description"]
        object              = {}
        object["uuid"]      = uuid # the catalyst object has the same uuid as the lightThread
        object["agent-uid"] = "201cac75-9ecc-4cac-8ca1-2643e962a6c6"
        object["metric"]    = LightThreadUtils::lightThread2Metric(lightThread)
        object["announce"]  = LightThreadUtils::lightThreadToString(lightThread)
        object["commands"]  = LightThreadUtils::trueIfLightThreadIsRunning(lightThread) ? ["stop"] : ["start", "time:", "dive"]
        object["default-expression"] = LightThreadUtils::trueIfLightThreadIsRunning(lightThread) ? "stop" : "start"
        object["is-running"] = LightThreadUtils::trueIfLightThreadIsRunning(lightThread)
        object["item-data"] = {}
        object["item-data"]["filepath"] = filepath
        object["item-data"]["lightThread"] = lightThread
        object 
    end

    # LightThreadUtils::startLightThread(lightThreadUUID)
    def self.startLightThread(lightThreadUUID)
        lightThread = LightThreadUtils::getLightThreadByUUIDOrNull(lightThreadUUID)
        return if lightThread.nil?
        currentStatus = lightThread["status"]
        return if currentStatus[0] == "active-runnning" 
        if currentStatus[0] == "active-paused" then
            status = ["active-runnning", currentStatus[1], Time.new.to_i] 
        end
        if currentStatus[0] == "sleeping" then
            status = ["active-runnning", 0, Time.new.to_i] 
        end 
        lightThread["status"] = status
        filepath = LightThreadUtils::getLightThreadFilepathFromItsUUIDOrNull(lightThread["uuid"])
        LightThreadUtils::commitLightThreadToDisk(lightThread, File.basename(filepath))
    end

    # LightThreadUtils::stopLightThread(lightThreadUUID)
    def self.stopLightThread(lightThreadUUID)
        lightThread = LightThreadUtils::getLightThreadByUUIDOrNull(lightThreadUUID)
        return if lightThread.nil?
        currentStatus = lightThread["status"]
        return if currentStatus[0] == "sleeping"
        return if currentStatus[0] == "active-paused"
        lastStartedRunningTime = currentStatus[2]
        timeDoneInSeconds = Time.new.to_i - lastStartedRunningTime
        status =
            if timeDoneInSeconds < lightThread["time-commitment-every-20-hours-in-hours"]*3600 then
                ["active-paused", timeDoneInSeconds]
            else
                ["sleeping", Time.new.to_i]
            end
        lightThread["status"] = status
        filepath = LightThreadUtils::getLightThreadFilepathFromItsUUIDOrNull(lightThread["uuid"])
        LightThreadUtils::commitLightThreadToDisk(lightThread, File.basename(filepath))

        # Admin for the day
        LightThreadDailyTimeTracking::addTimespanForTimeProton(lightThread["uuid"], timeDoneInSeconds)
    end

    # LightThreadUtils::lightThreadAddTime(lightThreadUUID, timeInHours)
    def self.lightThreadAddTime(lightThreadUUID, timeInHours)
        lightThread = LightThreadUtils::getLightThreadByUUIDOrNull(lightThreadUUID)
        return if lightThread.nil?
        filepath = LightThreadUtils::getLightThreadFilepathFromItsUUIDOrNull(lightThreadUUID)
        return if filepath.nil?
        if lightThread["status"][0] == "sleeping" then
            lightThread["status"] = ["active-paused", 0]
        end
        lightThread["status"][1] = lightThread["status"][1] + timeInHours*3600
        LightThreadUtils::commitLightThreadToDisk(lightThread, File.basename(filepath))

        # Admin for the day
        LightThreadDailyTimeTracking::addTimespanForTimeProton(lightThread["uuid"], timeInHours*3600)
    end

    # LightThreadUtils::lightThreadToLiveDoneTimeSpan(lightThread)
    def self.lightThreadToLiveDoneTimeSpan(lightThread)
        status = lightThread["status"]
        return 0 if status[0]=="sleeping"
        return status[1] if status[0]=="active-paused"
        status[1] + (Time.new.to_i-status[2])
    end

    # LightThreadUtils::lightThreadToLivePercentage(lightThread)
    def self.lightThreadToLivePercentage(lightThread)
        100*LightThreadUtils::lightThreadToLiveDoneTimeSpan(lightThread).to_f/(3600*lightThread["time-commitment-every-20-hours-in-hours"])
    end

    # LightThreadUtils::lightThreadToString(lightThread)
    def self.lightThreadToString(lightThread)
        status = lightThread["status"]
        if status[0]=="sleeping" then
            percentageAsString = "sleeping / "
        end
        if status[0]=="active-paused" then
            percentageAsString = "#{LightThreadUtils::lightThreadToLivePercentage(lightThread).round(2)}% of "
        end
        if status[0]=="active-runnning" then
            percentageAsString = "#{LightThreadUtils::lightThreadToLivePercentage(lightThread).round(2)}% of "
        end
        timeAsString = "(#{percentageAsString}#{lightThread["time-commitment-every-20-hours-in-hours"].round(2)} hours)"
        itemsAsString = "(#{MetadataInterface::lightThreadCatalystObjectsUUIDs(lightThread["uuid"]).size} objects)"
        "lightThread: #{lightThread["description"]} #{timeAsString} #{itemsAsString}"
    end

    # LightThreadUtils::interactivelySelectLightThreadOrNull()
    def self.interactivelySelectLightThreadOrNull()
        lightThreads = LightThreadUtils::lightThreadsWithFilepaths()
            .map{|data| data[0] }
        lightThread = LucilleCore::selectEntityFromListOfEntitiesOrNull("lightThread:", lightThreads, lambda{|lightThread| LightThreadUtils::lightThreadToString(lightThread) })  
        lightThread    
    end

    # -----------------------------------------------
    # UI Utils

    # LightThreadUtils::lightThreadDive(lightThread)
    def self.lightThreadDive(lightThread)
        loop {
            puts "-> #{LightThreadUtils::lightThreadToString(lightThread)}"
            puts "-> lightThread uuid: #{lightThread["uuid"]}"
            operation = LucilleCore::selectEntityFromListOfEntitiesOrNull("operation:", ["start", "stop", "time:", "show items", "remove items", "time commitment:", "edit object", "destroy"])
            break if operation.nil?
            if operation=="start" then
                LightThreadUtils::startLightThread(lightThread)
            end
            if operation=="stop" then
                LightThreadUtils::stopLightThread(lightThread)
            end
            if operation=="time:" then
                timeInHours = LucilleCore::askQuestionAnswerAsString("Time in hours: ").to_f
                LightThreadUtils::lightThreadAddTime(lightThreadUUID, timeInHours)
            end
            if operation == "show items" then
                loop {
                    lightThreadCatalystObjectsUUIDs = MetadataInterface::lightThreadCatalystObjectsUUIDs(lightThread["uuid"])
                    objects = CatalystObjectsOperator::getObjects().select{ |object| lightThreadCatalystObjectsUUIDs.include?(object["uuid"]) }
                    selectedobject = LucilleCore::selectEntityFromListOfEntitiesOrNull("object", objects, lambda{ |object| CommonsUtils::objectToString(object) })
                    break if selectedobject.nil?
                    CommonsUtils::doPresentObjectInviteAndExecuteCommand(selectedobject)
                }
            end
            if operation == "remove items" then
                loop {
                    lightThreadCatalystObjectsUUIDs = MetadataInterface::lightThreadCatalystObjectsUUIDs(lightThread["uuid"])
                    objects = CatalystObjectsOperator::getObjects().select{ |object| lightThreadCatalystObjectsUUIDs.include?(object["uuid"]) }
                    selectedobject = LucilleCore::selectEntityFromListOfEntitiesOrNull("object", objects, lambda{ |object| CommonsUtils::objectToString(object) })
                    break if selectedobject.nil?
                    MetadataInterface::unSetTimeProtonObjectLink(lightThread["uuid"], selectedobject["uuid"])
                }
            end
            if operation=="time commitment:" then
                timeCommitmentEvery20Hours = LucilleCore::askQuestionAnswerAsString("time commitment every day (every 20 hours): ").to_f
                lightThread["time-commitment-every-20-hours-in-hours"] = timeCommitmentEvery20Hours
                LightThreadUtils::commitLightThreadToDisk(lightThread, File.basename(LightThreadUtils::getLightThreadFilepathFromItsUUIDOrNull(lightThread["uuid"])))
            end
            if operation=="edit object" then
                filepath = LightThreadUtils::getLightThreadFilepathFromItsUUIDOrNull(lightThread["uuid"])
                system("open '#{filepath}'")
            end
            if operation=="destroy" then
                answer = LucilleCore::askQuestionAnswerAsBoolean("You are about to destroy this Time Proton, are you sure you want to do that ? ")
                if answer then
                    lightThreadFilepath = LightThreadUtils::getLightThreadFilepathFromItsUUIDOrNull(lightThread["uuid"])
                    if File.exists?(lightThreadFilepath) then
                        FileUtils.rm(lightThreadFilepath)
                    end
                end
                break
            end
        }
    end

    # LightThreadUtils::lightThreadsDive()
    def self.lightThreadsDive()
        loop {
            lightThread = LightThreadUtils::interactivelySelectLightThreadOrNull()
            return if lightThread.nil?
            LightThreadUtils::lightThreadDive(lightThread)
        }
    end

end