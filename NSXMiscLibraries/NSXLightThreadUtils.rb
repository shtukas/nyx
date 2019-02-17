# encoding: UTF-8

require 'time'

require "/Galaxy/Software/Misc-Common/Ruby-Libraries/KeyValueStore.rb"
=begin
    KeyValueStore::set(repositorylocation or nil, key, value)
    KeyValueStore::getOrNull(repositorylocation or nil, key)
    KeyValueStore::getOrDefaultValue(repositorylocation or nil, key, defaultValue)
    KeyValueStore::destroy(repositorylocation or nil, key)
=end

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

    # NSXLightThreadUtils::makeNewLightThread(description, dailyTimeCommitment, isPriorityThread)
    def self.makeNewLightThread(description, dailyTimeCommitment, isPriorityThread)
        uuid = SecureRandom.hex(4)
        lightThread = {}
        lightThread["uuid"] = uuid
        lightThread["unixtime"] = Time.new.to_i
        lightThread["description"] = description
        lightThread["dailyTimeCommitment"] = dailyTimeCommitment
        lightThread["isPriorityThread"] = isPriorityThread
        lightThread["streamuuid"] = SecureRandom.hex
        lightThread["folderpaths"] = []
        NSXLightThreadUtils::commitLightThreadToDisk(lightThread)
        NSXLightThreadUtils::addTimeToLightThread(uuid, 0)
        lightThread
    end

    # NSXLightThreadUtils::getLightThreadByUUIDOrNull(lightThreadUUID)
    def self.getLightThreadByUUIDOrNull(lightThreadUUID)
        filepath = "#{LIGHT_THREADS_FOLDERPATH}/#{lightThreadUUID}.json"
        return nil if !File.exists?(filepath)
        JSON.parse(IO.read(filepath))
    end

    # NSXLightThreadUtils::trueIfLightThreadIsRunning(lightThread)
    def self.trueIfLightThreadIsRunning(lightThread)
        NSXRunner::isRunning?(lightThread["uuid"])
    end

    # NSXLightThreadUtils::lightThreadCanBeDestroyed(lightThread)
    def self.lightThreadCanBeDestroyed(lightThread)
        return false if lightThread["streamuuid"] == "03b79978bcf7a712953c5543a9df9047"
        return false if NSXLightThreadsStreamsInterface::lightThreadToItsStreamItemsOrdered(lightThread).count > 0
        true
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

    # NSXLightThreadUtils::trueIfLightThreadIsRunningOrActive(lightThread)
    def self.trueIfLightThreadIsRunningOrActive(lightThread)
        # This function is to help the folder and stream items to decide whether to display or not
        # The follow the availability of the main LightThread
        # There are teo reasons why a LightThread would not be available
        # 1. It is DoNotShownUntilDatetime'd
        # 2. It is not it's day
        return true if NSXLightThreadUtils::trueIfLightThreadIsRunning(lightThread)
        return false if !NSXDoNotShowUntilDatetime::getFutureDatetimeOrNull(lightThread["uuid"]).nil? # The catalyst object has the same uuid as the LightThread
        return false if ( lightThread["activationWeekDays"] and !lightThread["activationWeekDays"].include?(NSXMiscUtils::currentWeekDay()) )
        true
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

    # NSXLightThreadUtils::addTimeToLightThread(lightThreadUUID, timeInSeconds)
    def self.addTimeToLightThread(lightThreadUUID, timeInSeconds)
        lightThread = NSXLightThreadUtils::getLightThreadByUUIDOrNull(lightThreadUUID)
        return if lightThread.nil?
        NSXLightThreadUtils::issueLightThreadTimeRecordItem(lightThread["uuid"], Time.new.to_i, timeInSeconds)
    end

    # -----------------------------------------------
    # .toString

    # NSXLightThreadUtils::lightThreadToString(lightThread)
    def self.lightThreadToString(lightThread)
        "LightThread: #{lightThread["description"]}"
    end

    # NSXLightThreadUtils::lightThreadToStringForCatlystObject(lightThread)
    def self.lightThreadToStringForCatlystObject(lightThread)
        "LightThread: #{lightThread["description"]} (#{NSXLightThreadMetrics::lightThreadBestPercentageOrNull(lightThread).round(2)} %)"
    end

    # -----------------------------------------------
    # Agent and Dive Support

    # NSXLightThreadUtils::stopLightThread(lightThreadUUID)
    def self.stopLightThread(lightThreadUUID)
        timespanInSeconds = NSXRunner::stop(lightThreadUUID)
        return if timespanInSeconds.nil?
        NSXLightThreadUtils::addTimeToLightThread(lightThreadUUID, timespanInSeconds)
    end

    # NSXLightThreadUtils::destroyLightThread(lightThreadUUID)
    def self.destroyLightThread(lightThreadUUID)
        filepath = "#{LIGHT_THREADS_FOLDERPATH}/#{lightThreadUUID}.json"
        return if !File.exists?(filepath)
        FileUtils.rm(filepath)
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
        object["uuid"]      = uuid # The catalyst object has the same uuid as the LightThread
        object["agentuid"]  = "201cac75-9ecc-4cac-8ca1-2643e962a6c6"
        object["metric"]    = NSXLightThreadMetrics::lightThread2Metric(lightThread)
        object["announce"]  = NSXLightThreadUtils::lightThreadToStringForCatlystObject(lightThread)
        object["commands"]  = NSXLightThreadUtils::trueIfLightThreadIsRunning(lightThread) ? ["stop", "dive"] : ["start", "time: <timeInHours>", "dive"]
        object["defaultExpression"] = NSXLightThreadUtils::trueIfLightThreadIsRunning(lightThread) ? "stop" : "start"
        object["isRunning"] = NSXLightThreadUtils::trueIfLightThreadIsRunning(lightThread)
        object["item-data"] = {}
        object["item-data"]["lightThread"] = lightThread
        object["item-data"]["percentage"] = NSXLightThreadMetrics::lightThreadBestPercentageOrNull(lightThread)
        object 
    end

    # -----------------------------------------------
    # UI Utils

    # NSXLightThreadUtils::interactivelySelectLightThreadOrNull()
    def self.interactivelySelectLightThreadOrNull()
        lightThreads = NSXLightThreadUtils::lightThreads()
                        .sort{|lt1, lt2| NSXLightThreadMetrics::lightThread2Metric(lt1)<=>NSXLightThreadMetrics::lightThread2Metric(lt2) }
                        .reverse
        xlambda = lambda{|lightThread| NSXLightThreadUtils::lightThreadToString(lightThread) }
        LucilleCore::selectEntityFromListOfEntitiesOrNull("lightThread:", lightThreads, xlambda)
    end

    # NSXLightThreadUtils::interactivelySelectZeroOrMoreNonAutomaticLightThreads()
    def self.interactivelySelectZeroOrMoreNonAutomaticLightThreads()
        lightThreads = NSXLightThreadUtils::lightThreads()
        xlambda = lambda{|lightThread| NSXLightThreadUtils::lightThreadToString(lightThread) }
        lightThreads, _ = LucilleCore::selectZeroOrMore("lightThread:", [], lightThreads, xlambda)
        lightThreads
    end

    # NSXLightThreadUtils::interactivelySelectOneOrMoreNonAutomaticLightThreads()
    def self.interactivelySelectOneOrMoreNonAutomaticLightThreads()
        lightThreads = NSXLightThreadUtils::interactivelySelectZeroOrMoreNonAutomaticLightThreads()
        return lightThreads if lightThreads.size>0
        NSXLightThreadUtils::interactivelySelectOneOrMoreNonAutomaticLightThreads()
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
            lightThread = NSXLightThreadUtils::getLightThreadByUUIDOrNull(lightThread["uuid"])
            lightThreadCatalystObjectUUID = lightThread["uuid"]
            livePercentages = (1..7).to_a.reverse.map{|indx| NSXMiscUtils::nonNullValueOrDefaultValue(NSXLightThreadMetrics::lightThreadToLivePercentageOverThePastNDaysOrNull(lightThread, indx), 0).round(2) }
            puts "LightThread"
            puts "     Description: #{lightThread["description"]}"
            puts "     uuid: #{lightThread["uuid"]}"
            puts "     Daily time commitment: #{lightThread["dailyTimeCommitment"]}"
            puts "     streamuuid: #{lightThread["streamuuid"]}"
            puts "     Target folderpaths: #{lightThread["folderpaths"].join(", ")}"
            puts "     Live Percentages (7..1): %: #{livePercentages.join(" ")}"
            puts "     Live running time: #{NSXRunner::runningTimeOrNull(lightThread["uuid"])}"
            puts "     LightThread metric: #{NSXLightThreadMetrics::lightThread2Metric(lightThread)}"
            puts "     Time to 100%: #{(NSXLightThreadMetrics::timeInSecondsTo100PercentOrNull(lightThread).to_f/3600).round(2)} hours"
            puts "     Activation week days: " + (lightThread["activationWeekDays"] ? lightThread["activationWeekDays"].join(", ") : "")
            puts "     Do not display until: #{NSXDoNotShowUntilDatetime::getFutureDatetimeOrNull(lightThreadCatalystObjectUUID)}"
            puts "     LightThread is active: #{NSXLightThreadUtils::trueIfLightThreadIsRunningOrActive(lightThread)}"
            puts "     Folder Base Metric: #{NSXLightThreadMetrics::lightThread2TargetFolderpathObjectMetric(lightThread)}"
            puts "     Stream Items Base Metric: #{NSXLightThreadMetrics::lightThread2BaseStreamItemMetric(lightThread)}"
            puts "     Object count: #{NSXLightThreadsStreamsInterface::lightThreadToItsStreamItemsOrdered(lightThread).count}"
            operations = [
                "start", 
                "stop", 
                "add time:", 
                "show timelog", 
                "update description:", 
                "update daily time commitment:",
                "set folderpaths",
                "set activationWeekDays",
                "stream items dive"
            ]
            if NSXLightThreadUtils::lightThreadCanBeDestroyed(lightThread) then
                operations << "destroy"
            end
            operation = LucilleCore::selectEntityFromListOfEntitiesOrNull("operation", operations)
            break if operation.nil?
            if operation=="start" then
                NSXRunner::start(lightThread["uuid"])
            end
            if operation=="show timelog" then
                NSXLightThreadUtils::getLightThreadTimeRecordItems(lightThread["uuid"])
                    .sort{|i1, i2| i1["unixtime"]<=>i2["unixtime"] }
                    .each{|item|
                        puts "    - #{Time.at(item["unixtime"]).to_s} : #{ "%9.2f" % item["timespan"] } seconds, #{ "%6.2f" %  (item["timespan"].to_f/3600) } hours"
                    }
                LucilleCore::pressEnterToContinue()
            end
            if operation=="stop" then
                NSXLightThreadUtils::stopLightThread(lightThread["uuid"])
            end
            if operation=="add time:" then
                timeInHours = LucilleCore::askQuestionAnswerAsString("Time in hours: ").to_f
                NSXLightThreadUtils::addTimeToLightThread(lightThread["uuid"], timeInHours*3600)
            end
            if operation=="update description:" then
                description = LucilleCore::askQuestionAnswerAsString("description: ")
                lightThread["description"] = description
                NSXLightThreadUtils::commitLightThreadToDisk(lightThread)
            end
            if operation=="update daily time commitment:" then
                lightThread["dailyTimeCommitment"] = NSXLightThreadUtils::dailyTimeCommitmentPickerOrNull()
                NSXLightThreadUtils::commitLightThreadToDisk(lightThread)
            end
            if operation == "set folderpaths" then
                puts "Not implemented yet"
                LucilleCore::pressEnterToContinue()
                # NSXLightThreadUtils::commitLightThreadToDisk(lightThread)
            end
            if operation == "set activationWeekDays" then
                selectedWeekDays, _ = LucilleCore::selectZeroOrMore("activation week days", NSXMiscUtils::weekDays(), [])
                lightThread["activationWeekDays"] = selectedWeekDays
                NSXLightThreadUtils::commitLightThreadToDisk(lightThread)
            end
            if operation=="destroy" then
                answer = LucilleCore::askQuestionAnswerAsBoolean("You are about to destroy this LightThread, are you sure you want to do that ? ")
                if answer then
                    NSXLightThreadUtils::destroyLightThread(lightThread["uuid"])
                end
                break
            end
            if operation == "stream items dive" then
                NSXStreamsUtils::shiftItemsOrdinalDownIfRequired(NSXLightThreadsStreamsInterface::lightThreadToItsStreamItemsOrdered(lightThread))
                items = NSXLightThreadsStreamsInterface::lightThreadToItsStreamItemsOrdered(lightThread)
                next if items.size == 0
                cardinal = items.size
                if items.size > 20 then
                    cardinal = LucilleCore::selectEntityFromListOfEntitiesOrNull("cardinal:", [20.to_s, items.size.to_s]).to_i
                end
                loop {
                    objects = NSXLightThreadsStreamsInterface::lightThreadToItsStreamItemsOrdered(lightThread)
                        .first(cardinal)
                        .map{|streamItem| NSXStreamsUtils::streamItemToStreamCatalystObject(lightThread, 1, streamItem) }
                    object = LucilleCore::selectEntityFromListOfEntitiesOrNull("object:", objects, lambda{|object| object["announce"] })
                    break if object.nil?
                    NSXDisplayUtils::doPresentObjectInviteAndExecuteCommand(object)
                }
            end
        }
        resetLightThreadCache(lightThread["uuid"])
    end

    # NSXLightThreadUtils::lightThreadsDive()
    def self.lightThreadsDive()
        loop {
            lightThread = NSXLightThreadUtils::interactivelySelectLightThreadOrNull()           
            return if lightThread.nil?
            NSXLightThreadUtils::lightThreadDive(lightThread)
        }
    end

    # NSXLightThreadUtils::dailyTimeCommitmentPickerOrNull()
    def self.dailyTimeCommitmentPickerOrNull()
        commitmentInHours = LucilleCore::askQuestionAnswerAsString("Daily commitment (in hours) [empty for none]: ")
        return nil if commitmentInHours.size==0
        commitmentInHours.to_f
    end
end

class NSXLightThreadsTargetFolderInterface

    # NSXLightThreadsTargetFolderInterface::lightThreadToItsFolderCatalystObjects(lightThread)
    def self.lightThreadToItsFolderCatalystObjects(lightThread)
        return [] if NSXLightThreadUtils::trueIfLightThreadIsRunning(lightThread)
        return [] if NSXMiscUtils::nonNullValueOrDefaultValue(NSXLightThreadMetrics::lightThreadToLivePercentageOverThePastNDaysOrNull(lightThread, 1), 0) >= 100
        lightThread["folderpaths"]
            .select{|folderpath|
                File.exist?(folderpath)
            }
            .select{|folderpath|
                uuid = Digest::SHA1.hexdigest("#{lightThread["uuid"]}:#{folderpath}:66aeb2e8-f161-4931-8c55-03d11468fc55")
                KeyValueStore::getOrNull("/Galaxy/DataBank/Catalyst/LightThreads-KVStoreRepository", "A8ED6E22-3427-479B-AC50-012F36BBBC4D:#{uuid}:#{NSXMiscUtils::currentDay()}").nil?
            }
            .map{|folderpath|
                uuid = Digest::SHA1.hexdigest("#{lightThread["uuid"]}:#{folderpath}:66aeb2e8-f161-4931-8c55-03d11468fc55")
                object              = {}
                object["uuid"]      = uuid
                object["agentuid"]  = "201cac75-9ecc-4cac-8ca1-2643e962a6c6"
                object["metric"]    = NSXRunner::isRunning?(uuid) ? 2 : (NSXLightThreadMetrics::lightThread2TargetFolderpathObjectMetric(lightThread) + NSXMiscUtils::traceToMetricShift(uuid))
                object["announce"]  = "LightThread: #{lightThread["description"]} ; Folder: #{folderpath}#{( NSXRunner::isRunning?(uuid) ? " (running for #{(NSXRunner::runningTimeOrNull(uuid).to_f/3600).round(2)} hours)" : "" )}"
                object["commands"]  = ["stop", "start", "dayoff"]
                object["defaultExpression"] = NSXRunner::isRunning?(uuid) ? "stop" : "start"
                object["isRunning"] = NSXRunner::isRunning?(uuid)
                object["item-data"] = {}
                object["item-data"]["lightThread"] = lightThread
                object["commandsLambdas"] = {
                    "dayoff" => lambda{|object|
                        objectuuid = object["uuid"]
                        lightThreadUUID = object["item-data"]["lightThread"]["uuid"]
                        if NSXRunner::isRunning?(objectuuid) then
                            puts "You cannot dayoff a running folder. You must stop first."
                            LucilleCore::pressEnterToContinue()
                            return
                        end
                        KeyValueStore::set("/Galaxy/DataBank/Catalyst/LightThreads-KVStoreRepository", "A8ED6E22-3427-479B-AC50-012F36BBBC4D:#{uuid}:#{NSXMiscUtils::currentDay()}", "off")
                        resetLightThreadCache(lightThreadUUID)
                    },
                    "stop" => lambda{|object|
                        objectuuid = object["uuid"]
                        lightThreadUUID = object["item-data"]["lightThread"]["uuid"]
                        return if !NSXRunner::isRunning?(objectuuid)
                        timespanInSeconds = NSXRunner::stop(objectuuid)
                        NSXLightThreadUtils::addTimeToLightThread(lightThreadUUID, timespanInSeconds)
                        resetLightThreadCache(lightThreadUUID)
                    },
                    "start" => lambda{|object|
                        objectuuid = object["uuid"]
                        lightThreadUUID = object["item-data"]["lightThread"]["uuid"]
                        return if NSXRunner::isRunning?(objectuuid)
                        NSXRunner::start(objectuuid)
                        resetLightThreadCache(lightThreadUUID)
                    }
                }
                object
            }
    end
end

class NSXLightThreadsStreamsInterface

    # NSXLightThreadsStreamsInterface::lightThreadToItsStreamCatalystObjects(lightThread)
    def self.lightThreadToItsStreamCatalystObjects(lightThread)
        lightThreadMetricForStreamItems = NSXLightThreadMetrics::lightThread2BaseStreamItemMetric(lightThread)
        items = NSXLightThreadsStreamsInterface::lightThreadToItsStreamItemsOrdered(lightThread)
        items = NSXLightThreadsStreamsInterface::filterAwayStreamItemsThatAreDoNotShowUntilHidden(items)
        items1 = 
        if lightThread["uuid"]=="cf78ae41" then
            items
        else
            items.first(6)
        end
        items2 = items.select{|item| NSXRunner::isRunning?(item["uuid"]) }
        itemsWithoutDuplicate = []
        (items1+items2).each{|item|
            next if itemsWithoutDuplicate.map{|item| item["uuid"] }.include?(item["uuid"])
            itemsWithoutDuplicate << item
        }
        itemsWithoutDuplicate.map{|item| NSXStreamsUtils::streamItemToStreamCatalystObject(lightThread, lightThreadMetricForStreamItems, item) }
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
        return nil if lightThread["dailyTimeCommitment"].nil?
        items = NSXLightThreadUtils::getLightThreadTimeRecordItems(lightThread["uuid"])
        timeDoneExpectationInHours = n * lightThread["dailyTimeCommitment"]
        timeDoneLiveInHours = NSXLightThreadMetrics::lightThreadToLiveAndOrSimulatedDoneTimeSpanInSecondsOverThePastNDays(lightThread, n, simulationTimeInSeconds).to_f/3600
        100 * (timeDoneLiveInHours.to_f / timeDoneExpectationInHours)
    end

    # NSXLightThreadMetrics::lightThreadBestPercentageOrNull(lightThread)
    def self.lightThreadBestPercentageOrNull(lightThread)
        bestPercentage = (1..7).map{|indx| NSXMiscUtils::nonNullValueOrDefaultValue(NSXLightThreadMetrics::lightThreadToLivePercentageOverThePastNDaysOrNull(lightThread, indx), 0) }.max
        bestPercentage
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

    # NSXLightThreadMetrics::lightThread2Metric(lightThread)
    def self.lightThread2Metric(lightThread)
        return 2 if NSXLightThreadUtils::trueIfLightThreadIsRunning(lightThread)
        return 0 if lightThread["dailyTimeCommitment"].nil?
        bestPercentage = NSXLightThreadMetrics::lightThreadBestPercentageOrNull(lightThread)
        metric = 0.2 + (lightThread["isPriorityThread"] ? 0.4 : 0.1)*Math.exp(-bestPercentage.to_f/50) + NSXMiscUtils::traceToMetricShift(lightThread["uuid"])
        metric
    end

    # NSXLightThreadMetrics::lightThread2BaseStreamItemMetric(lightThread)
    def self.lightThread2BaseStreamItemMetric(lightThread)
        return 0.90 if lightThread["dailyTimeCommitment"].nil?
        # We do not display the stream items if the LightThread itself is running
        shiftUp = [0.001, 0.002][Time.new.day % 2] # The shift array is the opposite of what it is for the Folder
        NSXLightThreadUtils::trueIfLightThreadIsRunning(lightThread) ? 0 : NSXLightThreadMetrics::lightThread2Metric(lightThread) + shiftUp
    end

    # NSXLightThreadMetrics::lightThread2TargetFolderpathObjectMetric(lightThread)
    def self.lightThread2TargetFolderpathObjectMetric(lightThread)
        # We do not display the folder item if the LightThread itself is running
        shiftUp = [0.002, 0.001][Time.new.day % 2] # The shift array is the opposite of what it is for the stream items
        NSXLightThreadUtils::trueIfLightThreadIsRunning(lightThread) ? 0 : NSXLightThreadMetrics::lightThread2Metric(lightThread) + shiftUp
    end
end


