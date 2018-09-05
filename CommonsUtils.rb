
# encoding: UTF-8

require 'digest/sha1'
# Digest::SHA1.hexdigest 'foo'
# Digest::SHA1.file(myFile).hexdigest

require 'securerandom'
# SecureRandom.hex    #=> "eb693ec8252cd630102fd0d0fb7c3485"
# SecureRandom.hex(4) #=> "eb693123"
# SecureRandom.uuid   #=> "2d931510-d99f-494a-8c67-87feb05e1594"

require "time"

require_relative "Bob.rb"

# ---------------------------------------------------

class CommonsUtils

    def self.currentHour()
        Time.now.utc.iso8601[0,13]
    end

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
        0.001*CommonsUtils::traceToRealInUnitInterval(trace)
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
            date = CommonsUtils::selectDateOfNextNonTodayWeekDay(weekdayName)
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
        FKVStore::getOrDefaultValue("301bc639-db20-4eff-bc84-94b4b9e4c133", "1").to_i
    end

    def self.setStandardListingPosition(position)
        FKVStore::set("301bc639-db20-4eff-bc84-94b4b9e4c133", position)
    end

    def self.codeHash()
        filenames = Dir.entries(File.dirname(__FILE__)).select{|filename| filename[-3, 3]==".rb" } + [ "catalyst" ]
        longhash = filenames.map{|filename| Digest::SHA1.file("/Galaxy/LucilleOS/Catalyst/#{filename}").hexdigest }.join()
        Digest::SHA1.hexdigest(longhash)
    end

    def self.emailSync(verbose)
        begin
            GeneralEmailClient::sync(JSON.parse(IO.read("#{CATALYST_COMMON_DATABANK_CATALYST_FOLDERPATH}/Agents-Data/Wave/Wave-Email-Config/guardian-relay.json")), verbose)
            OperatorEmailClient::download(JSON.parse(IO.read("#{CATALYST_COMMON_DATABANK_CATALYST_FOLDERPATH}/Agents-Data/Wave/Wave-Email-Config/operator.json")), verbose)
        rescue
        end
    end

    def self.newBinArchivesFolderpath()
        time = Time.new
        targetFolder = "#{CATALYST_COMMON_BIN_ARCHIVES_TIMELINE_FOLDERPATH}/#{time.strftime("%Y")}/#{time.strftime("%Y%m")}/#{time.strftime("%Y%m%d")}/#{time.strftime("%Y%m%d-%H%M%S-%6N")}"
        FileUtils.mkpath(targetFolder)
        targetFolder       
    end

    def self.object2DonotShowUntilAsString(object)
        ( object["do-not-show-until-datetime"] and Time.new.to_s < object["do-not-show-until-datetime"] ) ? " (do not show until: #{object["do-not-show-until-datetime"]})" : ""
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
                    return CommonsUtils::simplifyURLCarryingString(string)
                end
            }
        string
    end

    def self.selectRequirementFromExistingRequirementsOrNull()
        LucilleCore::selectEntityFromListOfEntitiesOrNull("requirement", RequirementsOperator::getAllRequirements())
    end

    def self.waveInsertNewItemDefaults(description) # uuid: String
        description = CommonsUtils::processItemDescriptionPossiblyAsTextEditorInvitation(description)
        uuid = SecureRandom.hex(4)
        folderpath = AgentWave::timestring22ToFolderpath(LucilleCore::timeStringL22())
        FileUtils.mkpath folderpath
        File.open("#{folderpath}/catalyst-uuid", 'w') {|f| f.write(uuid) }
        File.open("#{folderpath}/description.txt", 'w') {|f| f.write(description) }
        schedule = WaveSchedules::makeScheduleObjectTypeNew()
        AgentWave::writeScheduleToDisk(uuid, schedule)
        uuid
    end

    def self.buildCatalystObjectFromDescription(description) # (uuid, schedule)
        uuid = SecureRandom.hex(4)
        folderpath = AgentWave::timestring22ToFolderpath(LucilleCore::timeStringL22())
        FileUtils.mkpath folderpath
        File.open("#{folderpath}/catalyst-uuid", 'w') {|f| f.write(uuid) }
        File.open("#{folderpath}/description.txt", 'w') {|f| f.write(description) }
        schedule = WaveSchedules::makeScheduleObjectTypeNew()
        AgentWave::writeScheduleToDisk(uuid, schedule) 
        [uuid, schedule]
    end

    def self.sendCatalystObjectToList(objectuuid, announce)
        if announce and announce.include?("lisa:") then
            puts "You cannot put a lisa into a list"
            LucilleCore::pressEnterToContinue()
            return
        end
        list = ListsOperator::ui_interactivelySelectListOrNull()
        return if list.nil?
        ListsOperator::addCatalystObjectUUIDToList(objectuuid, list["list-uuid"])
    end

    def self.waveInsertNewItemInteractive(description)
        description = CommonsUtils::processItemDescriptionPossiblyAsTextEditorInvitation(description)
        uuid, schedule = CommonsUtils::buildCatalystObjectFromDescription(description)
        AgentWave::writeScheduleToDisk(uuid, schedule)    
        loop {
            option = LucilleCore::selectEntityFromListOfEntitiesOrNull("option", ["non new schedule", "datetime code", ">list"])
            break if option.nil?
            if option == "non new schedule" then
                schedule = WaveSchedules::makeScheduleObjectInteractivelyEnsureChoice()
                AgentWave::writeScheduleToDisk(uuid, schedule)  
            end
            if option == "datetime code" then
                if (datetimecode = LucilleCore::askQuestionAnswerAsString("datetime code ? (empty for none) : ")).size>0 then
                    if (datetime = CommonsUtils::codeToDatetimeOrNull(datetimecode)) then
                        TheFlock::setDoNotShowUntilDateTime(uuid, datetime)
                        EventsManager::commitEventToTimeline(EventsMaker::doNotShowUntilDateTime(uuid, datetime))
                    end
                end
            end
            if option == ">list" then
                CommonsUtils::sendCatalystObjectToList(uuid, nil)
            end
        }
    end

    def self.trueNoMoreOftenThanNEverySeconds(repositorylocation, uuid, timespanInSeconds)
        unixtime = KeyValueStore::getOrDefaultValue(repositorylocation, "9B46F2C2-8952-4387-BEE9-D365C512858E:#{uuid}", "0").to_i
        if ( Time.new.to_i - unixtime) > timespanInSeconds then
            KeyValueStore::set(repositorylocation, "9B46F2C2-8952-4387-BEE9-D365C512858E:#{uuid}", Time.new.to_i)
            true
        else
            false
        end 
    end

    def self.fDoNotShowUntilDateTimeUpdateForDisplay(object)
        if !TheFlock::getDoNotShowUntilDateTimeDistribution()[object["uuid"]].nil? and (Time.new.to_s < TheFlock::getDoNotShowUntilDateTimeDistribution()[object["uuid"]]) and object["metric"]<=1 then
            # The second condition in case we start running an object that wasn't scheduled to be shown today (they can be found through search)
            object["do-not-show-until-datetime"] = TheFlock::getDoNotShowUntilDateTimeDistribution()[object["uuid"]]
            object["metric"] = 0
        end
        object
    end

    # CommonsUtils::flockObjectsUpdatedForDisplay()
    def self.flockObjectsUpdatedForDisplay()
        Bob::generalFlockUpgrade()
        TheFlock::flockObjects()
            .map{|object| object.clone }
            .map{|object| CommonsUtils::fDoNotShowUntilDateTimeUpdateForDisplay(object) }
            .map{|object| RequirementsOperator::updateForDisplay(object) }
            .map{|object| CyclesOperator::updateObjectWithNewMetricIfNeeded(object) }
            .map{|object| 
                object[":object-original-updated-for-display-metric-8a2be8c6:"] = object["metric"]
                object
            }
    end

    def self.putshelp()
        puts "Special General Commands"
        puts "    help"
        puts "    search <pattern>"
        puts "    :<p>                    # set the listing reference point"
        puts "    +                       # add 1 to the standard listing position"
        puts ""
        puts "    wave: <description>     # create a new wave with that description"
        puts "    stream: <description>   # create a new stream with that description"
        puts "    project: <description>  # create a new project with that description"
        puts "    lisa:                   # create a new lisa, details entered interactively"
        puts "    list: <description>     # create a new list with that description"
        puts ""
        puts "    lisas                   # lisas listing dive"
        puts "    lists                   # lists listing dive"
        puts "    destroy:list            # destroy a list interactively selected"
        puts ""
        puts "    requirement on <requirement>"
        puts "    requirement off <requirement>"
        puts "    requirement show [requirement] # optional parameter # shows all the objects of that requirement"
        puts ""
        puts "    email-sync              # run email sync"
        puts "    lib                     # Invoques the Librarian interactive"
        puts ""
        puts "Special Commands Object:"
        puts "    ,, # cycle"
        puts "    +datetimecode"
        puts "        +<weekdayname>"
        puts "        +<integer>day(s)"
        puts "        +<integer>hour(s)"
        puts "        +YYYY-MM-DD"
        puts "    expose                  # pretty print the object"
        puts "    require <requirement>"
        puts "    requirement remove <requirement>"
        puts "    >list"
        puts "    command ..."
    end

    def self.object2Line_v0(object)
        announce = object['announce'].lines.first.strip
        [
            object[":is-lisa-listing-7fdfb1be:"] ? "       " : "(#{"%.3f" % object["metric"]})",
            " #{announce}",
            CommonsUtils::object2DonotShowUntilAsString(object),
        ].join()
    end

    def self.processObjectAndCommand(object, expression)

        # no object needed

        if expression == 'help' then
            CommonsUtils::putshelp()
            LucilleCore::pressEnterToContinue()
            return
        end

        if expression == 'info' then
            puts "CatalystDevOps::getArchiveTimelineSizeInMegaBytes(): #{CatalystDevOps::getArchiveTimelineSizeInMegaBytes()}".green
            puts "Todolists:".green
            puts "    Stream count : #{( count1 = AgentStream::getUUIDs().size )}".green
            puts "    Vienna count : #{(count3 = $viennaLinkFeeder.links().count)}".green
            puts "    Total        : #{(count1+count3)}".green
            puts "Requirements:".green
            puts "    On  : #{(RequirementsOperator::getAllRequirements() - RequirementsOperator::getCurrentlyUnsatisfiedRequirements()).join(", ")}".green
            puts "    Off : #{RequirementsOperator::getCurrentlyUnsatisfiedRequirements().join(", ")}".green
            LucilleCore::pressEnterToContinue()
            return
        end

        if expression == 'lib' then
            LibrarianExportedFunctions::librarianUserInterface_librarianInteractive()
            return
        end

        if expression == 'email-sync' then
            CommonsUtils::emailSync(true)
            return
        end

        if expression == 'lisas' then
            LisaUtils::ui_lisasDive()
            return
        end

        if expression == 'lists' then
            ListsOperator::ui_listsDive()
            return
        end

        if expression == 'lisa:' then
            description = LucilleCore::askQuestionAnswerAsString("description: ")
            timeCommitmentInHours = LucilleCore::askQuestionAnswerAsString("time commitment in hours: ").to_f
            timeUnitInDays = LucilleCore::askQuestionAnswerAsString("time unit in days: ").to_f
            timestructure = { "time-commitment-in-hours"=> timeCommitmentInHours.to_f, "time-unit-in-days" => timeUnitInDays.to_f }
            repeat = LucilleCore::askQuestionAnswerAsBoolean("should repeat?: ")
            target = nil
            lisa = LisaUtils::spawnNewLisa(description, timestructure, repeat, target)
            puts JSON.pretty_generate(lisa)
            LucilleCore::pressEnterToContinue()
            return
        end

        if expression == 'destroy:list' then
            list = ListsOperator::ui_interactivelySelectListOrNull()
            ListsOperator::destroyList(list["list-uuid"])
        end

        if expression.start_with?("list:") then
            description = expression[5, expression.size].strip
            return if description.size == 0 
            ListsOperator::createList(description)
        end

        if expression.start_with?('wave:') then
            description = expression[5, expression.size].strip
            CommonsUtils::waveInsertNewItemInteractive(description)
            #LucilleCore::pressEnterToContinue()
            return
        end

        if expression.start_with?('stream:') then
            description = expression[7, expression.size].strip
            description = CommonsUtils::processItemDescriptionPossiblyAsTextEditorInvitation(description)
            folderpath = AgentStream::issueNewItemWithDescription(description)
            puts "created item: #{folderpath}"
            LucilleCore::pressEnterToContinue()
            return
        end

        if expression.start_with?("requirement on") then
            _, _, requirement = expression.split(" ").map{|t| t.strip }
            RequirementsOperator::setSatisfifiedRequirement(requirement)
            return
        end

        if expression.start_with?("requirement off") then
            _, _, requirement = expression.split(" ").map{|t| t.strip }
            RequirementsOperator::setUnsatisfiedRequirement(requirement)
            return
        end

        if expression.start_with?("requirement show") then
            _, _, requirement = expression.split(" ").map{|t| t.strip }
            if requirement.nil? or requirement.size==0 then
                requirement = CommonsUtils::selectRequirementFromExistingRequirementsOrNull()
            end
            loop {
                requirementObjects = TheFlock::flockObjects().select{ |object| RequirementsOperator::getObjectRequirements(object['uuid']).include?(requirement) }
                selectedobject = LucilleCore::selectEntityFromListOfEntitiesOrNull("object", requirementObjects, lambda{ |object| CommonsUtils::object2Line_v0(object) })
                break if selectedobject.nil?
                CommonsUtils::doPresentObjectInviteAndExecuteCommand(selectedobject)
            }
            return
        end

        if expression.start_with?("search") then
            pattern = expression[6,expression.size].strip
            loop {
                FlockDiskIO::loadFromEventsTimeline()
                Bob::generalFlockUpgrade()
                searchobjects = TheFlock::flockObjects().select{|object| CommonsUtils::object2Line_v0(object).downcase.include?(pattern.downcase) }
                break if searchobjects.size==0
                selectedobject = LucilleCore::selectEntityFromListOfEntitiesOrNull("object", searchobjects, lambda{ |object| CommonsUtils::object2Line_v0(object) })
                break if selectedobject.nil?
                CommonsUtils::doPresentObjectInviteAndExecuteCommand(selectedobject)
            }
            return
        end

        return if object.nil?

        # object needed

        if expression == ',,' then
            CyclesOperator::setUnixtimeMark(object["uuid"])
            return
        end

        if expression == '>list' then
            CommonsUtils::sendCatalystObjectToList(object["uuid"], object["announce"])
            return
        end

        if expression == 'expose' then
            puts JSON.pretty_generate(object)
            LucilleCore::pressEnterToContinue()
            return
        end

        if expression.start_with?('+') then
            code = expression
            if (datetime = CommonsUtils::codeToDatetimeOrNull(code)) then
                TheFlock::setDoNotShowUntilDateTime(object["uuid"], datetime)
                EventsManager::commitEventToTimeline(EventsMaker::doNotShowUntilDateTime(object["uuid"], datetime))
            end
            return
        end

        if expression.start_with?("require") then
            _, requirement = expression.split(" ").map{|t| t.strip }
            RequirementsOperator::addRequirementToObject(object['uuid'],requirement)
            return
        end

        if expression.start_with?("requirement remove") then
            _, _, requirement = expression.split(" ").map{|t| t.strip }
            RequirementsOperator::removeRequirementFromObject(object['uuid'],requirement)
            return
        end

        if expression.size > 0 then
            tokens = expression.split(" ").map{|t| t.strip }
            .each{|command|
                Bob::agentuuid2AgentData(object["agent-uid"])["object-command-processor"].call(object, command)
            }
        else
            Bob::agentuuid2AgentData(object["agent-uid"])["object-command-processor"].call(object, "")
        end
    end

    def self.doPresentObjectInviteAndExecuteCommand(object)
        return if object.nil?
        puts CatalystInterfaceUtils::object2Line_v1(object)
        print "--> "
        command = STDIN.gets().strip
        command = command.size>0 ? command : ( object["default-expression"] ? object["default-expression"] : "" )
        CommonsUtils::processObjectAndCommand(object, command)
    end

    # CommonsUtils::unixtimeToMetricNS1935(unixtime)
    def self.unixtimeToMetricNS1935(unixtime)
        ageInHours = (Time.new.to_f - unixtime).to_f/3600
        ageInDays = (Time.new.to_f - unixtime).to_f/86400
        0.2 + 0.6*(1-Math.exp(-ageInHours.to_f/6))
    end

end
