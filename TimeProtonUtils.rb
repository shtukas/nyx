
# encoding: UTF-8

class TimeProtonUtils

    # TimeProtonUtils::timeProtonsWithFilepaths(): [timeProton, filepath]
    def self.timeProtonsWithFilepaths()
        Dir.entries("#{CATALYST_COMMON_DATABANK_CATALYST_FOLDERPATH}/System-Data/TimeProtons")
            .select{|filename| filename[-5, 5]=='.json' }
            .map{|filename| "#{CATALYST_COMMON_DATABANK_CATALYST_FOLDERPATH}/System-Data/TimeProtons/#{filename}" }
            .map{|filepath| [JSON.parse(IO.read(filepath)), filepath] }
            .map{|pair|
                timeProton, filepath = pair
                if timeProton["catalyst-object-uuids"].nil? then
                    timeProton["catalyst-object-uuids"] = []
                end
                count1 = timeProton["catalyst-object-uuids"].size
                timeProton["catalyst-object-uuids"] = timeProton["catalyst-object-uuids"].select{|objectuuid| Canary::isAlive(objectuuid) }
                count2 = timeProton["catalyst-object-uuids"].size
                if count1!=count2 then
                    TimeProtonUtils::commitTimeProtonToDisk(timeProton, File.basename(filepath))
                end
                [timeProton, filepath]
            }
    end

    # TimeProtonUtils::curateListObjectsListing(list)
    def self.curateListObjectsListing(list)
        list["catalyst-object-uuids"] = list["catalyst-object-uuids"].select{|objectuuid| Canary::isAlive(objectuuid) }
        list
    end

    # TimeProtonUtils::allCatalystItemsUUID()
    def self.allCatalystItemsUUID()
        TimeProtonUtils::timeProtonsWithFilepaths()
            .map{|pair| pair[0]["catalyst-object-uuids"] }
            .flatten
            .uniq
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
        File.open("#{CATALYST_COMMON_DATABANK_CATALYST_FOLDERPATH}/System-Data/TimeProtons/#{filename}", "w") { |f| f.puts(JSON.pretty_generate(timeProton)) }
    end

    # TimeProtonUtils::makeNewTimeProton(description, timeCommitmentEvery20Hours, target)
    def self.makeNewTimeProton(description, timeCommitmentEvery20Hours, target)
        timeProton = {
            "uuid"           => SecureRandom.hex(4),
            "unixtime"       => Time.new.to_i,
            "description"    => description,
            "time-commitment-every-20-hours-in-hours" => timeCommitmentEvery20Hours,
            "status"         => ["sleeping", 0]
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
        object["commands"]  = TimeProtonUtils::trueIfTimeProtonIsRunning(timeProton) ? ["stop"] : ["start", "time:", "dive"]
        object["default-expression"] = TimeProtonUtils::trueIfTimeProtonIsRunning(timeProton) ? "stop" : "start"
        object["is-running"] = TimeProtonUtils::trueIfTimeProtonIsRunning(timeProton)
        object["item-data"] = {}
        object["item-data"]["filepath"] = filepath
        object["item-data"]["timeProton"] = timeProton
        object 
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
        itemsAsString = "(#{timeProton["catalyst-object-uuids"].size} objects)"
        "timeProton: #{timeProton["description"]} #{timeAsString} #{itemsAsString}"
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
            operation = LucilleCore::selectEntityFromListOfEntitiesOrNull("operation:", ["start", "stop", "time:", "show items", "remove items", "time commitment:", "edit object", "destroy"])
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
            if operation == "show items" then
                loop {
                    objects = CatalystObjectsOperator::getObjects().select{ |object| timeProton["catalyst-object-uuids"].include?(object["uuid"]) }
                    selectedobject = LucilleCore::selectEntityFromListOfEntitiesOrNull("object", objects, lambda{ |object| CommonsUtils::objectToString(object) })
                    break if selectedobject.nil?
                    CommonsUtils::doPresentObjectInviteAndExecuteCommand(selectedobject)
                }
            end
            if operation == "remove items" then
                loop {
                    objects = CatalystObjectsOperator::getObjects().select{ |object| timeProton["catalyst-object-uuids"].include?(object["uuid"]) }
                    selectedobject = LucilleCore::selectEntityFromListOfEntitiesOrNull("object", objects, lambda{ |object| CommonsUtils::objectToString(object) })
                    break if selectedobject.nil?
                    timeProton["catalyst-object-uuids"].delete(selectedobject["uuid"])
                    filepath = TimeProtonUtils::getTimeProtonFilepathFromItsUUIDOrNull(timeProton["uuid"])
                    TimeProtonUtils::commitTimeProtonToDisk(timeProton, File.basename(filepath))
                }
            end
            if operation=="time commitment:" then
                timeCommitmentEvery20Hours = LucilleCore::askQuestionAnswerAsString("time commitment every day (every 20 hours): ").to_f
                timeProton["time-commitment-every-20-hours-in-hours"] = timeCommitmentEvery20Hours
                TimeProtonUtils::commitTimeProtonToDisk(timeProton, File.basename(TimeProtonUtils::getTimeProtonFilepathFromItsUUIDOrNull(timeProton["uuid"])))
            end
            if operation=="edit object" then
                filepath = TimeProtonUtils::getTimeProtonFilepathFromItsUUIDOrNull(timeProton["uuid"])
                system("open '#{filepath}'")
            end
            if operation=="destroy" then
                answer = LucilleCore::askQuestionAnswerAsBoolean("You are about to destroy this Time Proton, are you sure you want to do that ? ")
                if answer then
                    timeprotonfilepath = TimeProtonUtils::getTimeProtonFilepathFromItsUUIDOrNull(timeProton["uuid"])
                    if File.exists?(timeprotonfilepath) then
                        FileUtils.rm(timeprotonfilepath)
                    end
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

end