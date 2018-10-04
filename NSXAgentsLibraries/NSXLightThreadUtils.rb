
# encoding: UTF-8

class NSXLightThreadUtils

    # NSXLightThreadUtils::lightThreadsWithFilepaths(): [lightThread, filepath]
    def self.lightThreadsWithFilepaths()
        Dir.entries("#{CATALYST_COMMON_DATABANK_CATALYST_FOLDERPATH}/System-Data/Light-Threads")
            .select{|filename| filename[-5, 5]=='.json' }
            .map{|filename| "#{CATALYST_COMMON_DATABANK_CATALYST_FOLDERPATH}/System-Data/Light-Threads/#{filename}" }
            .map{|filepath| [JSON.parse(IO.read(filepath)), filepath] }
    end

    # NSXLightThreadUtils::commitLightThreadToDisk(lightThread, filename)
    def self.commitLightThreadToDisk(lightThread, filename)
        File.open("#{CATALYST_COMMON_DATABANK_CATALYST_FOLDERPATH}/System-Data/Light-Threads/#{filename}", "w") { |f| f.puts(JSON.pretty_generate(lightThread)) }
    end

    # NSXLightThreadUtils::makeNewLightThread(description, commitment, target)
    def self.makeNewLightThread(description, commitment, target)
        lightThread = {
            "uuid"        => SecureRandom.hex(4),
            "unixtime"    => Time.new.to_i,
            "description" => description,
            "commitment"  => commitment,
            "status"      => ["paused"],
            "done"        => []
        }
        lightThread["done"] << [Time.new.to_i, 0]
        NSXLightThreadUtils::commitLightThreadToDisk(lightThread, "#{LucilleCore::timeStringL22()}.json")
        lightThread
    end

    # NSXLightThreadUtils::getLightThreadByUUIDOrNull(lightThreadUUID)
    def self.getLightThreadByUUIDOrNull(lightThreadUUID)
        NSXLightThreadUtils::lightThreadsWithFilepaths()
            .map{|pair| pair.first }
            .select{|lightThread| lightThread["uuid"]==lightThreadUUID }
            .first
    end

    # NSXLightThreadUtils::getLightThreadFilepathFromItsUUIDOrNull(lightThreadUUID)
    def self.getLightThreadFilepathFromItsUUIDOrNull(lightThreadUUID)
        NSXLightThreadUtils::lightThreadsWithFilepaths()
            .select{|pair| pair[0]["uuid"]==lightThreadUUID }
            .each{|pair|  
                return pair[1]
            }
        nil
    end

    # NSXLightThreadUtils::trueIfLightThreadIsRunning(lightThread)
    def self.trueIfLightThreadIsRunning(lightThread)
        lightThread["status"][0] == "running-since"
    end

    # NSXLightThreadUtils::makeCatalystObjectFromLightThreadAndFilepath(lightThread, filepath)
    def self.makeCatalystObjectFromLightThreadAndFilepath(lightThread, filepath)
        # There is a check we need to do here: whether or not the lightThread should be taken out of sleeping

        if lightThread["status"][0] == "running-since" and NSXLightThreadUtils::lightThreadToLivePercentage(lightThread) >= 100 then
            system("terminal-notifier -title 'Catalyst TimeProton' -message '#{lightThread["description"].gsub("'","")} is done'")
        end

        uuid = lightThread["uuid"]
        description = lightThread["description"]
        object              = {}
        object["uuid"]      = uuid # the catalyst object has the same uuid as the lightThread
        object["agent-uid"] = "201cac75-9ecc-4cac-8ca1-2643e962a6c6"
        object["metric"]    = NSXLightThreadUtils::lightThread2Metric(lightThread)
        object["announce"]  = NSXLightThreadUtils::lightThreadToString(lightThread)
        object["commands"]  = NSXLightThreadUtils::trueIfLightThreadIsRunning(lightThread) ? ["stop"] : ["start", "time:", "dive"]
        object["default-expression"] = NSXLightThreadUtils::trueIfLightThreadIsRunning(lightThread) ? "stop" : "start"
        object["is-running"] = NSXLightThreadUtils::trueIfLightThreadIsRunning(lightThread)
        object["item-data"] = {}
        object["item-data"]["filepath"] = filepath
        object["item-data"]["lightThread"] = lightThread
        object 
    end

    # NSXLightThreadUtils::startLightThread(lightThreadUUID)
    def self.startLightThread(lightThreadUUID)
        lightThread = NSXLightThreadUtils::getLightThreadByUUIDOrNull(lightThreadUUID)
        return if lightThread.nil?
        return if lightThread["status"][0] == "running-since" 
        lightThread["status"] = ["running-since", Time.new.to_i]
        filepath = NSXLightThreadUtils::getLightThreadFilepathFromItsUUIDOrNull(lightThread["uuid"])
        NSXLightThreadUtils::commitLightThreadToDisk(lightThread, File.basename(filepath))
        ## Because we do not return anything, every call to this command should be followed by 
        ## signal = ["reload-agent-objects", self::agentuuid()]
        ## NSXCatalystObjectsOperator::processAgentProcessorSignal(signal)
    end

    # NSXLightThreadUtils::stopLightThread(lightThreadUUID)
    def self.stopLightThread(lightThreadUUID)
        lightThread = NSXLightThreadUtils::getLightThreadByUUIDOrNull(lightThreadUUID)
        return if lightThread.nil?
        return if lightThread["status"][0] == "paused" 
        recordItem = [ lightThread["status"][1], Time.new.to_i - lightThread["status"][1] ]
        lightThread["done"] << recordItem
        lightThread["status"] = ["paused"]
        filepath = NSXLightThreadUtils::getLightThreadFilepathFromItsUUIDOrNull(lightThread["uuid"])
        NSXLightThreadUtils::commitLightThreadToDisk(lightThread, File.basename(filepath))
        ## Because we do not return anything, every call to this command should be followed by 
        ## signal = ["reload-agent-objects", self::agentuuid()]
        ## NSXCatalystObjectsOperator::processAgentProcessorSignal(signal)
    end

    # NSXLightThreadUtils::lightThreadAddTime(lightThreadUUID, timeInHours)
    def self.lightThreadAddTime(lightThreadUUID, timeInHours)
        lightThread = NSXLightThreadUtils::getLightThreadByUUIDOrNull(lightThreadUUID)
        return if lightThread.nil?
        lightThread["done"] << [Time.new.to_i, timeInHours * 3600]
        filepath = NSXLightThreadUtils::getLightThreadFilepathFromItsUUIDOrNull(lightThreadUUID)
        NSXLightThreadUtils::commitLightThreadToDisk(lightThread, File.basename(filepath))
        ## Because we do not return anything, every call to this command should be followed by 
        ## signal = ["reload-agent-objects", self::agentuuid()]
        ## NSXCatalystObjectsOperator::processAgentProcessorSignal(signal)
    end

    # NSXLightThreadUtils::lightThread2Metric(lightThread)
    def self.lightThread2Metric(lightThread)
        return 2 if lightThread["status"][0] == "running-since"
        metric = 0.8 - 0.5*NSXLightThreadUtils::lightThreadToLivePercentage(lightThread).to_f/100 # at 100% we are still at 0.3
        metric - NSXMiscUtils::traceToMetricShift(lightThread["uuid"])
    end

    # NSXLightThreadUtils::lightThreadToRealisedTimeSpanInSeconds(lightThread)
    def self.lightThreadToRealisedTimeSpanInSeconds(lightThread)
        lightThread["done"].map{|item| item[1] }.inject(0, :+)
    end

    # NSXLightThreadUtils::lightThreadToLiveDoneTimeSpanInSeconds(lightThread)
    def self.lightThreadToLiveDoneTimeSpanInSeconds(lightThread)
        doneTime = NSXLightThreadUtils::lightThreadToRealisedTimeSpanInSeconds(lightThread)
        if lightThread["status"][0] == "running-since" then
            doneTime = Time.new.to_i - lightThread["status"][1]
        end
        doneTime
    end

    # NSXLightThreadUtils::lightThreadToLivePercentage(lightThread)
    def self.lightThreadToLivePercentage(lightThread)
        return 0 if lightThread["done"].size==0
        oldestUnixtime = lightThread["done"][0][0]
        calendarTimespanInSeconds = Time.new.to_i - oldestUnixtime
        calendarTimespanInDays = calendarTimespanInSeconds.to_f/86400
        timeDoneExpectationInHours = calendarTimespanInDays * lightThread["commitment"]
        timeDoneRealisedInHours = NSXLightThreadUtils::lightThreadToLiveDoneTimeSpanInSeconds(lightThread).to_f/3600
        100 * (timeDoneRealisedInHours.to_f / timeDoneExpectationInHours)
    end

    # NSXLightThreadUtils::lightThreadToString(lightThread)
    def self.lightThreadToString(lightThread)
        percentageAsString = "#{NSXLightThreadUtils::lightThreadToLivePercentage(lightThread).round(2)}%"
        itemsAsString = "(#{NSXCatalystMetadataInterface::lightThreadCatalystObjectsUUIDs(lightThread["uuid"]).size} objects)"
        "lightThread: #{lightThread["description"]} { #{percentageAsString} } #{itemsAsString}"
    end

    # NSXLightThreadUtils::interactivelySelectLightThreadOrNull()
    def self.interactivelySelectLightThreadOrNull()
        lightThreads = NSXLightThreadUtils::lightThreadsWithFilepaths()
            .map{|data| data[0] }
        lightThread = LucilleCore::selectEntityFromListOfEntitiesOrNull("lightThread:", lightThreads, lambda{|lightThread| NSXLightThreadUtils::lightThreadToString(lightThread) })  
        lightThread    
    end

    # -----------------------------------------------
    # UI Utils

    # NSXLightThreadUtils::lightThreadDive(lightThread)
    def self.lightThreadDive(lightThread)
        loop {
            puts "-> #{NSXLightThreadUtils::lightThreadToString(lightThread)}"
            puts "-> lightThread uuid: #{lightThread["uuid"]}"
            puts "-> lightThreadToLivePercentage: #{NSXLightThreadUtils::lightThreadToLivePercentage(lightThread)}"
            operation = LucilleCore::selectEntityFromListOfEntitiesOrNull("operation:", ["start", "stop", "time:", "show items", "remove items", "time commitment:", "edit object", "destroy"])
            break if operation.nil?
            if operation=="start" then
                NSXLightThreadUtils::startLightThread(lightThread)
                signal = ["reload-agent-objects", self::agentuuid()]
                NSXCatalystObjectsOperator::processAgentProcessorSignal(signal)
            end
            if operation=="stop" then
                NSXLightThreadUtils::stopLightThread(lightThread)
                signal = ["reload-agent-objects", self::agentuuid()]
                NSXCatalystObjectsOperator::processAgentProcessorSignal(signal)
            end
            if operation=="time:" then
                timeInHours = LucilleCore::askQuestionAnswerAsString("Time in hours: ").to_f
                NSXLightThreadUtils::lightThreadAddTime(lightThread["uuid"], timeInHours)
                signal = ["reload-agent-objects", self::agentuuid()]
                NSXCatalystObjectsOperator::processAgentProcessorSignal(signal)
            end
            if operation == "show items" then
                loop {
                    lightThreadCatalystObjectsUUIDs = NSXCatalystMetadataInterface::lightThreadCatalystObjectsUUIDs(lightThread["uuid"])
                    objects = NSXCatalystObjectsOperator::getObjects().select{ |object| lightThreadCatalystObjectsUUIDs.include?(object["uuid"]) }
                    selectedobject = LucilleCore::selectEntityFromListOfEntitiesOrNull("object", objects, lambda{ |object| NSXMiscUtils::objectToString(object) })
                    break if selectedobject.nil?
                    NSXMiscUtils::doPresentObjectInviteAndExecuteCommand(selectedobject)
                }
            end
            if operation == "remove items" then
                loop {
                    lightThreadCatalystObjectsUUIDs = NSXCatalystMetadataInterface::lightThreadCatalystObjectsUUIDs(lightThread["uuid"])
                    objects = NSXCatalystObjectsOperator::getObjects().select{ |object| lightThreadCatalystObjectsUUIDs.include?(object["uuid"]) }
                    selectedobject = LucilleCore::selectEntityFromListOfEntitiesOrNull("object", objects, lambda{ |object| NSXMiscUtils::objectToString(object) })
                    break if selectedobject.nil?
                    NSXCatalystMetadataInterface::unSetTimeProtonObjectLink(lightThread["uuid"], selectedobject["uuid"])
                }
            end
            if operation=="time commitment:" then
                commitment = LucilleCore::askQuestionAnswerAsString("time commitment every day (every 20 hours): ").to_f
                lightThread["commitment"] = commitment
                NSXLightThreadUtils::commitLightThreadToDisk(lightThread, File.basename(NSXLightThreadUtils::getLightThreadFilepathFromItsUUIDOrNull(lightThread["uuid"])))
            end
            if operation=="edit object" then
                filepath = NSXLightThreadUtils::getLightThreadFilepathFromItsUUIDOrNull(lightThread["uuid"])
                system("open '#{filepath}'")
            end
            if operation=="destroy" then
                answer = LucilleCore::askQuestionAnswerAsBoolean("You are about to destroy this Time Proton, are you sure you want to do that ? ")
                if answer then
                    lightThreadFilepath = NSXLightThreadUtils::getLightThreadFilepathFromItsUUIDOrNull(lightThread["uuid"])
                    if File.exists?(lightThreadFilepath) then
                        FileUtils.rm(lightThreadFilepath)
                    end
                end
                break
            end
        }
    end

    # NSXLightThreadUtils::lightThreadsDive()
    def self.lightThreadsDive()
        loop {
            lightThread = NSXLightThreadUtils::interactivelySelectLightThreadOrNull()
            return if lightThread.nil?
            NSXLightThreadUtils::lightThreadDive(lightThread)
        }
    end

end