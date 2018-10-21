#!/usr/bin/ruby

# encoding: UTF-8

LIGHT_THREADS_SECONDARY_OBJECTS_RUNNINGSTATUS_SETUUID = "7ee01bb9-0ff8-41de-aec8-8966869d4c96"
LT1526_SETUUID  = "05183ee7-3e44-4363-a6c4-8cab4c0e46bd"

class NSXMiscUtils
 
    # NSXMiscUtils::currentHour()
    def self.currentHour()
        Time.now.utc.iso8601[0,13]
    end

    # NSXMiscUtils::currentDay()
    def self.currentDay()
        Time.now.utc.iso8601[0,10]
    end

    # NSXMiscUtils::currentDayTime()
    def self.currentDayTime()
        Time.now.utc.iso8601
    end

    def self.isWeekDay()
        [1,2,3,4,5].include?(Time.new.wday)
    end

    def self.currentWeekDay()
        weekdays = ["sunday", "monday", "tuesday", "wednesday", "thursday", "friday", "saturday"]
        weekdays[Time.new.wday]
    end

    # NSXMiscUtils::areCoreHoursOfTheDay()
    def self.areCoreHoursOfTheDay()
        (Time.new.hour >= 8) and (Time.new.hour < 16)
    end

    def self.isInteger(str)
        str.to_i.to_s == str
    end

    def self.isFloat(str)
        str.to_f.to_s == str
    end

    def self.traceToRealInUnitInterval(trace)
        ( '0.'+Digest::SHA1.hexdigest(trace).gsub(/[^\d]/, '') ).to_f
    end

    # NSXMiscUtils::traceToMetricShift(trace)
    def self.traceToMetricShift(trace)
        0.001*NSXMiscUtils::traceToRealInUnitInterval(trace)
    end

    def self.realNumbersToZeroOne(x, pointAtZeroDotFive, unit)
        alpha =
            if x >= pointAtZeroDotFive then
                2-Math.exp(-(x-pointAtZeroDotFive).to_f/unit)
            else
                Math.exp((x-pointAtZeroDotFive).to_f/unit)
            end
        alpha.to_f/2
    end

    def self.screenHeight()
        `/usr/bin/env tput lines`.to_i
    end

    def self.screenWidth()
        `/usr/bin/env tput cols`.to_i
    end

    def self.selectDateOfNextNonTodayWeekDay(weekday)
        weekDayIndexToStringRepresentation = lambda {|indx|
            weekdayNames = ["sunday", "monday", "tuesday", "wednesday", "thursday", "friday", "saturday"]
            weekdayNames[indx]
        }
        (1..7).each{|indx|
            if weekDayIndexToStringRepresentation.call((Time.new+indx*86400).wday) == weekday then
                return (Time.new+indx*86400).to_s[0,10]
            end
        }
    end

    def self.codeToDatetimeOrNull(code)

        # +<weekdayname>
        # +<integer>day(s)
        # +<integer>hour(s)
        # +YYYY-MM-DD

        code = code[1,99]

        # <weekdayname>
        # <integer>day(s)
        # <integer>hour(s)
        # YYYY-MM-DD

        localsuffix = Time.new.to_s[-5,5]
        morningShowTime = "09:00:00 #{localsuffix}"
        weekdayNames = ["sunday", "monday", "tuesday", "wednesday", "thursday", "friday", "saturday"]

        if weekdayNames.include?(code) then
            # We have a week day
            weekdayName = code
            date = NSXMiscUtils::selectDateOfNextNonTodayWeekDay(weekdayName)
            datetime = "#{date} #{morningShowTime}"
            return datetime
        end

        if code.include?("hour") then
            return ( Time.new + code.to_f*3600 ).utc.iso8601
        end

        if code.include?("day") then
            return ( DateTime.now + code.to_f ).to_time.utc.iso8601
        end

        if code[4,1]=="-" and code[7,1]=="-" then
            return DateTime.parse("#{code} #{morningShowTime}").to_time.utc.iso8601
        end

        nil
    end

    def self.editTextUsingTextmate(text)
      filename = SecureRandom.hex
      filepath = "/tmp/#{filename}"
      File.open(filepath, 'w') {|f| f.write(text)}
      system("/usr/local/bin/mate \"#{filepath}\"")
      print "> press enter when done: "
      input = STDIN.gets
      IO.read(filepath)
    end

    # NSXMiscUtils::isLucille18()
    def self.isLucille18()
        ENV["COMPUTERLUCILLENAME"] == "Lucille18"
    end

    def self.isLucille19()
        ENV["COMPUTERLUCILLENAME"] == "Lucille19"
    end
    
    def self.getStandardListingPosition()
        NSXSystemDataOperator::getOrDefaultValue("301bc639-db20-4eff-bc84-94b4b9e4c133", 1)
    end

    # NSXMiscUtils::setStandardListingPosition(position)
    def self.setStandardListingPosition(position)
        NSXSystemDataOperator::set("301bc639-db20-4eff-bc84-94b4b9e4c133", position)
    end

    def self.emailSync(verbose)
        begin
            GeneralEmailClient::sync(JSON.parse(IO.read("#{CATALYST_COMMON_DATABANK_CATALYST_FOLDERPATH}/Agents-Data/Wave/Wave-Email-Config/guardian-relay.json")), verbose)
            OperatorEmailClient::download(JSON.parse(IO.read("#{CATALYST_COMMON_DATABANK_CATALYST_FOLDERPATH}/Agents-Data/Wave/Wave-Email-Config/operator.json")), verbose)
        rescue
        end
    end

    # NSXMiscUtils::newBinArchivesFolderpath()
    def self.newBinArchivesFolderpath()
        time = Time.new
        targetFolder = "#{CATALYST_COMMON_BIN_ARCHIVES_TIMELINE_FOLDERPATH}/#{time.strftime("%Y")}/#{time.strftime("%Y%m")}/#{time.strftime("%Y%m%d")}/#{time.strftime("%Y%m%d-%H%M%S-%6N")}"
        FileUtils.mkpath(targetFolder)
        targetFolder       
    end

    def self.object2DonotShowUntilAsString(object)
        ( object["do-not-show-until-datetime"] and ( Time.now.utc.iso8601 < DateTime.parse(object["do-not-show-until-datetime"]).to_time.utc.iso8601 ) ) ? " (do not show until: #{object["do-not-show-until-datetime"]})" : ""
    end

    def self.processItemDescriptionPossiblyAsTextEditorInvitation(description)
        if description=='text' then
            editTextUsingTextmate("")
        else
            description
        end
    end

    def self.simplifyURLCarryingString(string)
        return string if /http/.match(string).nil?
        [/^\{\s\d*\s\}/, /^\[\]/, /^line:/, /^todo:/, /^url:/, /^\[\s*\d*\s*\]/]
            .each{|regex|
                if ( m = regex.match(string) ) then
                    string = string[m.to_s.size, string.size].strip
                    return NSXMiscUtils::simplifyURLCarryingString(string)
                end
            }
        string
    end

    def self.waveInsertNewItemDefaults(description) # uuid: String
        description = NSXMiscUtils::processItemDescriptionPossiblyAsTextEditorInvitation(description)
        uuid = SecureRandom.hex(4)
        folderpath = NSXAgentWave::timestring22ToFolderpath(LucilleCore::timeStringL22())
        FileUtils.mkpath folderpath
        File.open("#{folderpath}/catalyst-uuid", 'w') {|f| f.write(uuid) }
        File.open("#{folderpath}/description.txt", 'w') {|f| f.write(description) }
        schedule = WaveSchedules::makeScheduleObjectTypeNew()
        NSXAgentWave::writeScheduleToDisk(uuid, schedule)
        uuid
    end

    def self.buildCatalystObjectFromDescription(description) # (uuid, schedule)
        uuid = SecureRandom.hex(4)
        folderpath = NSXAgentWave::timestring22ToFolderpath(LucilleCore::timeStringL22())
        FileUtils.mkpath folderpath
        File.open("#{folderpath}/catalyst-uuid", 'w') {|f| f.write(uuid) }
        File.open("#{folderpath}/description.txt", 'w') {|f| f.write(description) }
        schedule = WaveSchedules::makeScheduleObjectTypeNew()
        NSXAgentWave::writeScheduleToDisk(uuid, schedule) 
        [uuid, schedule]
    end

    # NSXMiscUtils::InteractiveLightThreadChoiceAndMakeLT1526Claim(objectuuid)
    def self.InteractiveLightThreadChoiceAndMakeLT1526Claim(objectuuid)
        lightThread = NSXLightThreadUtils::interactivelySelectLightThreadOrNull()
        return nil if lightThread.nil?
        NSXMiscUtils::makeLT1526Claim(objectuuid, lightThread["uuid"])
        lightThread
    end

    def self.waveInsertNewItemInteractive(description)
        description = NSXMiscUtils::processItemDescriptionPossiblyAsTextEditorInvitation(description)
        uuid, schedule = NSXMiscUtils::buildCatalystObjectFromDescription(description)
        NSXAgentWave::writeScheduleToDisk(uuid, schedule)    
        loop {
            option = LucilleCore::selectEntityFromListOfEntitiesOrNull("option", ["schedule", "datetime code", ">thread"])
            break if option.nil?
            if option == "schedule" then
                schedule = WaveSchedules::makeScheduleObjectInteractivelyEnsureChoice()
                puts JSON.pretty_generate(schedule)
                NSXAgentWave::writeScheduleToDisk(uuid, schedule)  
            end
            if option == "datetime code" then
                if (datetimecode = LucilleCore::askQuestionAnswerAsString("datetime code ? (empty for none) : ")).size>0 then
                    if (datetime = NSXMiscUtils::codeToDatetimeOrNull(datetimecode)) then
                        puts "Won't show until: #{datetime}"
                        NSXDoNotShowUntilDatetime::setDatetime(uuid, datetime)
                    end
                end
            end
            if option == ">thread" then
                lightThread = NSXMiscUtils::InteractiveLightThreadChoiceAndMakeLT1526Claim(uuid)
                if lightThread then
                    puts "Inserted in #{lightThread["description"]}"
                end
            end
        }
        signal = ["reload-agent-objects", NSXAgentWave::agentuuid()]
        NSXCatalystObjectsOperator::processAgentProcessorSignal(signal)
    end

    # NSXMiscUtils::trueNoMoreOftenThanNEverySeconds(repositorylocation, uuid, timespanInSeconds)
    def self.trueNoMoreOftenThanNEverySeconds(repositorylocation, uuid, timespanInSeconds)
        unixtime = NSXSystemDataOperator::getOrDefaultValue("9B46F2C2-8952-4387-BEE9-D365C512858E:#{uuid}", 0)
        if ( Time.new.to_i - unixtime) > timespanInSeconds then
            NSXSystemDataOperator::set("9B46F2C2-8952-4387-BEE9-D365C512858E:#{uuid}", Time.new.to_i)
            true
        else
            false
        end 
    end

    # NSXMiscUtils::shouldDisplayRelativelyToDoNotShowUntilDateTime(objectuuid)
    def self.shouldDisplayRelativelyToDoNotShowUntilDateTime(objectuuid)
        (NSXDoNotShowUntilDatetime::getDatetimeOrNull(objectuuid) || NSXMiscUtils::currentDayTime()) <= NSXMiscUtils::currentDayTime()
    end

    # NSXMiscUtils::fDoNotShowUntilDateTimeUpdateForDisplay(object)
    def self.fDoNotShowUntilDateTimeUpdateForDisplay(object)
        return object if object["is-running"]
        return object if NSXMiscUtils::shouldDisplayRelativelyToDoNotShowUntilDateTime(object["uuid"])
        object["metric"] = 0
        object[":metric-set-to-zero-by:NSXMiscUtils::fDoNotShowUntilDateTimeUpdateForDisplay:"]
        object
    end

    # NSXMiscUtils::objectToString(object)
    def self.objectToString(object)
        announce = object['announce'].lines.first.strip
        [
            object[":is-lightThread-listing-7fdfb1be:"] ? "       " : "(#{"%.3f" % object["metric"]})",
            object['announce'].lines.count > 1 ? " **MULTILINE !!** " : "",
            " #{announce}",
            NSXMiscUtils::object2DonotShowUntilAsString(object),
        ].join()
    end

    # NSXMiscUtils::startLightThreadSecondaryObject(secondaryObjectUUID, lightThreadUUID)
    def self.startLightThreadSecondaryObject(secondaryObjectUUID, lightThreadUUID)
        # Here we only need to record the current unixtime
        object = {
            "uuid"              => secondaryObjectUUID,
            "light-thread-uuid" => lightThreadUUID,
            "start-unixtime"    => Time.new.to_i
        }
        Iphetra::commitObjectToDisk(CATALYST_IPHETRA_DATA_REPOSITORY_FOLDERPATH, LIGHT_THREADS_SECONDARY_OBJECTS_RUNNINGSTATUS_SETUUID, object)
    end

    # NSXMiscUtils::getLightThreadSecondaryObjectRunningStatusOrNull(secondaryObjectUUID)
    def self.getLightThreadSecondaryObjectRunningStatusOrNull(secondaryObjectUUID)
        Iphetra::getObjectByUUIDOrNull(CATALYST_IPHETRA_DATA_REPOSITORY_FOLDERPATH, LIGHT_THREADS_SECONDARY_OBJECTS_RUNNINGSTATUS_SETUUID, secondaryObjectUUID)
        #    {
        #       "uuid"              => secondaryObjectUUID,
        #       "light-thread-uuid" => lightThreadUUID,
        #       "start-unixtime"    => Time.new.to_i
        #    }
    end

    # NSXMiscUtils::unsetLightThreadSecondaryObjectRunningStatus(secondaryObjectUUID)
    def self.unsetLightThreadSecondaryObjectRunningStatus(secondaryObjectUUID)
        Iphetra::destroyObject(CATALYST_IPHETRA_DATA_REPOSITORY_FOLDERPATH, LIGHT_THREADS_SECONDARY_OBJECTS_RUNNINGSTATUS_SETUUID, secondaryObjectUUID)
    end

    # NSXMiscUtils::makeLT1526Claim(secondaryObjectUUID, lightThreadUUID)
    def self.makeLT1526Claim(secondaryObjectUUID, lightThreadUUID)
        object = {
            "uuid" => secondaryObjectUUID,
            "light-thread-uuid" => lightThreadUUID
        }
        Iphetra::commitObjectToDisk(CATALYST_IPHETRA_DATA_REPOSITORY_FOLDERPATH, LT1526_SETUUID, object)
    end

    # NSXMiscUtils::destroyLT1526Claim(secondaryObjectUUID)
    def self.destroyLT1526Claim(secondaryObjectUUID)
        Iphetra::destroyObject(CATALYST_IPHETRA_DATA_REPOSITORY_FOLDERPATH, LT1526_SETUUID, secondaryObjectUUID)
    end

    # NSXMiscUtils::getLT1526ClaimOrNull(secondaryObjectUUID)
    def self.getLT1526ClaimOrNull(secondaryObjectUUID)
        Iphetra::getObjectByUUIDOrNull(CATALYST_IPHETRA_DATA_REPOSITORY_FOLDERPATH, LT1526_SETUUID, secondaryObjectUUID)
    end

    # NSXMiscUtils::getLT1526Claims()
    def self.getLT1526Claims()
        Iphetra::getObjects(CATALYST_IPHETRA_DATA_REPOSITORY_FOLDERPATH, LT1526_SETUUID)
    end

    # NSXMiscUtils::getLT1526SecondaryObjectUUIDsForLightThread(lightThreadUUID)
    def self.getLT1526SecondaryObjectUUIDsForLightThread(lightThreadUUID)
        NSXMiscUtils::getLT1526Claims()
            .select{|claim| claim["light-thread-uuid"]==lightThreadUUID }
            .map{|claim| claim["uuid"] }
    end

    # NSXMiscUtils::lightThreadSecondaryObjectUUIDToLightThreadLivePercentageOrNull(secondaryObjectUUID)
    def self.lightThreadSecondaryObjectUUIDToLightThreadLivePercentageOrNull(secondaryObjectUUID)
        secondaryObjectRunStatus = NSXMiscUtils::getLightThreadSecondaryObjectRunningStatusOrNull(secondaryObjectUUID)
        return nil if secondaryObjectRunStatus.nil?
        claim = NSXMiscUtils::getLT1526ClaimOrNull(secondaryObjectUUID)
        return nil if claim.nil?
        lightThreadUUID = claim["light-thread-uuid"]
        lightThread = NSXLightThreadUtils::getLightThreadByUUIDOrNull(lightThreadUUID)
        return nil if lightThread.nil?
        timespanInSeconds = Time.new.to_i - secondaryObjectRunStatus["start-unixtime"]
        NSXLightThreadMetrics::lightThreadToLivePercentageOverThePastNDays(lightThread, 1, timespanInSeconds)
    end

    # NSXMiscUtils::issueScreenNotification(title, message)
    def self.issueScreenNotification(title, message)
        title = title.gsub("'","")
        message = message.gsub("'","")
        message = message.gsub("[","|")
        message = message.gsub("]","|")
        command = "terminal-notifier -title '#{title}' -message '#{message}'"
        puts command
        system(command)
    end

end
