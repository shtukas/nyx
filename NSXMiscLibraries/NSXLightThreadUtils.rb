
# encoding: UTF-8

require 'time'

LIGHT_THREAD_DONE_TIMESPAN_IN_DAYS = 7
LIGHT_THREADS_FOLDERPATH = "/Galaxy/DataBank/Catalyst/LightThreads"

class NSXLightThreadUtils

    # NSXLightThreadUtils::timeStringL22()
    def self.timeStringL22()
        "#{Time.new.strftime("%Y%m%d-%H%M%S-%6N")}"
    end

    # NSXLightThreadUtils::lightThreads(): Array[LightThread]
    def self.lightThreads()
        Dir.entries(LIGHT_THREADS_FOLDERPATH)
            .select{|filename| filename[-5, 5]==".json" }
            .sort
            .map{|filename| "#{LIGHT_THREADS_FOLDERPATH}/#{filename}" }
            .map{|filepath| JSON.parse(IO.read(filepath)) }
    end

    # NSXLightThreadUtils::commitLightThreadToDisk(lightThread)
    def self.commitLightThreadToDisk(lightThread)
        File.open("#{LIGHT_THREADS_FOLDERPATH}/#{lightThread["uuid"]}.json", "w"){|f| f.puts(JSON.pretty_generate(lightThread)) }
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
        filepath = "#{LIGHT_THREADS_FOLDERPATH}/#{lightThreadUUID}.json"
        return nil if !File.exists?(filepath)
        JSON.parse(IO.read(filepath))
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

    # NSXLightThreadUtils::sendLightThreadTimeRecordItemToDisk(lightThreadUUID, item)
    def self.sendLightThreadTimeRecordItemToDisk(lightThreadUUID, item)
        folderpath = "#{LIGHT_THREADS_FOLDERPATH}/#{lightThreadUUID}"
        if !File.exists?(folderpath) then
            FileUtils.mkpath(folderpath)
        end
        filepath = "#{folderpath}/#{NSXLightThreadUtils::timeStringL22()}.json"
        File.open(filepath, "w"){|f| f.puts(JSON.pretty_generate(item)) }
    end

    # NSXLightThreadUtils::issueLightThreadTimeRecordItem(lightThreadUUID, unixtime, timespanInSeconds)
    def self.issueLightThreadTimeRecordItem(lightThreadUUID, unixtime, timespanInSeconds)
        item = {
            "uuid"     => SecureRandom.hex,
            "unixtime" => unixtime,
            "timespan" => timespanInSeconds
        }
        NSXLightThreadUtils::sendLightThreadTimeRecordItemToDisk(lightThreadUUID, item)
    end

    # NSXLightThreadUtils::getLightThreadTimeRecordItems(lightThreadUUID)
    def self.getLightThreadTimeRecordItems(lightThreadUUID)
        folderpath = "#{LIGHT_THREADS_FOLDERPATH}/#{lightThreadUUID}"
        return [] if !File.exists?(folderpath)
        Dir.entries(folderpath)
            .select{|filename| filename[-5, 5]==".json" }
            .map{|filename| "#{folderpath}/#{filename}" }
            .map{|filepath| [filepath, JSON.parse(IO.read(filepath))] }
            .select{|pair| 
                item = pair[1] 
                (Time.new.to_i-item["unixtime"]) > 86400*LIGHT_THREAD_DONE_TIMESPAN_IN_DAYS 
            }
            .each{|pair|
                filepath = pair[0]
                FileUtils.rm(filepath)
            }
        Dir.entries(folderpath)
            .select{|filename| filename[-5, 5]==".json" }
            .map{|filename| "#{folderpath}/#{filename}" }
            .map{|filepath| JSON.parse(IO.read(filepath)) }
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

        if lightThread["status"][0] == "running-since" and NSXMiscUtils::valueOrDefaultValue(NSXLightThreadMetrics::lightThreadToLivePercentageOverThePastNDaysOrNull(lightThread, 1), 0) >= 100 then
            NSXMiscUtils::onScreenNotification("Catalyst TimeProton", "#{lightThread["description"].gsub("'","")} is done")
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

    # NSXLightThreadUtils::lightThreadToTargetFolderCatalystObjectOrNull(lightThread)
    def self.lightThreadToTargetFolderCatalystObjectOrNull(lightThread)
        targetFolderpath = lightThread["targetFolderpath"]
        return nil if targetFolderpath == "/Galaxy/On-Going/DevNull"
        uuid = Digest::SHA1.hexdigest("cc430ddf-c5dd-434d-b3b7-c2dca7477fcf:#{lightThread["uuid"]}")
        return nil if KeyValueStore::getOrNull("/Galaxy/DataBank/Catalyst/LightThreads-KVStoreDataFolder", "6de5e81-dc334ac:#{uuid}")==NSXMiscUtils::currentDay()
        object              = {}
        object["uuid"]      = uuid
        object["agent-uid"] = "201cac75-9ecc-4cac-8ca1-2643e962a6c6"
        object["metric"]    = NSXLightThreadMetrics::lightThread2TargetFolderpathObjectMetric(lightThread)
        object["announce"]  = "LightThread: #{lightThread["description"]}; target folder: #{lightThread["targetFolderpath"]}"
        object["commands"]  = ["done"]
        object["default-expression"] = "start-the-thread-itself-and-open-the-folder"
        object["data"] = {}
        object["data"]["lightThread"] = lightThread
        object["commands-lambdas"] = {}
        object["commands-lambdas"]["done"] = 
            lambda{|object|
                KeyValueStore::set("/Galaxy/DataBank/Catalyst/LightThreads-KVStoreDataFolder", "6de5e81-dc334ac:#{object["uuid"]}", NSXMiscUtils::currentDay())
            }
        object["commands-lambdas"]["start-the-thread-itself-and-open-the-folder"] = 
            lambda{|object|
                targetFolderpath = object["data"]["lightThread"]["targetFolderpath"]
                lightThreadUUID = object["data"]["lightThread"]["uuid"]
                NSXLightThreadUtils::startLightThread(lightThreadUUID)
                NSXMiscUtils::setStandardListingPosition(1)
                system("open '#{targetFolderpath}'")
            }
        object
    end

    # NSXLightThreadUtils::lightThreadCanBeDestroyed(lightThread)
    def self.lightThreadCanBeDestroyed(lightThread)
        return false if NSXLightThreadsStreamsInterface::lightThreadToItsStreamItemsOrdered(lightThread).count > 0
        return false if NSXStreamsUtils::oldStreamNamesToNewStreamUUIDMapping().values.include?(lightThread["streamuuid"])
        true
    end

    # NSXLightThreadUtils::destroyLightThread(lightThreadUUID)
    def self.destroyLightThread(lightThreadUUID)
        filepath = "#{LIGHT_THREADS_FOLDERPATH}/#{lightThreadUUID}.json"
        return if !File.exists?(filepath)
        FileUtils.rm(filepath)
    end

    # -----------------------------------------------
    # .toString

    # NSXLightThreadUtils::lightThreadTimeTo100PercentString(lightThread)
    def self.lightThreadTimeTo100PercentString(lightThread)
        return "" if ( lightThread["priorityXp"][0]=="interruption-now" or lightThread["priorityXp"][0]=="must-be-all-done-today" )
        xtime = NSXLightThreadUtils::lightThreadTimeTo100PercentInSecondsOrNull(lightThread) 
        if xtime then
            "time to 100%: #{(xtime.to_f/3600).round(3)} hours"
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
        "LightThread: #{lightThread["description"]} (#{lightThread["priorityXp"].join(", ")}) #{timeTo100PercentString}"
    end

    # -----------------------------------------------
    # UI Utils

    # NSXLightThreadUtils::interactivelySelectOneLightThread()
    def self.interactivelySelectOneLightThread()
        xlambda = lambda{|lightThread| NSXLightThreadUtils::lightThreadToString(lightThread) }
        LucilleCore::selectEntityFromListOfEntitiesOrNull("lightThread:", NSXLightThreadUtils::lightThreads(), xlambda)
    end

    # NSXLightThreadUtils::interactivelySelectOneLightThreadPriority()
    def self.interactivelySelectOneLightThreadPriority()
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
            livePercentages = (1..7).to_a.reverse.map{|indx| NSXMiscUtils::valueOrDefaultValue(NSXLightThreadMetrics::lightThreadToLivePercentageOverThePastNDaysOrNull(lightThread, indx), 0).round(2) }
            puts "     Live Percentages (7..1): %: #{livePercentages.join(" ")}"
            puts "     Time to 100%: #{NSXLightThreadUtils::lightThreadTimeTo100PercentString(lightThread)}"
            puts "     LightThread metric: #{NSXLightThreadMetrics::lightThread2Metric(lightThread)}"
            puts "     Stream Items Base Metric: #{NSXLightThreadMetrics::lightThread2GenericStreamItemMetric(lightThread)}"
            puts "     Object count: #{NSXLightThreadsStreamsInterface::lightThreadToItsStreamItemsOrdered(lightThread).count}"
            operations = ["start", "stop", "add time:", "show timelog", "show elements", "update description:", "update LightThreadPriorityXP:"]
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
            if operation=="show timelog" then
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
            if operation=="update description:" then
                description = LucilleCore::askQuestionAnswerAsString("description: ")
                lightThread["description"] = description
                NSXLightThreadUtils::commitLightThreadToDisk(lightThread)
            end
            if operation=="update LightThreadPriorityXP:" then
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
                    NSXLightThreadUtils::destroyLightThread(lightThread["uuid"])
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

    # NSXLightThreadMetrics::lightThreadToLivePercentageOverThePastNDaysOrNull(lightThread, n, simulationTimeInSeconds = 0)
    def self.lightThreadToLivePercentageOverThePastNDaysOrNull(lightThread, n, simulationTimeInSeconds = 0)
        return nil if NSXLightThreadUtils::trueIfLightThreadIsMustBeGone(lightThread)
        items = NSXLightThreadUtils::getLightThreadTimeRecordItems(lightThread["uuid"])
        return 0 if ( (simulationTimeInSeconds==0) and (items.size==0) and (lightThread["status"][0]=="paused") )
        dailyCommitmentInHours = lightThread["priorityXp"][1]
        timeDoneExpectationInHours = n * dailyCommitmentInHours
        timeDoneLiveInHours = NSXLightThreadMetrics::lightThreadToLiveAndOrSimulatedDoneTimeSpanInSecondsOverThePastNDays(lightThread, n, simulationTimeInSeconds).to_f/3600
        100 * (timeDoneLiveInHours.to_f / timeDoneExpectationInHours)
    end

    # NSXLightThreadMetrics::lightThreadToMetricParameters(lightThread) # [streamItemMetric, expansion]
    def self.lightThreadToMetricParameters(lightThread) # [streamItemMetric, expansion]
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

    # NSXLightThreadMetrics::lightThread2MetricOverThePastNDaysOrNull(lightThread, n, simulationTimeInSeconds = 0)
    def self.lightThread2MetricOverThePastNDaysOrNull(lightThread, n, simulationTimeInSeconds = 0)
        return 2 if ( simulationTimeInSeconds==0 and lightThread["status"][0] == "running-since" )
        livePercentage = NSXLightThreadMetrics::lightThreadToLivePercentageOverThePastNDaysOrNull(lightThread, n, simulationTimeInSeconds)
        return nil if livePercentage.nil?
        return 0 if livePercentage >= 100
        streamItemMetric, expansion = NSXLightThreadMetrics::lightThreadToMetricParameters(lightThread)
        metric = streamItemMetric + expansion*Math.exp(-livePercentage.to_f/100) # at 100% we are at streamItemMetric + expansion*Math.exp(-1)
        metric - NSXMiscUtils::traceToMetricShift(lightThread["uuid"])
    end

    # NSXLightThreadMetrics::lightThread2Metric(lightThread, simulationTimeInSeconds = 0)
    def self.lightThread2Metric(lightThread, simulationTimeInSeconds = 0)
        return 2 if (lightThread["status"][0] == "running-since" and simulationTimeInSeconds==0)
        return 0 if lightThread["priorityXp"][0] == "interruption-now"
        return 0 if lightThread["priorityXp"][0] == "must-be-all-done-today"
        (1..7).map{|indx| NSXMiscUtils::valueOrDefaultValue(NSXLightThreadMetrics::lightThread2MetricOverThePastNDaysOrNull(lightThread, indx, simulationTimeInSeconds), 0) }.min
    end

    # NSXLightThreadMetrics::lightThread2GenericStreamItemMetric(lightThread)
    def self.lightThread2GenericStreamItemMetric(lightThread)
        return 0.90 if lightThread["priorityXp"][0] == "interruption-now"
        return 0.60 if lightThread["priorityXp"][0] == "must-be-all-done-today"
        ( NSXLightThreadUtils::trueIfLightThreadIsRunning(lightThread) ? 0.90 : 1.05 ) * NSXLightThreadMetrics::lightThread2Metric(lightThread)
    end

    # NSXLightThreadMetrics::lightThread2TargetFolderpathObjectMetric(lightThread)
    def self.lightThread2TargetFolderpathObjectMetric(lightThread)
        1.01 * NSXLightThreadMetrics::lightThread2GenericStreamItemMetric(lightThread)
    end

end

class NSXLightThreadsStreamsInterface

    # NSXLightThreadsStreamsInterface::lightThreadToItsStreamCatalystObjects(lightThread)
    def self.lightThreadToItsStreamCatalystObjects(lightThread)
        streamItemMetric = NSXLightThreadMetrics::lightThread2GenericStreamItemMetric(lightThread)
        items = NSXLightThreadsStreamsInterface::lightThreadToItsStreamItemsOrdered(lightThread)
        items = NSXLightThreadsStreamsInterface::filterAwayStreamItemsThatAreDoNotShowUntilHidden(items)
        items
            .first(1)
            .map{|item| NSXStreamsUtils::streamItemToStreamCatalystObject(lightThread, item, streamItemMetric) }
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

# -----------------------------------------------------------------------
# Cache System
# Speeding up NSXLightThreadsStreamsInterface::lightThreadToItsStreamItemsOrdered
# -----------------------------------------------------------------------

$lightThreadToItsStreamItemsOrderedCache = {} # marker: 73ca550c-9508
$lightThreadToItsStreamItemsOrderedCacheLightThreadUUIDToCacheKeyMap = {} # marker: 73ca550c-9508

def nsxLightThreadsStreamsItemsOrdered_getCacheKey(lightThreadUUID) # marker: 73ca550c-9508
    if $lightThreadToItsStreamItemsOrderedCacheLightThreadUUIDToCacheKeyMap[lightThreadUUID].nil? then
        $lightThreadToItsStreamItemsOrderedCacheLightThreadUUIDToCacheKeyMap[lightThreadUUID] = SecureRandom.hex
    end
    $lightThreadToItsStreamItemsOrderedCacheLightThreadUUIDToCacheKeyMap[lightThreadUUID]
end

def nsxLightThreadsStreamsItemsOrdered_resetCacheKey(lightThreadUUID) # marker: 73ca550c-9508
    $lightThreadToItsStreamItemsOrderedCacheLightThreadUUIDToCacheKeyMap.delete(lightThreadUUID)
end

class NSXLightThreadsStreamsInterface

    # NSXLightThreadsStreamsInterface::lightThreadToItsStreamItemsOrdered(lightThread)
    def self.lightThreadToItsStreamItemsOrdered(lightThread) # marker: 73ca550c-9508
        cacheKey = nsxLightThreadsStreamsItemsOrdered_getCacheKey(lightThread["uuid"]) 
        if $lightThreadToItsStreamItemsOrderedCache[cacheKey] then
            return $lightThreadToItsStreamItemsOrderedCache[cacheKey]
        end
        items = NSXStreamsUtils::allStreamsItemsEnumerator()
            .select{|item| item["streamuuid"]==lightThread["streamuuid"] }
            .sort{|i1, i2| i1["ordinal"]<=>i2["ordinal"] }
        $lightThreadToItsStreamItemsOrderedCache[cacheKey] = items
        items
    end

end

# -----------------------------------------------------------------------
# Cache System
# Speeding up NSXLightThreadUtils::lightThreadTimeTo100PercentInSecondsOrNull
# -----------------------------------------------------------------------

$lightThreadTimeTo100PercentInSecondsPrecomputedValues = {}

Thread.new {
    sleep 10
    loop {
        NSXLightThreadUtils::lightThreads()
        .each{|lightThread|
            $lightThreadTimeTo100PercentInSecondsPrecomputedValues[lightThread["uuid"]] = NSXLightThreadUtils::lightThreadTimeTo100PercentInSecondsOrNullOrigins(lightThread)
        }
        sleep (1+rand)*60
    }
}

class NSXLightThreadUtils
    # NSXLightThreadUtils::lightThreadTimeTo100PercentInSecondsOrNullOrigins(lightThread)
    def self.lightThreadTimeTo100PercentInSecondsOrNullOrigins(lightThread)
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

    # NSXLightThreadUtils::lightThreadTimeTo100PercentInSecondsOrNull(lightThread)
    def self.lightThreadTimeTo100PercentInSecondsOrNull(lightThread)
        if NSXLightThreadUtils::trueIfLightThreadIsRunning(lightThread) then
            return NSXLightThreadUtils::lightThreadTimeTo100PercentInSecondsOrNullOrigins(lightThread)
        end
        $lightThreadTimeTo100PercentInSecondsPrecomputedValues[lightThread["uuid"]]
    end
end




