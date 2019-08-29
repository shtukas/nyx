#!/usr/bin/ruby

# encoding: UTF-8

require "/Galaxy/Software/Misc-Common/Ruby-Libraries/KeyValueStore.rb"
=begin
    KeyValueStore::setFlagTrue(repositorylocation or nil, key)
    KeyValueStore::setFlagFalse(repositorylocation or nil, key)
    KeyValueStore::flagIsTrue(repositorylocation or nil, key)

    KeyValueStore::set(repositorylocation or nil, key, value)
    KeyValueStore::getOrNull(repositorylocation or nil, key)
    KeyValueStore::getOrDefaultValue(repositorylocation or nil, key, defaultValue)
    KeyValueStore::destroy(repositorylocation or nil, key)
=end

require "/Galaxy/Software/Misc-Common/Ruby-Libraries/Torr.rb"
=begin
    Torr::event(repositorylocation, collectionuuid, mass)
    Torr::weight(repositorylocation, collectionuuid, stabililityPeriodInSeconds, simulationWeight = 0)
    Torr::metric(repositorylocation, collectionuuid, stabililityPeriodInSeconds, targetWeight, metricAtZero, metricAtTarget)
=end

class NSXMiscUtils

    # NSXMiscUtils::currentMonth()
    def self.currentMonth()
        Time.now.utc.iso8601[0,7]
    end
 
    # NSXMiscUtils::currentHour()
    def self.currentHour()
        Time.now.utc.iso8601[0,13]
    end

    # NSXMiscUtils::yesterdayDay()
    def self.yesterdayDay()
        (Time.now-86400).utc.iso8601[0,10]
    end

    # NSXMiscUtils::nDaysAgo(n)
    def self.nDaysAgo(n)
        (Time.now-86400*n).utc.iso8601[0,10]
    end

    # NSXMiscUtils::nDaysInTheFuture(n)
    def self.nDaysInTheFuture(n)
        (Time.now+86400*n).utc.iso8601[0,10]
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

    # NSXMiscUtils::weekDays()
    def self.weekDays()
        ["sunday", "monday", "tuesday", "wednesday", "thursday", "friday", "saturday"]
    end

    # NSXMiscUtils::currentWeekDay()
    def self.currentWeekDay()
        NSXMiscUtils::weekDays()[Time.new.wday]
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

    # NSXMiscUtils::screenHeight()
    def self.screenHeight()
        `/usr/bin/env tput lines`.to_i
    end

    # NSXMiscUtils::screenWidth()
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

    # NSXMiscUtils::codeToDatetimeOrNull(code)
    def self.codeToDatetimeOrNull(code)

        return nil if code.nil?
        return nil if code == ""

        # +<weekdayname>
        # +<integer>day(s)
        # +<integer>hour(s)
        # +YYYY-MM-DD
        # +1@12:34

        code = code[1,99]

        # <weekdayname>
        # <integer>day(s)
        # <integer>hour(s)
        # YYYY-MM-DD
        # 1@12:34

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

        if code.include?('@') then
            p1, p2 = code.split('@') # 1 12:34
            return "#{NSXMiscUtils::nDaysInTheFuture(p1.to_i)[0, 10]} #{p2}:00 #{localsuffix}"
        end

        nil
    end

    # NSXMiscUtils::editTextUsingTextmate(text)
    def self.editTextUsingTextmate(text)
      filename = SecureRandom.hex
      filepath = "/tmp/#{filename}"
      File.open(filepath, 'w') {|f| f.write(text)}
      system("/usr/local/bin/mate \"#{filepath}\"")
      print "> press enter when done: "
      input = STDIN.gets
      IO.read(filepath)
    end

    # NSXMiscUtils::instanceName()
    def self.instanceName()
        ENV["COMPUTERLUCILLENAME"]
    end

    # NSXMiscUtils::isLucille18()
    def self.isLucille18()
        NSXMiscUtils::instanceName() == "Lucille18"
    end

    # NSXMiscUtils::isLucille19()
    def self.isLucille19()
        NSXMiscUtils::instanceName() == "Lucille19"
    end

    # NSXMiscUtils::getStandardListingPosition()   
    def self.getStandardListingPosition()
        KeyValueStore::getOrDefaultValue(nil, "301bc639-db20-4eff-bc84-94b4b9e4c133:#{NSXMiscUtils::currentDay()}", "1").to_i
    end

    # NSXMiscUtils::setStandardListingPosition(position)
    def self.setStandardListingPosition(position)
        KeyValueStore::set(nil, "301bc639-db20-4eff-bc84-94b4b9e4c133:#{NSXMiscUtils::currentDay()}", position)
    end

    # NSXMiscUtils::emailSync(verbose)
    def self.emailSync(verbose)
        GeneralEmailClient::downloadWithoutSync(JSON.parse(IO.read("#{CATALYST_COMMON_DATABANK_CATALYST_FOLDERPATH}/Email-Credentials/operator.json")), verbose)
    end

    # NSXMiscUtils::newBinArchivesFolderpath()
    def self.newBinArchivesFolderpath()
        time = Time.new
        folder1 = "#{CATALYST_COMMON_BIN_ARCHIVES_TIMELINE_FOLDERPATH}/#{time.strftime("%Y")}/#{time.strftime("%Y%m")}/#{time.strftime("%Y%m%d")}"
        folder2 = LucilleCore::indexsubfolderpath(folder1)
        folder3 = "#{folder2}/#{time.strftime("%Y%m%d-%H%M%S-%6N")}"
        FileUtils.mkpath(folder3)
        folder3
    end

    def self.object2DoNotShowUntilAsString(object)
        ( object["do-not-show-until-datetime"] and ( Time.now.utc.iso8601 < DateTime.parse(object["do-not-show-until-datetime"]).to_time.utc.iso8601 ) ) ? " (do not show until: #{object["do-not-show-until-datetime"]})" : ""
    end

    # NSXMiscUtils::processItemDescriptionPossiblyAsTextEditorInvitation(description)
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

    # NSXMiscUtils::spawnNewWaveItem(description): String (uuid)
    def self.spawnNewWaveItem(description)
        description = NSXMiscUtils::processItemDescriptionPossiblyAsTextEditorInvitation(description)
        uuid = SecureRandom.hex(4)
        folderpath = NSXAgentWave::timestring22ToFolderpath(LucilleCore::timeStringL22())
        FileUtils.mkpath folderpath
        File.open("#{folderpath}/catalyst-uuid", 'w') {|f| f.write(uuid) }
        File.open("#{folderpath}/description.txt", 'w') {|f| f.write(description) }
        schedule = WaveSchedules::makeScheduleObjectInteractivelyEnsureChoice()
        NSXAgentWave::writeScheduleToDisk(uuid, schedule)
        uuid
    end

    # NSXMiscUtils::trueNoMoreOftenThanNEverySeconds(repositorylocation, uuid, timespanInSeconds)
    def self.trueNoMoreOftenThanNEverySeconds(repositorylocation, uuid, timespanInSeconds)
        unixtime = KeyValueStore::getOrDefaultValue(repositorylocation, "9B46F2C2-8952-4387-BEE9-D365C512858E:#{uuid}", "0").to_i
        if ( Time.new.to_i - unixtime) > timespanInSeconds then
            KeyValueStore::set(repositorylocation, "9B46F2C2-8952-4387-BEE9-D365C512858E:#{uuid}", Time.new.to_i)
            true
        else
            false
        end 
    end

    # NSXMiscUtils::shouldDisplayRelativelyToDoNotShowUntilDateTime(objectuuid)
    def self.shouldDisplayRelativelyToDoNotShowUntilDateTime(objectuuid)
        (NSXDoNotShowUntilDatetime::getFutureDatetimeOrNull(objectuuid) || NSXMiscUtils::currentDayTime()) <= NSXMiscUtils::currentDayTime()
    end

    # NSXMiscUtils::makeGreenIfObjectRunning(string, isRunning)
    def self.makeGreenIfObjectRunning(string, isRunning)
        isRunning ? string.green : string
    end

    # NSXMiscUtils::onScreenNotification(title, message)
    def self.onScreenNotification(title, message)
        title = title.gsub("'","")
        message = message.gsub("'","")
        message = message.gsub("[","|")
        message = message.gsub("]","|")
        command = "terminal-notifier -title '#{title}' -message '#{message}'"
        system(command)
    end

    # NSXMiscUtils::integerEnumerator()
    def self.integerEnumerator()
        Enumerator.new do |integers|
            cursor = -1
            while true do
                cursor = cursor + 1
                integers << cursor
            end
        end
    end

    # NSXMiscUtils::copyLocationToCatalystBin(location)
    def self.copyLocationToCatalystBin(location)
        return if location.nil?
        return if !File.exists?(location)
        targetFolder = NSXMiscUtils::newBinArchivesFolderpath()
        FileUtils.cp(location,targetFolder)
    end

    # NSXMiscUtils::moveLocationToCatalystBin(location)
    def self.moveLocationToCatalystBin(location)
        return if location.nil?
        return if !File.exists?(location)
        targetFolder = NSXMiscUtils::newBinArchivesFolderpath()
        FileUtils.mv(location,targetFolder)
    end

    # NSXMiscUtils::nonNullValueOrDefaultValue(value, defaultValue)
    def self.nonNullValueOrDefaultValue(value, defaultValue)
        return defaultValue if value.nil?
        value
    end

    # NSXMiscUtils::emitNewValueEveryNSeconds(n)
    def self.emitNewValueEveryNSeconds(n)
        Digest::SHA1.hexdigest("66b44d63-0168-4217-9712-2b84ad3e41cb:#{(Time.new.to_f/n).to_i.to_s}")
    end

    # NSXMiscUtils::objectIsAutoDone(object)
    def self.objectIsAutoDone(object)
        return true if object["announce"].include?("condition 58f3eb60")
        if object and
            object["agentuid"] == "d2de3f8e-6cf2-46f6-b122-58b60b2a96f1" and
            object["generic-content-item"] and
            object["generic-content-item"]["email-subject"] and
            object["generic-content-item"]["email-subject"].start_with?("Declined:") then
            return true
        end
        if object and 
            object["agentuid"] == "d2de3f8e-6cf2-46f6-b122-58b60b2a96f1" and 
            object["announce"].include?("notifications@github.com") and 
            /Merged #\d+ into master./.match(object["announce"]) then
            return true
        end
        if object and 
            object["agentuid"] == "d2de3f8e-6cf2-46f6-b122-58b60b2a96f1" and 
            object["announce"].include?("notifications@github.com") and 
            /^Closed #\d+/.match(object["announce"]) then
            return true
        end
        if object and
            object["agentuid"] == "d2de3f8e-6cf2-46f6-b122-58b60b2a96f1" and
            object["generic-content-item"] and
            object["generic-content-item"]["email-subject"] and
            object["generic-content-item"]["email-subject"].start_with?("Tentatively Accepted:") then
            return true
        end
        if object and
            object["agentuid"] == "d2de3f8e-6cf2-46f6-b122-58b60b2a96f1" and
            object["generic-content-item"] and
            object["generic-content-item"]["email-subject"] and
            object["generic-content-item"]["email-subject"].start_with?("On leave until") then
            return true
        end
        if object and
            object["agentuid"] == "d2de3f8e-6cf2-46f6-b122-58b60b2a96f1" and
            object["generic-content-item"] and
            object["generic-content-item"]["email-subject"] and
            object["generic-content-item"]["email-subject"].downcase.start_with?("on leave re:") then
            return true
        end
        if object and
            object["agentuid"] == "d2de3f8e-6cf2-46f6-b122-58b60b2a96f1" and
            object["generic-content-item"] and
            object["generic-content-item"]["email-subject"] and
            object["generic-content-item"]["email-subject"].downcase.start_with?("out of office") then
            return true
        end
        if object and
            object["agentuid"] == "d2de3f8e-6cf2-46f6-b122-58b60b2a96f1" and
            object["generic-content-item"] and
            object["generic-content-item"]["email-subject"] and
            object["generic-content-item"]["email-subject"].downcase.start_with?("ooo ") then
            return true
        end
        if object and
            object["agentuid"] == "d2de3f8e-6cf2-46f6-b122-58b60b2a96f1" and
            object["generic-content-item"] and
            object["generic-content-item"]["email-subject"] and
            object["generic-content-item"]["email-subject"].downcase.start_with?("accepted: learning groups:") then
            return true
        end
        if object and
            object["agentuid"] == "d2de3f8e-6cf2-46f6-b122-58b60b2a96f1" and
            object["generic-content-item"] and
            object["generic-content-item"]["email-subject"] and
            object["generic-content-item"]["email-subject"].downcase.start_with?("Declined: Learning Groups:".downcase) then
            return true
        end
        if object and
            object["agentuid"] == "d2de3f8e-6cf2-46f6-b122-58b60b2a96f1" and
            object["generic-content-item"] and
            object["generic-content-item"]["email-subject"] and
            object["generic-content-item"]["email-subject"].start_with?("I'm back in the office on") then
            return true
        end
        if object and
            object["agentuid"] == "d2de3f8e-6cf2-46f6-b122-58b60b2a96f1" and
            object["generic-content-item"] and
            object["generic-content-item"]["email-subject"] and
            object["generic-content-item"]["email-subject"].start_with?("Sorry I'm away Re:") then
            return true
        end
        false
    end

    # NSXMiscUtils::getXNote(objectuuid)
    def self.getXNote(objectuuid)
        KeyValueStore::getOrDefaultValue("/Galaxy/DataBank/Catalyst/xnotes", "6ec120de-581e-4704-9fb6-3718cd4f1306:#{objectuuid}", "").strip
    end

    # NSXMiscUtils::hasXNote(objectuuid)
    def self.hasXNote(objectuuid)
        NSXMiscUtils::getXNote(objectuuid).size>0
    end

    # NSXMiscUtils::setXNote(objectuuid, text)
    def self.setXNote(objectuuid, text)
        KeyValueStore::set("/Galaxy/DataBank/Catalyst/xnotes", "6ec120de-581e-4704-9fb6-3718cd4f1306:#{objectuuid}", text)
    end

    # NSXMiscUtils::filepathOfTheOnlyRelevantFileInFolderOrNull(folderpath)
    def self.filepathOfTheOnlyRelevantFileInFolderOrNull(folderpath)
        filenames = Dir.entries(folderpath).select{|filename| filename[0,1] != '.' }
        return nil if filenames.size != 1
        "#{folderpath}/#{filenames.first}"
    end

    # NSXMiscUtils::makeEndOfQueueStreamItemOrdinal()
    def self.makeEndOfQueueStreamItemOrdinal()
        items = NSXStreamsUtils::getItemsFromDisk()
        return 1 if items.size==0
        items.map{|item| item["ordinal"] }.max.to_i + 1
    end

    # NSXMiscUtils::agentsSpeedReport()
    def self.agentsSpeedReport()
        NSXBob::agents()
            .map{|agentinterface|
                t1 = Time.new.to_f
                agentinterface["get-objects"].call()
                t2 = Time.new.to_f
                object = {}
                object["agent-name"] = agentinterface["agent-name"]
                object["retreive-time"] = t2-t1
                object
            }
            .sort{|o1,o2| o1["retreive-time"]<=>o2["retreive-time"] }
    end

    # NSXMiscUtils::setNoInternetForThisHour()
    def self.setNoInternetForThisHour()
        KeyValueStore::setFlagTrue(nil, "d24cbf78-b01e-4fc0-896b-ecc505ffda2a:#{NSXMiscUtils::currentHour()}")
    end

    # NSXMiscUtils::hasInternetCondition1121()
    def self.hasInternetCondition1121()
        !KeyValueStore::flagIsTrue(nil, "d24cbf78-b01e-4fc0-896b-ecc505ffda2a:#{NSXMiscUtils::currentHour()}")
    end

    # NSXMiscUtils::getIPAddressOrNull()
    def self.getIPAddressOrNull()
        line = `ifconfig`
            .lines
            .map{|line| line.strip }
            .drop_while{|line| !line.start_with?("en0:") }
            .first(10)
            .select{|line| line.start_with?("inet ") }
            .first
        return nil if line.nil?
        line = line[5, 99]
        line.split(" ").first.strip
    end

end
