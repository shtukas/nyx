
# encoding: UTF-8

# -----------------------------------------------------------------------

class CommonUtils

    # ----------------------------------------------------
    # Misc

    # CommonUtils::editTextSynchronously(text)
    def self.editTextSynchronously(text)
        filename = SecureRandom.uuid
        filepath = "/tmp/#{filename}.txt"
        File.open(filepath, 'w') {|f| f.write(text)}
        system("open '#{filepath}'")
        print "> press enter when done: "
        input = STDIN.gets
        IO.read(filepath)
    end

    # CommonUtils::accessText(text)
    def self.accessText(text)
        filename = SecureRandom.uuid
        filepath = "/tmp/#{filename}.txt"
        File.open(filepath, 'w') {|f| f.write(text)}
        system("open '#{filepath}'")
    end

    # CommonUtils::isInteger(str)
    def self.isInteger(str)
        str == str.to_i.to_s
    end

    # CommonUtils::getNewValueEveryNSeconds(uuid, n)
    def self.getNewValueEveryNSeconds(uuid, n)
      Digest::SHA1.hexdigest("6bb2e4cf-f627-43b3-812d-57ff93012588:#{uuid}:#{(Time.new.to_f/n).to_i.to_s}")
    end

    # CommonUtils::openFilepath(filepath)
    def self.openFilepath(filepath)
        system("open '#{filepath}'")
    end

    # CommonUtils::openFilepathWithInvite(filepath)
    def self.openFilepathWithInvite(filepath)
        system("open '#{filepath}'")
        LucilleCore::pressEnterToContinue()
    end

    # CommonUtils::openUrlUsingSafari(url)
    def self.openUrlUsingSafari(url)
        system("open -a Safari '#{url}'")
    end

    # CommonUtils::onScreenNotification(title, message)
    def self.onScreenNotification(title, message)
        title = title.gsub("'","")
        message = message.gsub("'","")
        message = message.gsub("[","|")
        message = message.gsub("]","|")
        command = "terminal-notifier -title '#{title}' -message '#{message}'"
        system(command)
    end

    # CommonUtils::selectDateOfNextNonTodayWeekDay(weekday) #2
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

    # CommonUtils::screenHeight()
    def self.screenHeight()
        `/usr/bin/env tput lines`.to_i
    end

    # CommonUtils::screenWidth()
    def self.screenWidth()
        `/usr/bin/env tput cols`.to_i
    end

    # CommonUtils::verticalSize(displayStr)
    def self.verticalSize(displayStr)
        displayStr.lines.map{|line| line.size/CommonUtils::screenWidth() + 1 }.inject(0, :+)
    end

    # CommonUtils::fileByFilenameIsSafelyOpenable(filename)
    def self.fileByFilenameIsSafelyOpenable(filename)
        safelyOpeneableExtensions = [".txt", ".jpg", ".jpeg", ".png", ".eml", ".webloc", ".pdf"]
        safelyOpeneableExtensions.any?{|extension| filename.downcase[-extension.size, extension.size] == extension }
    end

    # CommonUtils::putsOnPreviousLine(str)
    def self.putsOnPreviousLine(str)
        # \r move to the beginning \033[1A move up \033[0K erase to the end
        print "\r"
        print "\033[1A"
        print "\033[0K"
        puts str
    end

    # CommonUtils::nx45()
    def self.nx45()
        str1 = Time.new.strftime("%Y%m%d%H%M%S%6N")
        str2 = str1[0, 6]
        str3 = str1[6, 4]
        str4 = str1[10, 4]
        str5 = str1[14, 4]
        str6 = str1[18, 2]
        str7 = SecureRandom.hex[0, 10]
        "10#{str2}-#{str3}-#{str4}-#{str5}-#{str6}#{str7}"
    end

    # CommonUtils::base64_encode(str)
    def self.base64_encode(str)
        return nil if str.nil?
        [str].pack("m")
    end

    # CommonUtils::base64_decode(encoded)
    def self.base64_decode(encoded)
        return nil if encoded.nil?
        encoded.unpack("m").first
    end

    # ----------------------------------------------------
    # File System Routines

    # CommonUtils::locationTrace(location)
    def self.locationTrace(location)
        raise "(error: 4d172723-3748-4f0b-a309-3944e4f352d9)" if !File.exists?(location)
        if File.file?(location) then
            Digest::SHA256.hexdigest("#{File.basename(location)}:#{Digest::SHA256.file(location).hexdigest}")
        else
            t1 = File.basename(location)
            t2 = LucilleCore::locationsAtFolder(location)
                    .map{|loc| CommonUtils::locationTrace(loc) }
                    .join(":")
            Digest::SHA1.hexdigest([t1, t2].join(":"))
        end
    end

    # CommonUtils::locationTraceCode(location)
    def self.locationTraceCode(location)
        raise "(error: 4d172723-3748-4f0b-a309-3944e4f352d9)" if !File.exists?(location)
        if File.file?(location) then
            Digest::SHA1.hexdigest("#{File.basename(location)}:#{Digest::SHA1.file(location).hexdigest}")
        else
            t1 = File.basename(location)
            t2 = LucilleCore::locationsAtFolder(location)
                    .select{|loc| File.basename(loc)[0, 1] != "." }
                    .select{|loc| File.directory?(loc) or File.basename(loc)[-3, 3] == ".rb" }
                    .map{|loc| CommonUtils::locationTraceCode(loc) }
                    .join(":")
            Digest::SHA1.hexdigest([t1, t2].join(":"))
        end
    end

    # CommonUtils::codeTraceWithMultipleRoots(roots)
    def self.codeTraceWithMultipleRoots(roots)
        rtraces = roots.map{|root| CommonUtils::locationTraceCode(root) }
        Digest::SHA1.hexdigest(rtraces.join(":"))
    end

    # CommonUtils::generalCodeTrace()
    def self.generalCodeTrace()
        CommonUtils::locationTraceCode("#{File.dirname(__FILE__)}/..")
    end

    # ----------------------------------------------------
    # Date Routines

    # CommonUtils::isWeekday()
    def self.isWeekday()
        ![6, 0].include?(Time.new.wday)
    end

    # CommonUtils::isWeekend()
    def self.isWeekend()
        !CommonUtils::isWeekday()
    end

    # CommonUtils::getLocalTimeZone()
    def self.getLocalTimeZone()
        `date`.strip[-3 , 3]
    end

    # CommonUtils::todayAsLowercaseEnglishWeekDayName()
    def self.todayAsLowercaseEnglishWeekDayName()
        ["sunday", "monday", "tuesday", "wednesday", "thursday", "friday", "saturday"][Time.new.wday]
    end

    # CommonUtils::interactivelySelectUnixtimeOrNull()
    def self.interactivelySelectUnixtimeOrNull()
        datecode = LucilleCore::askQuestionAnswerAsString("date code: +today, +tomorrow, +<weekdayname>, +<integer>hours(s), +<integer>day(s), +<integer>@HH:MM, +YYYY-MM-DD (empty to abort): ")
        unixtime = CommonUtils::codeToUnixtimeOrNull(datecode)
        return nil if unixtime.nil?
        unixtime
    end

    # CommonUtils::interactivelySelectADateOrNull()
    def self.interactivelySelectADateOrNull()
        unixtime = CommonUtils::interactivelySelectUnixtimeOrNull()
        return nil if unixtime.nil?
        Time.at(unixtime).to_s[0, 10]
    end

    # CommonUtils::interactivelySelectDateTimeIso8601UsingDateCode()
    def self.interactivelySelectDateTimeIso8601UsingDateCode()
        loop {
            unixtime = CommonUtils::interactivelySelectUnixtimeOrNull()
            next if unixtime.nil?
            return Time.at(unixtime).utc.iso8601
        }
    end

    # CommonUtils::nDaysInTheFuture(n)
    def self.nDaysInTheFuture(n)
        (Time.now+86400*n).to_s[0,10]
    end

    # CommonUtils::dateIsWeekEnd(date)
    def self.dateIsWeekEnd(date)
        [6, 0].include?(Date.parse(date).to_time.wday)
    end

    # CommonUtils::codeToUnixtimeOrNull(code)
    def self.codeToUnixtimeOrNull(code)

        return nil if code.nil?
        return nil if code == ""
        return nil if code == "today"

        localsuffix = Time.new.to_s[-5,5]

        dateToMorningUnixtime = lambda {|date|
            DateTime.parse("#{date} 07:00:00 #{localsuffix}").to_time.to_i
        }

        # +++ postpone til midnight
        # ++ postpone by one hour
        # +today
        # +tomorrow
        # +<weekdayname>
        # +<integer>day(s)
        # +<integer>hour(s)
        # +YYYY-MM-DD
        # +1@12:34


        return CommonUtils::unixtimeAtComingMidnightAtGivenTimeZone(CommonUtils::getLocalTimeZone()) if code == "+++"
        return (Time.new.to_i+3600) if code == "++"

        code = code[1,99].strip

        # today
        # tomorrow
        # <weekdayname>
        # <integer>day(s)
        # <integer>hour(s)
        # YYYY-MM-DD
        # 1@12:34

        
        weekdayNames = ["sunday", "monday", "tuesday", "wednesday", "thursday", "friday", "saturday"]

        if weekdayNames.include?(code) then
            # We have a week day
            weekdayName = code
            date = CommonUtils::selectDateOfNextNonTodayWeekDay(weekdayName)
            return dateToMorningUnixtime.call(date)
        end

        if code.include?("hour") then
            return Time.new.to_i + code.to_f*3600
        end

        if code == "today" then
            return dateToMorningUnixtime.call(CommonUtils::today())
        end

        if code == "tomorrow" then
            return dateToMorningUnixtime.call(CommonUtils::nDaysInTheFuture(1))
        end

        if code.include?("day") then
            return Time.new.to_i + code.to_f*86400
        end

        if code[4,1]=="-" and code[7,1]=="-" then
            return dateToMorningUnixtime.call(code)
        end

        if code.include?('@') then
            p1, p2 = code.split('@') # 1 12:34
            return DateTime.parse("#{CommonUtils::nDaysInTheFuture(p1.to_i)[0, 10]} #{p2}:00 #{localsuffix}").to_time.to_i
        end

        nil
    end

    # CommonUtils::today()
    def self.today()
        Time.new.to_s[0, 10]
    end

    # CommonUtils::unixtimeAtComingMidnightAtGivenTimeZone(timezone)
    def self.unixtimeAtComingMidnightAtGivenTimeZone(timezone)
        supportedTimeZones = ["BST", "GMT"]
        if !supportedTimeZones.include?(timezone) then
            raise "error: 7CB8000B-7896-4F61-89ED-89C12E009EE6 ; we are only supporting '#{supportedTimeZones}' and you provided #{timezone}"
        end
        DateTime.parse("#{(DateTime.now.to_date+1).to_s} 00:00:00 #{timezone}").to_time.to_i
    end

    # CommonUtils::datesSinceLastSaturday()
    def self.datesSinceLastSaturday()
        dateIsSaturday = lambda{|date| Date.parse(date).to_time.wday == 6}
        (0..6)
            .map{|i| CommonUtils::nDaysInTheFuture(-i) }
            .reduce([]){|days, day|
                if days.none?{|d| dateIsSaturday.call(d) } then
                    days + [day]
                else
                    days
                end
            }
    end

    # CommonUtils::isDateTime_UTC_ISO8601(datetime)
    def self.isDateTime_UTC_ISO8601(datetime)
        begin
            DateTime.parse(datetime).to_time.utc.iso8601 == datetime
        rescue
            false
        end
    end

    # CommonUtils::nowDatetimeIso8601()
    def self.nowDatetimeIso8601()
        Time.new.utc.iso8601
    end

    # CommonUtils::editDatetimeWithANewDate(datetime, date)
    def self.editDatetimeWithANewDate(datetime, date)
        datetime = "#{date}#{datetime[10, 99]}"
        if !CommonUtils::isDateTime_UTC_ISO8601(datetime) then
            raise "(error: 32c505fa-4168, #{datetime})"
        end
        datetime
    end

    # CommonUtils::dateSinceLastSaturday()
    def self.dateSinceLastSaturday()
        dates = []
        cursor = 0
        loop {
            date = CommonUtils::nDaysInTheFuture(cursor)
            dates << date
            break if Date.parse(date).to_time.wday == 6
            cursor = cursor - 1
        }
        dates
    end

    # CommonUtils::interactiveDateTimeBuilder()
    def self.interactiveDateTimeBuilder()
        puts ""
        date = LucilleCore::askQuestionAnswerAsString("date (YYYY-MM-DD) (empty for today) : ")
        if date == "" then
            date = Time.new.to_s[0, 10]
        end
        time = LucilleCore::askQuestionAnswerAsString("time (HH:MM) (empty for current time) : ")
        if time == "" then
            time = Time.new.to_s[11, 5]
        end
        construct = "#{date} #{time}#{Time.new.to_s[16, 99]}"
        if LucilleCore::askQuestionAnswerAsBoolean("Do you mean '#{construct.green}' ? ", true) then
            DateTime.parse(construct).to_time.utc.iso8601
        else
            CommonUtils::interactiveDateTimeBuilder()
        end
    end

    # ----------------------------------------------------
    # String Utilities

    # CommonUtils::sanitiseStringForFilenaming(str)
    def self.sanitiseStringForFilenaming(str)
        str
            .gsub(":", "-")
            .gsub("/", "-")
            .gsub("'", "")
            .strip
    end

    # CommonUtils::ends_with?(str, ending)
    def self.ends_with?(str, ending)
        str[-ending.size, ending.size] == ending
    end

    # CommonUtils::levenshteinDistance(s, t)
    def self.levenshteinDistance(s, t)
      # https://stackoverflow.com/questions/16323571/measure-the-distance-between-two-strings-with-ruby
      m = s.length
      n = t.length
      return m if n == 0
      return n if m == 0
      d = Array.new(m+1) {Array.new(n+1)}

      (0..m).each {|i| d[i][0] = i}
      (0..n).each {|j| d[0][j] = j}
      (1..n).each do |j|
        (1..m).each do |i|
          d[i][j] = if s[i-1] == t[j-1] # adjust index into string
                      d[i-1][j-1]       # no operation required
                    else
                      [ d[i-1][j]+1,    # deletion
                        d[i][j-1]+1,    # insertion
                        d[i-1][j-1]+1,  # substitution
                      ].min
                    end
        end
      end
      d[m][n]
    end

    # CommonUtils::stringDistance1(str1, str2)
    def self.stringDistance1(str1, str2)
        # This metric takes values between 0 and 1
        return 1 if str1.size == 0
        return 1 if str2.size == 0
        CommonUtils::levenshteinDistance(str1, str2).to_f/[str1.size, str2.size].max
    end

    # CommonUtils::stringDistance2(str1, str2)
    def self.stringDistance2(str1, str2)
        # We need the smallest string to come first
        if str1.size > str2.size then
            str1, str2 = str2, str1
        end
        diff = str2.size - str1.size
        (0..diff).map{|i| CommonUtils::levenshteinDistance(str1, str2[i, str1.size]) }.min
    end

    # ----------------------------------------------------
    # Inherited from the old Librarian

    # CommonUtils::filepathToContentHash(filepath) # nhash
    def self.filepathToContentHash(filepath)
        "SHA256-#{Digest::SHA256.file(filepath).hexdigest}"
    end

    # CommonUtils::openUrlUsingSafari(url)
    def self.openUrlUsingSafari(url)
        system("open -a Safari '#{url}'")
    end

    # CommonUtils::editTextSynchronously(text)
    def self.editTextSynchronously(text)
        filename = "#{SecureRandom.uuid}.txt"
        filepath = "/tmp/#{filename}"
        File.open(filepath, 'w') {|f| f.write(text)}
        system("open '#{filepath}'")
        print "> press enter when done: "
        input = STDIN.gets
        IO.read(filepath)
    end

    # CommonUtils::timeStringL22()
    def self.timeStringL22()
        "#{Time.new.strftime("%Y%m%d-%H%M%S-%6N")}"
    end

    # CommonUtils::atlas(pattern)
    def self.atlas(pattern)
        location = `#{Config::userHomeDirectory()}/Galaxy/Binaries/atlas '#{pattern}'`.strip
        (location != "") ? location : nil
    end

    # CommonUtils::interactivelySelectDesktopLocationOrNull() 
    def self.interactivelySelectDesktopLocationOrNull()
        entries = Dir.entries("#{Config::userHomeDirectory()}/Desktop").select{|filename| !filename.start_with?(".") }.sort
        locationNameOnDesktop = LucilleCore::selectEntityFromListOfEntitiesOrNull("locationname", entries)
        return nil if locationNameOnDesktop.nil?
        "#{Config::userHomeDirectory()}/Desktop/#{locationNameOnDesktop}"
    end

    # CommonUtils::interactivelySelectDesktopLocation()
    def self.interactivelySelectDesktopLocation()
        location = CommonUtils::interactivelySelectDesktopLocationOrNull()
        return location if location
        CommonUtils::interactivelySelectDesktopLocation()
    end

    # CommonUtils::moveFileToBinTimeline(location)
    def self.moveFileToBinTimeline(location)
        return if !File.exists?(location)
        directory = "#{Config::userHomeDirectory()}/x-space/bin-timeline/#{Time.new.strftime("%Y%m")}/#{Time.new.strftime("%Y%m%d-%H%M%S-%6N")}"
        FileUtils.mkpath(directory)
        FileUtils.mv(location, directory)
    end

    # CommonUtils::uniqueStringLocationUsingPartialGalaxySearchOrNull(uniquestring)
    def self.uniqueStringLocationUsingPartialGalaxySearchOrNull(uniquestring)
        roots = [
            "#{Config::userHomeDirectory()}/Desktop",
            "#{Config::userHomeDirectory()}/Galaxy/DataHub"
        ]
        roots.each{|root|
            Find.find(root) do |path|
                if File.basename(path).downcase.include?(uniquestring.downcase) then
                    return path
                end
            end
        }
        nil
    end
end
