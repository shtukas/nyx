
# encoding: UTF-8

require 'time'

LIGHT_THREAD_DONE_TIMESPAN_IN_DAYS = 7
LIGHT_THREADS_FOLDERPATH = "#{CATALYST_COMMON_DATABANK_CATALYST_FOLDERPATH}/LightThreads"

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

    # NSXLightThreadUtils::trueIfLightThreadIsInterruption(lightThread)
    def self.trueIfLightThreadIsInterruption(lightThread)
        return true if lightThread["priorityXp"][0]=="interruption-now"
        false
    end

    # NSXLightThreadUtils::trueIfLightThreadIsTypeMustBeGone(lightThread)
    def self.trueIfLightThreadIsTypeMustBeGone(lightThread)
        return true if lightThread["priorityXp"][0]=="interruption-now"
        return true if lightThread["priorityXp"][0]=="must-be-all-done-today"
        false
    end

    # NSXLightThreadUtils::trueIfLightThreadIsRunning(lightThread)
    def self.trueIfLightThreadIsRunning(lightThread)
        NSXRunner::isRunning?(lightThread["uuid"])
    end

    # NSXLightThreadUtils::stopLightThread(lightThreadUUID)
    def self.stopLightThread(lightThreadUUID)
        timespanInSeconds = NSXRunner::stop(lightThreadUUID)
        return if timespanInSeconds.nil?
        NSXLightThreadUtils::issueLightThreadTimeRecordItem(lightThreadUUID, Time.new.to_i, timespanInSeconds)
    end

    # NSXLightThreadUtils::lightThreadAddTime(lightThreadUUID, timeInHours)
    def self.lightThreadAddTime(lightThreadUUID, timeInHours)
        lightThread = NSXLightThreadUtils::getLightThreadByUUIDOrNull(lightThreadUUID)
        return if lightThread.nil?
        NSXLightThreadUtils::issueLightThreadTimeRecordItem(lightThread["uuid"], Time.new.to_i, timeInHours * 3600)
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

    # NSXLightThreadUtils::lightThreadToCatalystObject(lightThread)
    def self.lightThreadToCatalystObject(lightThread)
        # There is a check we need to do here: whether or not the lightThread should be taken out of sleeping

        if NSXLightThreadUtils::trueIfLightThreadIsRunning(lightThread) and NSXMiscUtils::nonNullValueOrDefaultValue(NSXLightThreadMetrics::lightThreadToLivePercentageOverThePastNDaysOrNull(lightThread, 1), 0) >= 100 then
            NSXMiscUtils::onScreenNotification("Catalyst TimeProton", "#{lightThread["description"].gsub("'","")} is done")
        end

        uuid = lightThread["uuid"]
        description = lightThread["description"]
        object              = {}
        object["uuid"]      = uuid # the catalyst object has the same uuid as the lightThread
        object["agent-uid"] = "201cac75-9ecc-4cac-8ca1-2643e962a6c6"
        object["metric"]    = NSXLightThreadMetrics::lightThread2Metric(lightThread)
        object["announce"]  = NSXLightThreadUtils::lightThreadToString(lightThread) + ( lightThread["targetFolderpath"]!="/Galaxy/LightThreads/DevNull" ? " (#{lightThread["targetFolderpath"]})" : "" )
        object["commands"]  = NSXLightThreadUtils::trueIfLightThreadIsRunning(lightThread) ? ["stop"] : ["start", "time: <timeInHours>", "dive"]
        object["default-expression"] = NSXLightThreadUtils::trueIfLightThreadIsRunning(lightThread) ? "stop" : "start"
        object["is-running"] = NSXLightThreadUtils::trueIfLightThreadIsRunning(lightThread)
        object["item-data"] = {}
        object["item-data"]["lightThread"] = lightThread
        object 
    end

    # NSXLightThreadUtils::lightThreadCanBeDestroyed(lightThread)
    def self.lightThreadCanBeDestroyed(lightThread)
        return false if ["29be9b439c40a9e8fcd34b7818ba4153", "03b79978bcf7a712953c5543a9df9047", "354d0160d6151cb10015e6325ca5f26a"].include?(lightThread["streamuuid"])
        return false if NSXLightThreadsStreamsInterface::lightThreadToItsStreamItemsOrdered(lightThread).count > 0
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

    # NSXLightThreadUtils::lightThreadToString(lightThread)
    def self.lightThreadToString(lightThread)
        "LightThread: #{lightThread["description"]}"
    end

    # -----------------------------------------------
    # UI Utils

    # NSXLightThreadUtils::interactivelySelectLightThreadOrNull()
    def self.interactivelySelectLightThreadOrNull()
        LucilleCore::selectEntityFromListOfEntitiesOrNull("lightThread:", NSXLightThreadUtils::lightThreads().sort{|lt1, lt2| lt1["description"].downcase<=>lt2["description"].downcase }, lambda{|lightThread| NSXLightThreadUtils::lightThreadToString(lightThread) })
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
        lightThreadCatalystObjectUUID = lightThread["uuid"]
        loop {
            doNotShowUntilDateTime = NSXDoNotShowUntilDatetime::getFutureDatetimeOrNull(lightThreadCatalystObjectUUID)
            livePercentages = (1..7).to_a.reverse.map{|indx| NSXMiscUtils::nonNullValueOrDefaultValue(NSXLightThreadMetrics::lightThreadToLivePercentageOverThePastNDaysOrNull(lightThread, indx), 0).round(2) }
            puts "LightThread"
            puts "     description: #{lightThread["description"]}"
            puts "     uuid: #{lightThread["uuid"]}"
            puts "     priorityXp: #{lightThread["priorityXp"].join(", ")}"
            puts "     streamuuid: #{lightThread["streamuuid"]}"
            puts "     Live Percentages (7..1): %: #{livePercentages.join(" ")}"
            puts "     LightThread metric: #{NSXLightThreadMetrics::lightThread2Metric(lightThread)}"
            puts "     Stream Items Base Metric: #{NSXLightThreadMetrics::lightThread2GenericStreamItemMetric(lightThread)}"
            puts "     Object count: #{NSXLightThreadsStreamsInterface::lightThreadToItsStreamItemsOrdered(lightThread).count}"
            if doNotShowUntilDateTime then
                puts "     Do not display until: #{doNotShowUntilDateTime}"
            end
            operations = [
                "start", 
                "stop", 
                "add time:", 
                "show timelog", 
                "update description:", 
                "update LightThreadPriorityXP:",
                "stream items dive"
            ]
            if NSXLightThreadUtils::lightThreadCanBeDestroyed(lightThread) then
                operations << "destroy"
            end
            operation = LucilleCore::selectEntityFromListOfEntitiesOrNull("operation:", operations)
            break if operation.nil?
            if operation == "stream items dive" then
                items = NSXLightThreadsStreamsInterface::lightThreadToItsStreamItemsOrdered(lightThread)
                next if items.size == 0
                if items.first["ordinal"] > 10 then
                    items.each{|item| 
                        item["ordinal"] = item["ordinal"] - 10
                        NSXStreamsUtils::sendItemToDisk(item)
                    }
                end
                loop {
                    objects = NSXLightThreadsStreamsInterface::lightThreadToItsStreamItemsOrdered(lightThread)
                                .map{|streamItem| NSXStreamsUtils::streamItemToStreamCatalystObject(lightThread, streamItem, 1) }
                    object = LucilleCore::selectEntityFromListOfEntitiesOrNull("object:", objects, lambda{|object| object["announce"] })
                    break if object.nil?
                    NSXDisplayUtils::doPresentObjectInviteAndExecuteCommand(object)
                }
            end
            if operation=="start" then
                NSXRunner::start(lightThread["uuid"])
            end
            if operation=="show timelog" then
                NSXLightThreadUtils::getLightThreadTimeRecordItems(lightThread["uuid"])
                    .sort{|i1, i2| i1["unixtime"]<=>i2["unixtime"] }
                    .each{|item|
                        puts "    - #{Time.at(item["unixtime"]).to_s} : #{ item["timespan"].round(2) } seconds, #{ (item["timespan"].to_f/3600).round(2) } hours"
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
        NSXLightThreadMetrics::lightThreadToRealisedTimeSpanInSecondsOverThePastNDays(lightThread["uuid"], n) +
            NSXMiscUtils::nonNullValueOrDefaultValue(NSXRunner::runningTimeOrNull(lightThread["uuid"]), 0) +
            simulationTimeInSeconds
    end

    # NSXLightThreadMetrics::lightThreadToLivePercentageOverThePastNDaysOrNull(lightThread, n, simulationTimeInSeconds = 0)
    def self.lightThreadToLivePercentageOverThePastNDaysOrNull(lightThread, n, simulationTimeInSeconds = 0)
        return nil if NSXLightThreadUtils::trueIfLightThreadIsTypeMustBeGone(lightThread)
        items = NSXLightThreadUtils::getLightThreadTimeRecordItems(lightThread["uuid"])
        dailyCommitmentInHours = lightThread["priorityXp"][1]
        timeDoneExpectationInHours = n * dailyCommitmentInHours
        timeDoneLiveInHours = NSXLightThreadMetrics::lightThreadToLiveAndOrSimulatedDoneTimeSpanInSecondsOverThePastNDays(lightThread, n, simulationTimeInSeconds).to_f/3600
        100 * (timeDoneLiveInHours.to_f / timeDoneExpectationInHours)
    end

    # NSXLightThreadMetrics::lightThreadToMetricParameters(lightThread) # [streamItemMetric, expansion]
    def self.lightThreadToMetricParameters(lightThread) # [streamItemMetric, expansion]
        return nil if lightThread["priorityXp"][0]=="interruption-now"
        return nil if lightThread["priorityXp"][0]=="must-be-all-done-today"
        return [0.19, 0.4] if lightThread["priorityXp"][0]=="stream-important"
        return [0.19, 0.2] if lightThread["priorityXp"][0]=="stream-luxury"
        raise "Error: 0a86f002"
    end

    # NSXLightThreadMetrics::lightThread2MetricOverThePastNDaysOrNull(lightThread, n, simulationTimeInSeconds = 0)
    def self.lightThread2MetricOverThePastNDaysOrNull(lightThread, n, simulationTimeInSeconds = 0)
        return 2 if ( simulationTimeInSeconds==0 and NSXLightThreadUtils::trueIfLightThreadIsRunning(lightThread) )
        metricParameters = NSXLightThreadMetrics::lightThreadToMetricParameters(lightThread)
        return nil if metricParameters.nil?
        baseMetric, expansion = metricParameters
        livePercentage = NSXLightThreadMetrics::lightThreadToLivePercentageOverThePastNDaysOrNull(lightThread, n, simulationTimeInSeconds)
        return nil if livePercentage.nil?
        baseMetric + expansion*Math.exp(-livePercentage.to_f/100) + NSXMiscUtils::traceToMetricShift(lightThread["uuid"])
    end

    # NSXLightThreadMetrics::lightThread2Metric(lightThread, simulationTimeInSeconds = 0)
    def self.lightThread2Metric(lightThread, simulationTimeInSeconds = 0)
        return 2 if (NSXLightThreadUtils::trueIfLightThreadIsRunning(lightThread) and simulationTimeInSeconds==0)
        return 0 if lightThread["priorityXp"][0] == "interruption-now"
        return 0 if lightThread["priorityXp"][0] == "must-be-all-done-today"
        (1..7).map{|indx| NSXMiscUtils::nonNullValueOrDefaultValue(NSXLightThreadMetrics::lightThread2MetricOverThePastNDaysOrNull(lightThread, indx, simulationTimeInSeconds), 0) }.min
    end

    # NSXLightThreadMetrics::lightThread2GenericStreamItemMetric(lightThread)
    def self.lightThread2GenericStreamItemMetric(lightThread)
        ( NSXLightThreadUtils::trueIfLightThreadIsRunning(lightThread) ? -0.02 : 0.02 ) + NSXLightThreadMetrics::lightThread2Metric(lightThread)
    end

    # NSXLightThreadMetrics::lightThread2TargetFolderpathObjectMetric(lightThread)
    def self.lightThread2TargetFolderpathObjectMetric(lightThread)
        ( NSXLightThreadUtils::trueIfLightThreadIsRunning(lightThread) ? -0.001 : 0.001 ) + NSXLightThreadMetrics::lightThread2Metric(lightThread)
    end

    # NSXLightThreadMetrics::timespanInSecondsTo100PercentRelativelyToNDaysOrNull(lightThread, n)
    def self.timespanInSecondsTo100PercentRelativelyToNDaysOrNull(lightThread, n)
        return nil if NSXLightThreadMetrics::lightThreadToLivePercentageOverThePastNDaysOrNull(lightThread, n, 0).nil?
        timespan = 0
        while NSXLightThreadMetrics::lightThreadToLivePercentageOverThePastNDaysOrNull(lightThread, n, timespan) < 100 do
            timespan = timespan + 600
        end
        timespan
    end

    # NSXLightThreadMetrics::timeInSecondsTo100PercentOrNull(lightThread)
    def self.timeInSecondsTo100PercentOrNull(lightThread)
        numbers = (1..7).map{|n| NSXLightThreadMetrics::timespanInSecondsTo100PercentRelativelyToNDaysOrNull(lightThread, n) }.compact
        return nil if numbers.size==0
        numbers.min
    end

end

class NSXLightThreadsStreamsInterface

    # NSXLightThreadsStreamsInterface::lightThreadToItsStreamCatalystObjectsCountOrNull(lightThread)
    def self.lightThreadToItsStreamCatalystObjectsCountOrNull(lightThread)
        return nil if lightThread["priorityXp"][0] == "interruption-now"
        return nil if lightThread["priorityXp"][0] == "must-be-all-done-today"
        1
    end

    # NSXLightThreadsStreamsInterface::lightThreadToItsStreamCatalystObjects(lightThread)
    def self.lightThreadToItsStreamCatalystObjects(lightThread)
        streamItemMetric = NSXLightThreadMetrics::lightThread2GenericStreamItemMetric(lightThread)
        items = NSXLightThreadsStreamsInterface::lightThreadToItsStreamItemsOrdered(lightThread)
        items = NSXLightThreadsStreamsInterface::filterAwayStreamItemsThatAreDoNotShowUntilHidden(items)
        items1 = items.first(NSXLightThreadsStreamsInterface::lightThreadToItsStreamCatalystObjectsCountOrNull(lightThread) || 6)
        items2 = items.select{|item| NSXRunner::isRunning?(item["uuid"]) }
        (items1+items2).map{|item| NSXStreamsUtils::streamItemToStreamCatalystObject(lightThread, item, streamItemMetric) }
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




