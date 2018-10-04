#!/usr/bin/ruby

# encoding: UTF-8

class NSXMiscUtils
    # NSXMiscUtils::currentHour()
    def self.currentHour()
        Time.now.utc.iso8601[0,13]
    end

    # NSXMiscUtils::currentDay()
    def self.currentDay()
        Time.now.utc.iso8601[0,10]
    end

    def self.isWeekDay()
        [1,2,3,4,5].include?(Time.new.wday)
    end

    def self.currentWeekDay()
        weekdays = ["sunday", "monday", "tuesday", "wednesday", "thursday", "friday", "saturday"]
        weekdays[Time.new.wday]
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
            return ( Time.new + code.to_f*3600 ).to_s
        end

        if code.include?("day") then
            return ( DateTime.now + code.to_f ).to_time.to_s
        end

        if code[4,1]=="-" and code[7,1]=="-" then
            return "#{code} #{morningShowTime}"
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

    def self.isLucille18()
        ENV["COMPUTERLUCILLENAME"] == "Lucille18"
    end

    def self.isLucille19()
        ENV["COMPUTERLUCILLENAME"] == "Lucille19"
    end
    
    def self.getStandardListingPosition()
        NSXSystemDataOperator::getOrDefaultValue("301bc639-db20-4eff-bc84-94b4b9e4c133", 1)
    end

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

    def self.selectRequirementFromExistingRequirementsOrNull()
        LucilleCore::selectEntityFromListOfEntitiesOrNull("requirement", NSXCatalystMetadataInterface::allKnownRequirementsCarriedByObjects())
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

    # NSXMiscUtils::sendCatalystObjectToTimeProton(objectuuid)
    def self.sendCatalystObjectToTimeProton(objectuuid)
        lightThread = NSXLightThreadUtils::interactivelySelectLightThreadOrNull()
        return nil if lightThread.nil?
        NSXCatalystMetadataInterface::setTimeProtonObjectLink(lightThread["uuid"], objectuuid)
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
                lightThread = NSXMiscUtils::sendCatalystObjectToTimeProton(uuid)
                if lightThread then
                    puts "Inserted in #{lightThread["description"]}"
                end
            end
        }
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

    # NSXMiscUtils::fDoNotShowUntilDateTimeUpdateForDisplay(object)
    def self.fDoNotShowUntilDateTimeUpdateForDisplay(object)
        return object if object["is-running"]
        datetime = NSXDoNotShowUntilDatetime::getDatetimeOrNull(object["uuid"])
        return object if datetime.nil?
        datetime = DateTime.parse(datetime).to_time.utc.iso8601
        if Time.now.utc.iso8601 < datetime then
            object["metric"] = 0
            object[":metric-set-to-zero-by:NSXMiscUtils::fDoNotShowUntilDateTimeUpdateForDisplay:"]
        end
        object
    end

    # NSXMiscUtils::flockObjectsProcessedForCatalystDisplay()
    def self.flockObjectsProcessedForCatalystDisplay()
        futureBucketsObjectsUUID = NSXDayBucketOperator::futureBuckets().map{|bucket| bucket["items"].map{|item| item["objectuuid"] } }.flatten
        NSXCatalystObjectsOperator::getObjects()
            .map{|object| object.clone }
            .map{|object| 
                NSXCanary::mark(object["uuid"]) 
                object
            }
            .map{|object| 
                object[":metric-from-agent:"] = object["metric"]
                object
            }
            .map{|object| NSXCyclesOperator::updateObjectWithNS1935MetricIfNeeded(object) }
            .map{|object| NSXMiscUtils::fDoNotShowUntilDateTimeUpdateForDisplay(object) }
            .map{|object| NSXRequirementsOperator::updateForDisplay(object) }
            .map{|object| 
                if futureBucketsObjectsUUID.include?(object["uuid"]) then
                    object["metric"] = 0
                    object[":metric-updated-by:futureBuckets:"] = true
                end
                object
            }
            .map{|object| 
                if ( ordinal = NSXCatalystMetadataInterface::getOrdinalOrNull(object["uuid"]) ) then
                    object["metric"] = NSXOrdinal::ordinalToMetric(ordinal)
                    object[":metric-updated-by:NSXOrdinal::ordinalToMetric:"] = true
                end
                object
            }
    end

    # NSXMiscUtils::putshelp()
    def self.putshelp()
        puts "Special General Commands"
        puts "    help"
        puts "    search <pattern>"
        puts "    :<p>                    # set the listing reference point"
        puts "    +                       # add 1 to the standard listing position"
        puts ""
        puts "    wave: <description>     # create a new wave with that description"
        puts "    thread:                 # create a new lightThread, details entered interactively"
        puts ""
        puts "    threads                 # lightThreads listing dive"
        puts ""
        puts "    requirement on <requirement>"
        puts "    requirement off <requirement>"
        puts "    requirement show [requirement] # optional parameter # shows all the objects of that requirement"
        puts ""
        puts "    email-sync              # run email sync"
        puts "    house-on"
        puts "    house-off"
        puts ""
    end

    # NSXMiscUtils::objectToString(object)
    def self.objectToString(object)
        announce = object['announce'].lines.first.strip
        maybeOrdinal = NSXCatalystMetadataInterface::getOrdinalOrNull(object['uuid'])
        [
            object[":is-lightThread-listing-7fdfb1be:"] ? "       " : "(#{"%.3f" % object["metric"]})",
            maybeOrdinal ? " {ordinal: #{maybeOrdinal}}" : "",
            object['announce'].lines.count > 1 ? " **MULTILINE !!** " : "",
            " #{announce}",
            NSXMiscUtils::object2DonotShowUntilAsString(object),
        ].join()
    end

    # NSXMiscUtils::doPresentObjectInviteAndExecuteCommand(object)
    def self.doPresentObjectInviteAndExecuteCommand(object)
        return if object.nil?
        puts NSXMiscUtils::objectToString(object)
        puts CatalystInterfaceUtils::objectInferfaceString(object)
        print "--> "
        command = STDIN.gets().strip
        command = command.size>0 ? command : ( object["default-expression"] ? object["default-expression"] : "" )
        NSXGeneralCommandHandler::processCommand(object, command)
    end

    # NSXMiscUtils::unixtimeToMetricNS1935(unixtime)
    def self.unixtimeToMetricNS1935(unixtime)
        ageInHours = (Time.new.to_f - unixtime).to_f/3600
        ageInDays = (Time.new.to_f - unixtime).to_f/86400
        0.1 + 0.7*(1-Math.exp(-ageInHours.to_f/6))
    end

end
