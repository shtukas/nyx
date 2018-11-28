
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

class NSXLightThreadUtils

    # NSXLightThreadUtils::lightThreads(): Array[LightThread]
    def self.lightThreads()
        Iphetra::getObjects(CATALYST_IPHETRA_DATA_REPOSITORY_FOLDERPATH, LIGHT_THREADS_SETUUID)
    end

    # NSXLightThreadUtils::commitLightThreadToDisk(lightThread)
    def self.commitLightThreadToDisk(lightThread)
        Iphetra::commitObjectToDisk(CATALYST_IPHETRA_DATA_REPOSITORY_FOLDERPATH, LIGHT_THREADS_SETUUID, lightThread)
    end

    # NSXLightThreadUtils::makeNewLightThread(description, priorityXp)
    def self.makeNewLightThread(description, priorityXp)
        uuid = SecureRandom.hex(4)
        lightThread = {}
        lightThread["uuid"] = uuid
        lightThread["unixtime"] = Time.new.to_i
        lightThread["description"] = description
        lightThread["priorityXp"] = priorityXp
        lightThread["status"] = ["paused"]
        lightThread["streamuuid"] = SecureRandom.hex
        NSXLightThreadUtils::issueLightThreadTimeRecordItem(uuid, Time.new.to_i, 0)
        NSXLightThreadUtils::commitLightThreadToDisk(lightThread)
        lightThread
    end

    # NSXLightThreadUtils::getLightThreadByUUIDOrNull(lightThreadUUID)
    def self.getLightThreadByUUIDOrNull(lightThreadUUID)
        Iphetra::getObjectByUUIDOrNull(CATALYST_IPHETRA_DATA_REPOSITORY_FOLDERPATH, LIGHT_THREADS_SETUUID, lightThreadUUID)
    end

    # NSXLightThreadUtils::trueIfLightThreadIsMustBeGone(lightThread)
    def self.trueIfLightThreadIsMustBeGone(lightThread)
        return true if lightThread["priorityXp"][0]=="interruption-now"
        return true if lightThread["priorityXp"][0]=="must-be-all-done-today"
        false
    end

    # NSXLightThreadUtils::trueIfLightThreadIsRunning(lightThread)
    def self.trueIfLightThreadIsRunning(lightThread)
        lightThread["status"][0] == "running-since"
    end

    # NSXLightThreadUtils::startLightThread(lightThreadUUID)
    def self.startLightThread(lightThreadUUID)
        lightThread = NSXLightThreadUtils::getLightThreadByUUIDOrNull(lightThreadUUID)
        return if lightThread.nil?
        return if lightThread["status"][0] == "running-since" 
        lightThread["status"] = ["running-since", Time.new.to_i]
        NSXLightThreadUtils::commitLightThreadToDisk(lightThread)
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
    end

    # NSXLightThreadUtils::lightThreadAddTime(lightThreadUUID, timeInHours)
    def self.lightThreadAddTime(lightThreadUUID, timeInHours)
        lightThread = NSXLightThreadUtils::getLightThreadByUUIDOrNull(lightThreadUUID)
        return if lightThread.nil?
        NSXLightThreadUtils::issueLightThreadTimeRecordItem(lightThread["uuid"], Time.new.to_i, timeInHours * 3600)
    end

    # NSXLightThreadUtils::interactivelySelectLightThreadOrNull()
    def self.interactivelySelectLightThreadOrNull()
        lightThreads = NSXLightThreadUtils::lightThreads()
        lightThread = LucilleCore::selectEntityFromListOfEntitiesOrNull("lightThread:", lightThreads, lambda{|lightThread| NSXLightThreadUtils::lightThreadToString(lightThread) })  
        lightThread
    end

    # NSXLightThreadUtils::issueLightThreadTimeRecordItem(lightThreadUUID, unixtime, timespanInSeconds)
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

    # NSXLightThreadUtils::lightThreadTimeTo100PercentInSecondsOrNull(lightThread)
    def self.lightThreadTimeTo100PercentInSecondsOrNull(lightThread)
        return nil if lightThread["priorityXp"][0] == "interruption-now"
        return nil if lightThread["priorityXp"][0] == "must-be-all-done-today"
        enumerator = NSXMiscUtils::integerEnumerator()
        seconds = 0
        loop {
            seconds = enumerator.next() * 200
            break if NSXLightThreadMetrics::lightThread2Metric(lightThread, seconds) <= 0.2
        }
        seconds
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

    # NSXLightThreadUtils::lightThreadCanBeDestroyed(lightThread)
    def self.lightThreadCanBeDestroyed(lightThread)
        return false if NSXLightThreadsStreamsInterface::lightThreadToItsStreamItemsOrdered(lightThread).count > 0
        return false if NSXStreamsUtils::oldStreamNamesToNewStreamUUIDMapping().values.include?(lightThread["streamuuid"])
        true
    end

    # -----------------------------------------------
    # .toString

    # NSXLightThreadUtils::lightThreadTimeTo100PercentString(lightThread)
    def self.lightThreadTimeTo100PercentString(lightThread)
        return "" if ( lightThread["priorityXp"][0]=="interruption-now" or lightThread["priorityXp"][0]=="must-be-all-done-today" )
        xtime = NSXLightThreadUtils::lightThreadTimeTo100PercentInSecondsOrNull(lightThread) 
        if xtime then
            "time to 100%: #{(xtime.to_f/3600).round(2)} hours"
        else
            ""
        end 
    end

    # NSXLightThreadUtils::lightThreadToString(lightThread)
    def self.lightThreadToString(lightThread)
        timeTo100PercentString = NSXLightThreadUtils::lightThreadTimeTo100PercentString(lightThread)
        if timeTo100PercentString.size>0 then
            timeTo100PercentString = "(#{timeTo100PercentString}) "
        end
        "lightThread: #{lightThread["description"]} (#{lightThread["priorityXp"].join(", ")}) #{timeTo100PercentString}"
    end

    # -----------------------------------------------
    # UI Utils

    # NSXLightThreadUtils::interactivelySelectALightThread()
    def self.interactivelySelectALightThread()
        xlambda = lambda{|lightThread| NSXLightThreadUtils::lightThreadToString(lightThread) }
        LucilleCore::selectEntityFromListOfEntitiesOrNull("lightThread:", NSXLightThreadUtils::lightThreads(), xlambda)
    end

    # NSXLightThreadUtils::interactivelySelectALightThreadPriority()
    def self.interactivelySelectALightThreadPriority()
        xlambda = lambda{|index|
            mapping = ["Must be done", "Ideally done", "Luxury"]
            mapping[index-1]
        }
        LucilleCore::selectEntityFromListOfEntitiesOrNull("lightThread Priority:", [1,2,3], xlambda)
    end

    # NSXLightThreadUtils::lightThreadDive(lightThread)
    def self.lightThreadDive(lightThread)
        loop {
            puts "LightThread"
            puts "     description: #{lightThread["description"]}"
            puts "     uuid: #{lightThread["uuid"]}"
            puts "     priorityXp: #{lightThread["priorityXp"].join(", ")}"
            puts "     streamuuid: #{lightThread["streamuuid"]}"
            livePercentages = (1..7).to_a.reverse.map{|indx| NSXLightThreadMetrics::lightThreadToLivePercentageOverThePastNDays(lightThread, indx).round(2) }
            puts "     Live Percentages (7..1): %: #{livePercentages.join(" ")}"
            puts "     Time to 100%: #{NSXLightThreadUtils::lightThreadTimeTo100PercentString(lightThread)}"
            puts "     LightThread metric: #{NSXLightThreadMetrics::lightThread2Metric(lightThread)}"
            puts "     Stream Items Base Metric: #{NSXLightThreadMetrics::lightThread2StreamItemBaseMetric(lightThread)}"
            puts "     Object count: #{NSXLightThreadsStreamsInterface::lightThreadToItsStreamItemsOrdered(lightThread).count}"
            operations = ["show elements", "start", "stop", "show time log", "add time:", "issue new LightThreadPriorityXP:"]
            if NSXLightThreadUtils::lightThreadCanBeDestroyed(lightThread) then
                operations << "destroy"
            end
            operation = LucilleCore::selectEntityFromListOfEntitiesOrNull("operation:", operations)
            break if operation.nil?
            if operation=="show elements" then
                NSXLightThreadsStreamsInterface::lightThreadToItsStreamItemsOrdered(lightThread)
                    .each{|streamItem|
                        puts NSXStreamsUtils::streamItemToStreamCatalystObjectAnnounce(lightThread, streamItem)
                    }
                LucilleCore::pressEnterToContinue()
            end
            if operation=="start" then
                NSXLightThreadUtils::startLightThread(lightThread["uuid"])
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
            end
            if operation=="add time:" then
                timeInHours = LucilleCore::askQuestionAnswerAsString("Time in hours: ").to_f
                NSXLightThreadUtils::lightThreadAddTime(lightThread["uuid"], timeInHours)
            end
            if operation == "show items" then
                puts "To be implemented"
                LucilleCore::pressEnterToContinue()                
            end
            if operation=="issue new LightThreadPriorityXP:" then
                priorityXp = NSXLightThreadUtils::lightThreadPriorityXPPickerOrNull()
                if priorityXp.nil? then
                    puts "You have not provided a priority. Aborting."
                    LucilleCore::pressEnterToContinue()
                    next
                end
                lightThread["priorityXp"] = priorityXp
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

    # NSXLightThreadUtils::lightThreadPriorityXPPickerOrNull()
    def self.lightThreadPriorityXPPickerOrNull()
        type = LucilleCore::selectEntityFromListOfEntitiesOrNull("thread type:", ["interruption-now", "must-be-all-done-today", "stream-important", "stream-luxury"])
        return nil if type.nil?
        if (type == "interruption-now") or (type == "must-be-all-done-today") then
            return [type]
        end
        commitmentInHours = LucilleCore::askQuestionAnswerAsString("Daily commitment: ").to_f
        [type, commitmentInHours]
    end

end


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
        return 101 if NSXLightThreadUtils::trueIfLightThreadIsMustBeGone(lightThread)
        dailyCommitmentInHours = lightThread["priorityXp"][1]
        timeDoneExpectationInHours = n * dailyCommitmentInHours
        timeDoneLiveInHours = NSXLightThreadMetrics::lightThreadToLiveAndOrSimulatedDoneTimeSpanInSecondsOverThePastNDays(lightThread, n, simulationTimeInSeconds).to_f/3600
        100 * (timeDoneLiveInHours.to_f / timeDoneExpectationInHours)
    end

    # NSXLightThreadMetrics::lightThreadToMetricParameters(lightThread) # [baseMetric, expansion]
    def self.lightThreadToMetricParameters(lightThread) # [baseMetric, expansion]
        if lightThread["priorityXp"][0]=="interruption-now" then
            return [1.5, 1.5] # Irrelevant
        end
        if lightThread["priorityXp"][0]=="must-be-all-done-today" then
            return [1.5, 1.5] # Irrelevant
        end
        if lightThread["priorityXp"][0]=="stream-important" then
            return [0.4, 0.2]
        end
        if lightThread["priorityXp"][0]=="stream-luxury" then
            return [0.2, 0.2]
        end
        [0.8, 0.1]
    end

    # NSXLightThreadMetrics::lightThread2MetricOverThePastNDays(lightThread, n, simulationTimeInSeconds = 0)
    def self.lightThread2MetricOverThePastNDays(lightThread, n, simulationTimeInSeconds = 0)
        return 2 if ( simulationTimeInSeconds==0 and lightThread["status"][0] == "running-since" )
        livePercentage = NSXLightThreadMetrics::lightThreadToLivePercentageOverThePastNDays(lightThread, n, simulationTimeInSeconds)
        return 0 if livePercentage >= 100
        baseMetric, expansion = NSXLightThreadMetrics::lightThreadToMetricParameters(lightThread)
        metric = baseMetric + expansion*Math.exp(-livePercentage.to_f/100) # at 100% we are at baseMetric + expansion*Math.exp(-1)
        metric - NSXMiscUtils::traceToMetricShift(lightThread["uuid"])
    end

    # NSXLightThreadMetrics::lightThread2Metric(lightThread, simulationTimeInSeconds = 0)
    def self.lightThread2Metric(lightThread, simulationTimeInSeconds = 0)
        return 0 if lightThread["priorityXp"][0] == "interruption-now"
        return 0 if lightThread["priorityXp"][0] == "must-be-all-done-today"
        # Here we take the min of NSXLightThreadMetrics::lightThread2MetricOverThePastNDays(lightThread, n) for n=1..7
        0.9 * (1..7).map{|indx| NSXLightThreadMetrics::lightThread2MetricOverThePastNDays(lightThread, indx, simulationTimeInSeconds) }.min
    end

    # NSXLightThreadMetrics::lightThread2StreamItemBaseMetric(lightThread)
    def self.lightThread2StreamItemBaseMetric(lightThread)
        return 0.90 if lightThread["priorityXp"][0] == "interruption-now"
        return 0.60 if lightThread["priorityXp"][0] == "must-be-all-done-today"
        # Here we take the min of NSXLightThreadMetrics::lightThread2MetricOverThePastNDays(lightThread, n) for n=1..7
        (1..7).map{|indx| NSXLightThreadMetrics::lightThread2MetricOverThePastNDays(lightThread, indx) }.min
    end

end

class NSXLightThreadsStreamsInterface

    # NSXLightThreadsStreamsInterface::lightThreadToItsStreamCatalystObjects(lightThread)
    def self.lightThreadToItsStreamCatalystObjects(lightThread)
        baseMetric = NSXLightThreadMetrics::lightThread2StreamItemBaseMetric(lightThread)
        items = NSXLightThreadsStreamsInterface::lightThreadToItsStreamItemsOrdered(lightThread)
        items = NSXLightThreadsStreamsInterface::filterAwayStreamItemsThatAreDoNotShowUntilHidden(items)
        items
            .first(3)
            .map{|item| NSXStreamsUtils::streamItemToStreamCatalystObject(lightThread, item, baseMetric) }
    end

    # NSXLightThreadsStreamsInterface::lightThreadToItsStreamItemsOrdered(lightThread)
    def self.lightThreadToItsStreamItemsOrdered(lightThread)
        NSXStreamsUtils::allStreamsItemsEnumerator()
            .select{|item| item["streamuuid"]==lightThread["streamuuid"] }
            .sort{|i1, i2| i1["ordinal"]<=>i2["ordinal"] }
    end

    # NSXLightThreadsStreamsInterface::filterAwayStreamItemsThatAreDoNotShowUntilHidden(items)
    def self.filterAwayStreamItemsThatAreDoNotShowUntilHidden(items)
        items.select{|item|
            objectuuid = item["uuid"][0,8]
            NSXDoNotShowUntilDatetime::getFutureDatetimeOrNull(objectuuid).nil?
        }
    end

end
