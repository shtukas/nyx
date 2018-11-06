
# encoding: UTF-8

require 'time'

require "/Galaxy/Software/Misc-Common/Ruby-Libraries/Iphetra.rb"
=begin
    Iphetra::commitObjectToDisk(repositoryRootFolderPath, setuuid, object)
    Iphetra::getObjectByUUIDOrNull(repositoryRootFolderPath, setuuid, objectuuid)
    Iphetra::getObjects(repositoryRootFolderPath, setuuid)
=end

LIGHT_THREAD_DONE_TIMESPAN_IN_DAYS = 7
LIGHT_THREADS_SETUUID = "d85fe272-b37a-4afa-9815-afa2cf5041ff"


class NSXLightThreadMetrics

    # NSXLightThreadMetrics::lightThreadToRealisedTimeSpanInSecondsOverThePastNDays(lightThreadUUID, n)
    def self.lightThreadToRealisedTimeSpanInSecondsOverThePastNDays(lightThreadUUID, n)
        NSXLightThreadUtils::getLightThreadTimeRecordItems(lightThreadUUID)
            .select{|item| (Time.new.to_i-item["unixtime"])<=(86400*n) }
            .map{|item| item["timespan"] }.inject(0, :+)
    end

    # NSXLightThreadMetrics::lightThreadToLiveAndOrSimulatedDoneTimeSpanInSecondsOverThePastNDays(lightThread, n, simulationTimeInSeconds = 0)
    def self.lightThreadToLiveAndOrSimulatedDoneTimeSpanInSecondsOverThePastNDays(lightThread, n, simulationTimeInSeconds = 0)
        doneTime = NSXLightThreadMetrics::lightThreadToRealisedTimeSpanInSecondsOverThePastNDays(lightThread["uuid"], n)
        if lightThread["status"][0] == "running-since" then
            doneTime = doneTime + (Time.new.to_i - lightThread["status"][1])
        end
        doneTime = doneTime + simulationTimeInSeconds
        doneTime
    end

    # NSXLightThreadMetrics::lightThreadToLivePercentageOverThePastNDays(lightThread, n, simulationTimeInSeconds = 0)
    def self.lightThreadToLivePercentageOverThePastNDays(lightThread, n, simulationTimeInSeconds = 0)
        items = NSXLightThreadUtils::getLightThreadTimeRecordItems(lightThread["uuid"])
        return 0 if ( (simulationTimeInSeconds==0) and (items.size==0) and (lightThread["status"][0]=="paused") )
        timeDoneExpectationInHours = n * lightThread["commitment"] # The commitment is daily
        timeDoneLiveInHours = NSXLightThreadMetrics::lightThreadToLiveAndOrSimulatedDoneTimeSpanInSecondsOverThePastNDays(lightThread, n, simulationTimeInSeconds).to_f/3600
        100 * (timeDoneLiveInHours.to_f / timeDoneExpectationInHours)
    end

    # NSXLightThreadMetrics::lightThread2MetricOverThePastNDays(lightThread, n, simulationTimeInSeconds = 0)
    def self.lightThread2MetricOverThePastNDays(lightThread, n, simulationTimeInSeconds = 0)
        return 2 if ( simulationTimeInSeconds==0 and lightThread["status"][0] == "running-since" )
        metric = 0.2 - 0.6*Math.exp(-1.5) + 0.6*Math.exp(-NSXLightThreadMetrics::lightThreadToLivePercentageOverThePastNDays(lightThread, n, simulationTimeInSeconds).to_f/100) # at 100% we are at 0.2 - 0.6*Math.exp(-1.5) + 0.6*Math.exp(-1) 
        metric - NSXMiscUtils::traceToMetricShift(lightThread["uuid"])
    end

    # NSXLightThreadMetrics::lightThread2Metric(lightThread, simulationTimeInSeconds = 0)
    def self.lightThread2Metric(lightThread, simulationTimeInSeconds = 0)
        # Here we take the min of NSXLightThreadMetrics::lightThread2MetricOverThePastNDays(lightThread, n) for n=1..7
        (1..7).map{|indx| NSXLightThreadMetrics::lightThread2MetricOverThePastNDays(lightThread, indx, simulationTimeInSeconds) }.min
    end

end

class NSXLightThreadUtils

    # NSXLightThreadUtils::lightThreads(): Array[LightThread]
    def self.lightThreads()
        Iphetra::getObjects(CATALYST_IPHETRA_DATA_REPOSITORY_FOLDERPATH, LIGHT_THREADS_SETUUID)
    end

    # NSXLightThreadUtils::commitLightThreadToDisk(lightThread)
    def self.commitLightThreadToDisk(lightThread)
        Iphetra::commitObjectToDisk(CATALYST_IPHETRA_DATA_REPOSITORY_FOLDERPATH, LIGHT_THREADS_SETUUID, lightThread)
    end

    # NSXLightThreadUtils::makeNewLightThread(description, commitment, target)
    def self.makeNewLightThread(description, commitment, target)
        uuid = SecureRandom.hex(4)
        lightThread = {
            "uuid"        => uuid,
            "unixtime"    => Time.new.to_i,
            "description" => description,
            "commitment"  => commitment,
            "status"      => ["paused"]
        }
        NSXLightThreadUtils::issueLightThreadTimeRecordItem(uuid, Time.new.to_i, 0)
        NSXLightThreadUtils::commitLightThreadToDisk(lightThread)
        lightThread
    end

    # NSXLightThreadUtils::getLightThreadByUUIDOrNull(lightThreadUUID)
    def self.getLightThreadByUUIDOrNull(lightThreadUUID)
        Iphetra::getObjectByUUIDOrNull(CATALYST_IPHETRA_DATA_REPOSITORY_FOLDERPATH, LIGHT_THREADS_SETUUID, lightThreadUUID)
    end

    # NSXLightThreadUtils::trueIfLightThreadIsRunning(lightThread)
    def self.trueIfLightThreadIsRunning(lightThread)
        lightThread["status"][0] == "running-since"
    end

    # NSXLightThreadUtils::lightThreadToCatalystObject(lightThread)
    def self.lightThreadToCatalystObject(lightThread)
        # There is a check we need to do here: whether or not the lightThread should be taken out of sleeping

        if lightThread["status"][0] == "running-since" and NSXLightThreadMetrics::lightThreadToLivePercentageOverThePastNDays(lightThread, 1) >= 100 then
            NSXMiscUtils::issueScreenNotification("Catalyst TimeProton", "#{lightThread["description"].gsub("'","")} is done")
        end

        uuid = lightThread["uuid"]
        description = lightThread["description"]
        object              = {}
        object["uuid"]      = uuid # the catalyst object has the same uuid as the lightThread
        object["agent-uid"] = "201cac75-9ecc-4cac-8ca1-2643e962a6c6"
        object["metric"]    = NSXLightThreadMetrics::lightThread2Metric(lightThread)
        object["announce"]  = NSXLightThreadUtils::lightThreadToString(lightThread)
        object["commands"]  = NSXLightThreadUtils::trueIfLightThreadIsRunning(lightThread) ? ["stop"] : ["start", "time: <timeInHours>", "dive"]
        object["default-expression"] = NSXLightThreadUtils::trueIfLightThreadIsRunning(lightThread) ? "stop" : "start"
        object["is-running"] = NSXLightThreadUtils::trueIfLightThreadIsRunning(lightThread)
        object["item-data"] = {}
        object["item-data"]["lightThread"] = lightThread
        object 
    end

    # NSXLightThreadUtils::startLightThread(lightThreadUUID)
    def self.startLightThread(lightThreadUUID)
        lightThread = NSXLightThreadUtils::getLightThreadByUUIDOrNull(lightThreadUUID)
        return if lightThread.nil?
        return if lightThread["status"][0] == "running-since" 
        lightThread["status"] = ["running-since", Time.new.to_i]
        NSXLightThreadUtils::commitLightThreadToDisk(lightThread)
        signal = ["reload-agent-objects", NSXAgentLightThread::agentuuid()]
        NSXCatalystObjectsOperator::processAgentProcessorSignal(signal)
    end

    # NSXLightThreadUtils::stopLightThread(lightThreadUUID)
    def self.stopLightThread(lightThreadUUID)
        lightThread = NSXLightThreadUtils::getLightThreadByUUIDOrNull(lightThreadUUID)
        return if lightThread.nil?
        return if lightThread["status"][0] == "paused" 
        unixtime = lightThread["status"][1]
        timespanInSeconds = Time.new.to_i - unixtime
        NSXLightThreadUtils::issueLightThreadTimeRecordItem(lightThread["uuid"], unixtime, timespanInSeconds)
        lightThread["status"] = ["paused"]
        NSXLightThreadUtils::commitLightThreadToDisk(lightThread)
        signal = ["reload-agent-objects", NSXAgentLightThread::agentuuid()]
        NSXCatalystObjectsOperator::processAgentProcessorSignal(signal)
    end

    # NSXLightThreadUtils::lightThreadAddTime(lightThreadUUID, timeInHours)
    def self.lightThreadAddTime(lightThreadUUID, timeInHours)
        lightThread = NSXLightThreadUtils::getLightThreadByUUIDOrNull(lightThreadUUID)
        return if lightThread.nil?
        NSXLightThreadUtils::issueLightThreadTimeRecordItem(lightThread["uuid"], Time.new.to_i, timeInHours * 3600)
        signal = ["reload-agent-objects", NSXAgentLightThread::agentuuid()]
        NSXCatalystObjectsOperator::processAgentProcessorSignal(signal)
    end

    # NSXLightThreadUtils::interactivelySelectLightThreadOrNull()
    def self.interactivelySelectLightThreadOrNull()
        lightThreads = NSXLightThreadUtils::lightThreads()
            .sort{|lt1,lt2|
                NSXLightThreadMetrics::lightThread2Metric(lt1) <=> NSXLightThreadMetrics::lightThread2Metric(lt2)
            }
            .reverse
        lightThread = LucilleCore::selectEntityFromListOfEntitiesOrNull("lightThread:", lightThreads, lambda{|lightThread| NSXLightThreadUtils::lightThreadToString(lightThread) })  
        lightThread
    end

    # NSXLightThreadUtils::issueLightThreadTimeRecordItem(unixtime, timespanInSeconds)
    def self.issueLightThreadTimeRecordItem(lightThreadUUID, unixtime, timespanInSeconds)
        setuuid = "#{lightThreadUUID}:DFB99806"
        object = {
            "uuid"     => SecureRandom.hex,
            "unixtime" => unixtime,
            "timespan" => timespanInSeconds
        }
        Iphetra::commitObjectToDisk(CATALYST_IPHETRA_DATA_REPOSITORY_FOLDERPATH, setuuid, object)
    end

    # NSXLightThreadUtils::getLightThreadTimeRecordItems(lightThreadUUID)
    def self.getLightThreadTimeRecordItems(lightThreadUUID)
        setuuid = "#{lightThreadUUID}:DFB99806"
        Iphetra::getObjects(CATALYST_IPHETRA_DATA_REPOSITORY_FOLDERPATH, setuuid)
            .select{|item| (Time.new.to_i-item["unixtime"]) < 86400*LIGHT_THREAD_DONE_TIMESPAN_IN_DAYS }
    end

    # NSXLightThreadUtils::lightThreadTimeTo100PercentInSeconds(lightThread)
    def self.lightThreadTimeTo100PercentInSeconds(lightThread)
        enumerator = NSXMiscUtils::integerEnumerator()
        metric100 = 0.2 - 0.6*Math.exp(-1.5) + 0.6*Math.exp(-1)
        seconds = 0
        loop {
            seconds = enumerator.next() * 200
            break if NSXLightThreadMetrics::lightThread2Metric(lightThread, seconds) <= metric100
        }
        seconds
    end

    # NSXLightThreadUtils::globalTimeTo100PercentInSeconds()
    def self.globalTimeTo100PercentInSeconds()
        NSXLightThreadUtils::lightThreads()
            .map{|lightThread| NSXLightThreadUtils::lightThreadTimeTo100PercentInSeconds(lightThread) }
            .inject(0, :+)
    end

    # -----------------------------------------------
    # .toString

    # NSXLightThreadUtils::lightThreadToString(lightThread)
    def self.lightThreadToString(lightThread)
        "lightThread: #{lightThread["description"]} (daily: #{lightThread["commitment"].round(2)} hours) (time to completion: #{(NSXLightThreadUtils::lightThreadTimeTo100PercentInSeconds(lightThread).to_f/3600).round(2)} hours) (#{NSXMiscUtils::getLT1526SecondaryObjectUUIDsForLightThread(lightThread["uuid"]).size} objects)"
    end

    # -----------------------------------------------
    # UI Utils

    # NSXLightThreadUtils::lightThreadDive(lightThread)
    def self.lightThreadDive(lightThread)
        loop {
            puts "LightThread"
            puts "     description: #{lightThread["description"]}"
            puts "     uuid: #{lightThread["uuid"]}"
            puts "     daily commitment: #{lightThread["commitment"]}"
            livePercentages = (1..7).to_a.reverse.map{|indx| NSXLightThreadMetrics::lightThreadToLivePercentageOverThePastNDays(lightThread, indx).round(2) }
            puts "     Live Percentages (7..1): %: #{livePercentages.join(" ")}"
            puts "     Time to 100%: #{(NSXLightThreadUtils::lightThreadTimeTo100PercentInSeconds(lightThread).to_f/3600).round(2)} hours"
            puts "     NSXDoNotShowUntilDatetime: #{NSXDoNotShowUntilDatetime::getDatetimeOrNull(lightThread["uuid"])}"
            puts "Items:"
            NSXMiscUtils::getLT1526SecondaryObjectUUIDsForLightThread(lightThread["uuid"])
                .each{|uuid|
                    object = NSXCatalystObjectsOperator::getObjects().select{|object| object["uuid"]==uuid }.first
                    next if object.nil?
                    puts "    "+NSXMiscUtils::objectToString(object)
                }
            operation = LucilleCore::selectEntityFromListOfEntitiesOrNull("operation:", ["start", "stop", "show time log", "time:", "show items", "remove items", "time commitment:", "destroy"])
            break if operation.nil?
            if operation=="start" then
                NSXLightThreadUtils::startLightThread(lightThread["uuid"])
                signal = ["reload-agent-objects", NSXAgentLightThread::agentuuid()]
                NSXCatalystObjectsOperator::processAgentProcessorSignal(signal)
            end
            if operation=="show time log" then
                NSXLightThreadUtils::getLightThreadTimeRecordItems(lightThread["uuid"])
                    .each{|item|
                        puts "    - #{Time.at(item["unixtime"]).to_s} : #{ (item["timespan"].to_f/3600).round(2) } hours"
                    }
                LucilleCore::pressEnterToContinue()
            end
            if operation=="stop" then
                NSXLightThreadUtils::stopLightThread(lightThread["uuid"])
                signal = ["reload-agent-objects", NSXAgentLightThread::agentuuid()]
                NSXCatalystObjectsOperator::processAgentProcessorSignal(signal)
            end
            if operation=="time:" then
                timeInHours = LucilleCore::askQuestionAnswerAsString("Time in hours: ").to_f
                NSXLightThreadUtils::lightThreadAddTime(lightThread["uuid"], timeInHours)
                signal = ["reload-agent-objects", NSXAgentLightThread::agentuuid()]
                NSXCatalystObjectsOperator::processAgentProcessorSignal(signal)
            end
            if operation == "show items" then
                loop {
                    lightThreadCatalystObjectsUUIDs = NSXMiscUtils::getLT1526SecondaryObjectUUIDsForLightThread(lightThread["uuid"])
                    objects = NSXCatalystObjectsOperator::getObjects().select{ |object| lightThreadCatalystObjectsUUIDs.include?(object["uuid"]) }
                    selectedobject = LucilleCore::selectEntityFromListOfEntitiesOrNull("object", objects, lambda{ |object| NSXMiscUtils::objectToString(object) })
                    break if selectedobject.nil?
                    NSXDisplayOperator::doPresentObjectInviteAndExecuteCommand(selectedobject)
                }
            end
            if operation == "remove items" then
                loop {
                    lightThreadCatalystObjectsUUIDs = NSXMiscUtils::getLT1526SecondaryObjectUUIDsForLightThread(lightThread["uuid"])
                    objects = NSXCatalystObjectsOperator::getObjects().select{ |object| lightThreadCatalystObjectsUUIDs.include?(object["uuid"]) }
                    selectedobject = LucilleCore::selectEntityFromListOfEntitiesOrNull("object", objects, lambda{ |object| NSXMiscUtils::objectToString(object) })
                    break if selectedobject.nil?
                    NSXMiscUtils::destroyLT1526Claim(selectedobject["uuid"])
                }
            end
            if operation=="time commitment:" then
                commitment = LucilleCore::askQuestionAnswerAsString("time commitment every day: ").to_f
                lightThread["commitment"] = commitment
                NSXLightThreadUtils::commitLightThreadToDisk(lightThread)
            end
            if operation=="destroy" then
                answer = LucilleCore::askQuestionAnswerAsBoolean("You are about to destroy this LightThread, are you sure you want to do that ? ")
                if answer then
                    Iphetra::destroyObject(CATALYST_IPHETRA_DATA_REPOSITORY_FOLDERPATH, LIGHT_THREADS_SETUUID, lightThread["uuid"])
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