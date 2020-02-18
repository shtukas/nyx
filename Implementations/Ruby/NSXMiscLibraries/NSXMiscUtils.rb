#!/usr/bin/ruby

# encoding: UTF-8

require "/Users/pascal/Galaxy/2020-LucilleOS/Software-Common/Ruby-Libraries/KeyValueStore.rb"
=begin
    KeyValueStore::setFlagTrue(repositorylocation or nil, key)
    KeyValueStore::setFlagFalse(repositorylocation or nil, key)
    KeyValueStore::flagIsTrue(repositorylocation or nil, key)

    KeyValueStore::set(repositorylocation or nil, key, value)
    KeyValueStore::getOrNull(repositorylocation or nil, key)
    KeyValueStore::getOrDefaultValue(repositorylocation or nil, key, defaultValue)
    KeyValueStore::destroy(repositorylocation or nil, key)
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

    # NSXMiscUtils::timeStringL22()
    def self.timeStringL22()
        "#{Time.new.strftime("%Y%m%d-%H%M%S-%6N")}"
    end

    # NSXMiscUtils::isInteger(str)
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

    # NSXMiscUtils::realNumbersToZeroOne(x, pointAtZeroDotFive, unit) #1
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

    # NSXMiscUtils::selectDateOfNextNonTodayWeekDay(weekday) #2
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

    # NSXMiscUtils::codeDatetimePatterns()
    def self.codeDatetimePatterns()
        [
            "+<weekdayname>",
            "+<integer>day(s)",
            "+<integer>hour(s)",
            "+YYYY-MM-DD",
            "+1@12:34"
        ]
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

    # NSXMiscUtils::interactivelyDetermineDatetimeEnsureChoice()
    def self.interactivelyDetermineDatetimeEnsureChoice()
        loop {
            puts NSXMiscUtils::codeDatetimePatterns().join("\n")
            code = LucilleCore::askQuestionAnswerAsString("code: ")
            datetime = NSXMiscUtils::codeToDatetimeOrNull(code)
            return datetime if datetime
        }
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

    # NSXMiscUtils::thisInstanceName()
    def self.thisInstanceName()
        ENV["COMPUTERLUCILLENAME"]
    end

    # NSXMiscUtils::instanceNames()
    def self.instanceNames()
        ["Lucille18", "Lucille19"]
    end

    # NSXMiscUtils::isLucille18()
    def self.isLucille18()
        NSXMiscUtils::thisInstanceName() == "Lucille18"
    end

    # NSXMiscUtils::newBinArchivesFolderpath()
    def self.newBinArchivesFolderpath()
        time = Time.new
        folder1 = "#{CATALYST_BIN_TIMELINE_FOLDERPATH}/#{time.strftime("%Y")}/#{time.strftime("%Y%m")}/#{time.strftime("%Y%m%d")}"
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
        folderpath = NSXWaveUtils::timestring22ToFolderpath(LucilleCore::timeStringL22())
        FileUtils.mkpath folderpath
        File.open("#{folderpath}/catalyst-uuid", 'w') {|f| f.write(uuid) }
        File.open("#{folderpath}/description.txt", 'w') {|f| f.write(description) }
        schedule = NSXWaveUtils::makeScheduleObjectInteractivelyEnsureChoice()
        NSXWaveUtils::writeScheduleToDisk(uuid, schedule)
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

    # NSXMiscUtils::filepathOfTheOnlyRelevantFileInFolderOrNull(folderpath)
    def self.filepathOfTheOnlyRelevantFileInFolderOrNull(folderpath)
        filenames = Dir.entries(folderpath).select{|filename| filename[0,1] != '.' }
        return nil if filenames.size != 1
        "#{folderpath}/#{filenames.first}"
    end

    # NSXMiscUtils::agentsSpeedReport()
    def self.agentsSpeedReport()
        NSXBob::agents()
            .map{|agentinterface|
                t1 = Time.new.to_f
                Object.const_get(agentinterface["agent-name"]).send("getObjects")
                t2 = Time.new.to_f
                object = {}
                object["agent-name"] = agentinterface["agent-name"]
                object["retreive-time"] = t2-t1
                object
            }
            .sort{|o1,o2| o1["retreive-time"]<=>o2["retreive-time"] }
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

    # NSXMiscUtils::applyNextTransformationToContent(content)
    def self.applyNextTransformationToContent(content)

        positionOfFirstNonSpaceCharacter = lambda{|line, size|
            return (size-1) if !line.start_with?(" " * size)
            positionOfFirstNonSpaceCharacter.call(line, size+1)
        }

        lines = content.strip.lines.to_a
        return content if lines.empty?
        slineWithIndex = lines
            .reject{|line| line.strip == "" }
            .each_with_index
            .map{|line, i| [line, i] }
            .reduce(nil) {|selectedLineWithIndex, cursorLineWithIndex|
                if selectedLineWithIndex.nil? then
                    cursorLineWithIndex
                else
                    if (positionOfFirstNonSpaceCharacter.call(selectedLineWithIndex.first, 1) < positionOfFirstNonSpaceCharacter.call(cursorLineWithIndex.first, 1)) and (selectedLineWithIndex[1] == cursorLineWithIndex[1]-1) then
                        cursorLineWithIndex
                    else
                        selectedLineWithIndex
                    end
                end
            }
        sline = slineWithIndex.first
        lines
            .reject{|line| line == sline }
            .join()
            .strip
    end

    # NSXMiscUtils::linearMap(x1, y1, x2, y2, x)
    def self.linearMap(x1, y1, x2, y2, x)
        slope = (y2-y1).to_f/(x2-x1)
        (x-x1)*slope + y1
    end

    # NSXMiscUtils::runtimePointsToMetricShift(points, preservationTimeInSeconds, thenTimeToExpMinus1InSeconds)
    def self.runtimePointsToMetricShift(points, preservationTimeInSeconds, thenTimeToExpMinus1InSeconds)
        x2 = points
                .map{|point|
                    d1 = Time.new.to_i - point["unixtime"]
                    x1 = (d1 <= preservationTimeInSeconds) ? 1 : Math.exp(-(d1-preservationTimeInSeconds).to_f/thenTimeToExpMinus1InSeconds)
                    point["algebraicTimespanInSeconds"] * x1
                }
                .inject(0, :+)
        NSXMiscUtils::linearMap(0, 0, 3600, -0.8, x2)
    end

end
