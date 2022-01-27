
# encoding: UTF-8

# -----------------------------------------------------------------------

class Utils

    # Utils::applyNextTransformationToFile(filepath)
    def self.applyNextTransformationToFile(filepath)
        text = IO.read(filepath).strip
        text = SectionsType0141::applyNextTransformationToText(text)
        File.open(filepath, "w"){|f| f.puts(text) }
    end

    # Utils::catalystDataCenterFolderpath()
    def self.catalystDataCenterFolderpath()
        "/Users/pascal/Galaxy/DataBank/Catalyst"
    end

    # Utils::codeToUnixtimeOrNull(code)
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


        return Utils::unixtimeAtComingMidnightAtGivenTimeZone(Utils::getLocalTimeZone()) if code == "+++"
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
            date = Utils::selectDateOfNextNonTodayWeekDay(weekdayName)
            return dateToMorningUnixtime.call(date)
        end

        if code.include?("hour") then
            return Time.new.to_i + code.to_f*3600
        end

        if code == "today" then
            return dateToMorningUnixtime.call(Utils::today())
        end

        if code == "tomorrow" then
            return dateToMorningUnixtime.call(Utils::nDaysInTheFuture(1))
        end

        if code.include?("day") then
            return Time.new.to_i + code.to_f*86400
        end

        if code[4,1]=="-" and code[7,1]=="-" then
            return dateToMorningUnixtime.call(code)
        end

        if code.include?('@') then
            p1, p2 = code.split('@') # 1 12:34
            return DateTime.parse("#{Utils::nDaysInTheFuture(p1.to_i)[0, 10]} #{p2}:00 #{localsuffix}").to_time.to_i
        end

        nil
    end

    # Utils::editTextSynchronously(text)
    def self.editTextSynchronously(text)
        filename = SecureRandom.uuid
        filepath = "/tmp/#{filename}.txt"
        File.open(filepath, 'w') {|f| f.write(text)}
        system("open '#{filepath}'")
        print "> press enter when done: "
        input = STDIN.gets
        IO.read(filepath)
    end

    # Utils::isInteger(str)
    def self.isInteger(str)
        str == str.to_i.to_s
    end

    # Utils::getNewValueEveryNSeconds(uuid, n)
    def self.getNewValueEveryNSeconds(uuid, n)
      Digest::SHA1.hexdigest("6bb2e4cf-f627-43b3-812d-57ff93012588:#{uuid}:#{(Time.new.to_f/n).to_i.to_s}")
    end

    # Utils::nDaysInTheFuture(n)
    def self.nDaysInTheFuture(n)
        (Time.now+86400*n).to_s[0,10]
    end

    # Utils::dateIsWeekEnd(date)
    def self.dateIsWeekEnd(date)
        [6, 0].include?(Date.parse(date).to_time.wday)
    end

    # Utils::stringDistance1(str1, str2)
    def self.stringDistance1(str1, str2)
        # This metric takes values between 0 and 1
        return 1 if str1.size == 0
        return 1 if str2.size == 0
        Utils::levenshteinDistance(str1, str2).to_f/[str1.size, str2.size].max
    end

    # Utils::openFilepath(filepath)
    def self.openFilepath(filepath)
        system("open '#{filepath}'")
    end

    # Utils::openFilepathWithInvite(filepath)
    def self.openFilepathWithInvite(filepath)
        system("open '#{filepath}'")
        LucilleCore::pressEnterToContinue()
    end

    # Utils::openUrlUsingSafari(url)
    def self.openUrlUsingSafari(url)
        system("open -a Safari '#{url}'")
    end

    # Utils::onScreenNotification(title, message)
    def self.onScreenNotification(title, message)
        title = title.gsub("'","")
        message = message.gsub("'","")
        message = message.gsub("[","|")
        message = message.gsub("]","|")
        command = "terminal-notifier -title '#{title}' -message '#{message}'"
        system(command)
    end

    # Utils::selectDateOfNextNonTodayWeekDay(weekday) #2
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

    # Utils::screenHeight()
    def self.screenHeight()
        `/usr/bin/env tput lines`.to_i
    end

    # Utils::screenWidth()
    def self.screenWidth()
        `/usr/bin/env tput cols`.to_i
    end

    # Utils::today()
    def self.today()
        Time.new.to_s[0, 10]
    end

    # Utils::todayAsLowercaseEnglishWeekDayName()
    def self.todayAsLowercaseEnglishWeekDayName()
        ["sunday", "monday", "tuesday", "wednesday", "thursday", "friday", "saturday"][Time.new.wday]
    end

    # Utils::interactivelySelectAUnixtimeOrNull()
    def self.interactivelySelectAUnixtimeOrNull()
        datecode = LucilleCore::askQuestionAnswerAsString("date code +<weekdayname>, +<integer>day(s), +YYYY-MM-DD (empty to abort): ")
        unixtime = Utils::codeToUnixtimeOrNull(datecode)
        return nil if unixtime.nil?
        unixtime
    end

    # Utils::interactivelySelectADateOrNull()
    def self.interactivelySelectADateOrNull()
        unixtime = Utils::interactivelySelectAUnixtimeOrNull()
        return nil if unixtime.nil?
        Time.at(unixtime).to_s[0, 10]
    end

    # Utils::interactivelySelectAUTCIso8601DateTimeOrNull()
    def self.interactivelySelectAUTCIso8601DateTimeOrNull()
        unixtime = Utils::interactivelySelectAUnixtimeOrNull()
        return nil if unixtime.nil?
        Time.at(unixtime).utc.iso8601
    end

    # Utils::verticalSize(displayStr)
    def self.verticalSize(displayStr)
        displayStr.lines.map{|line| line.size/Utils::screenWidth() + 1 }.inject(0, :+)
    end

    # Utils::locationByUniqueStringOrNull(uniquestring)
    def self.locationByUniqueStringOrNull(uniquestring)
        location = `atlas '#{uniquestring}'`.strip
        location.size > 0 ? location : nil
    end

    # Utils::isWeekday()
    def self.isWeekday()
        ![6, 0].include?(Time.new.wday)
    end

    # Utils::isWeekend()
    def self.isWeekend()
        !Utils::isWeekday()
    end

    # Utils::getLocalTimeZone()
    def self.getLocalTimeZone()
        `date`.strip[-3 , 3]
    end

    # Utils::unixtimeAtComingMidnightAtGivenTimeZone(timezone)
    def self.unixtimeAtComingMidnightAtGivenTimeZone(timezone)
        supportedTimeZones = ["BST", "GMT"]
        if !supportedTimeZones.include?(timezone) then
            raise "error: 7CB8000B-7896-4F61-89ED-89C12E009EE6 ; we are only supporting '#{supportedTimeZones}' and you provided #{timezone}"
        end
        DateTime.parse("#{(DateTime.now.to_date+1).to_s} 00:00:00 #{timezone}").to_time.to_i
    end

    # Utils::datesSinceLastSaturday()
    def self.datesSinceLastSaturday()
        dateIsSaturday = lambda{|date| Date.parse(date).to_time.wday == 6}
        (0..6)
            .map{|i| Utils::nDaysInTheFuture(-i) }
            .reduce([]){|days, day|
                if days.none?{|d| dateIsSaturday.call(d) } then
                    days + [day]
                else
                    days
                end
            }
    end

    # Utils::sanitiseStringForFilenaming(str)
    def self.sanitiseStringForFilenaming(str)
        str
            .gsub(":", "-")
            .gsub("/", "-")
            .gsub("'", "")
    end

    # Utils::codeTrace()
    def self.codeTrace()
        trace = []
        Find.find(File.dirname(__FILE__)) do |location|
            next if !File.file?(location)
            next if location[-3, 3] != ".rb"
            trace << Digest::SHA1.hexdigest(IO.read(location))
        end
        Digest::SHA1.hexdigest(trace.join(":"))
    end

    # Utils::copyFileToBinTimeline(location)
    def self.copyFileToBinTimeline(location)
        return if !File.exists?(location)
        directory = "/Users/pascal/x-space/bin-timeline/#{Time.new.strftime("%Y%m")}/#{Time.new.strftime("%Y%m%d-%H%M%S-%6N")}"
        FileUtils.mkpath(directory)
        FileUtils.cp(location, directory)
    end

    # ----------------------------------------------------

    # Utils::pecoStyleSelectionOrNull(lines)
    def self.pecoStyleSelectionOrNull(lines)
        lines  = [""] + lines
        line = `echo '#{lines.join("\n")}' | /usr/local/bin/peco`.strip
        return line if line.size > 0
        nil
    end

    # Utils::ncurseSelection1410(lambda1, lambda2)
    # lambda1: pattern: String -> Array[String]
    # lambda2: string:  String -> Object or null
    def self.ncurseSelection1410(lambda1, lambda2)

        windowUpdate = lambda { |win, strs|
            win.setpos(0,0)
            strs.each{|str|
                win.deleteln()
                win << (str + "\n")
            }
            win.refresh
        }

        Curses::init_screen
        # Initializes a standard screen. At this point the present state of our terminal is saved and the alternate screen buffer is turned on

        Curses::noecho
        # Disables characters typed by the user to be echoed by Curses.getch as they are typed.

        inputString = ""
        inputString_lastModificationUnixtime = nil
        currentLines = []

        win1 = Curses::Window.new(1, Utils::screenWidth(), 0, 0)
        win2 = Curses::Window.new(Utils::screenHeight()-1, Utils::screenWidth(), 1, 0)

        win1.refresh
        win2.refresh

        # windowUpdate.call(win1, ["line1"])
        # windowUpdate.call(win2, ["line3", "line4"])

        windowUpdate.call(win1, ["-> "])

        thread1 = Thread.new {
            lastSearchedForString = nil
            loop {
                if inputString_lastModificationUnixtime.nil? then
                    sleep 0.1
                    next
                end
                if (Time.new.to_f - inputString_lastModificationUnixtime) < 0.5 then
                    sleep 0.1
                    next
                end
                if inputString.length < 3 then
                    sleep 0.1
                    next
                end
                if !lastSearchedForString.nil? and lastSearchedForString == inputString then
                    sleep 0.1
                    next
                end
                lastSearchedForString = inputString
                currentLines = lambda1.call(inputString)
                windowUpdate.call(win2, currentLines)
                windowUpdate.call(win1, ["-> #{inputString}"])
            }
        }

        loop {
            char = win1.getch.to_s # Reads and return a character non blocking

            next if char.size == 0

            if char == '127' then
                # delete
                next if inputString.length == 0
                inputString = inputString[0, inputString.length-1]
                inputString_lastModificationUnixtime = Time.new.to_f
                windowUpdate.call(win1, ["-> #{inputString}"])
                next
            end

            if char == '10' then
                # enter
                break
            end

            inputString = inputString + char
            inputString_lastModificationUnixtime = Time.new.to_f
            windowUpdate.call(win1, ["-> #{inputString}"])
        }

        thread1.terminate

        win1.close
        win2.close

        Curses::close_screen # this method restore our terminal's settings

        # -----------------------------------------------------------------------

        line = LucilleCore::selectEntityFromListOfEntitiesOrNull("selection", lambda1.call(inputString))
        return nil if line.nil?
        lambda2.call(line) # this returns an object or null
    end

    # ----------------------------------------------------

    # Utils::levenshteinDistance(s, t)
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

    # Utils::stringDistance1(str1, str2)
    def self.stringDistance1(str1, str2)
        # This metric takes values between 0 and 1
        return 1 if str1.size == 0
        return 1 if str2.size == 0
        Utils::levenshteinDistance(str1, str2).to_f/[str1.size, str2.size].max
    end

    # Utils::stringDistance2(str1, str2)
    def self.stringDistance2(str1, str2)
        # We need the smallest string to come first
        if str1.size > str2.size then
            str1, str2 = str2, str1
        end
        diff = str2.size - str1.size
        (0..diff).map{|i| Utils::levenshteinDistance(str1, str2[i, str1.size]) }.min
    end

    # ----------------------------------------------------

    # Utils::selectLinesUsingInteractiveInterface(lines) : Array[String]
    def self.selectLinesUsingInteractiveInterface(lines)
        # Some lines break peco, so we need to be a bit clever here...
        linesX = lines.map{|line|
            {
                "line"     => line,
                "announce" => line.gsub("(", "").gsub(")", "").gsub("'", "").gsub('"', "") 
            }
        }
        announces = linesX.map{|i| i["announce"] } 
        selected = `echo '#{([""]+announces).join("\n")}' | /usr/local/bin/peco`.split("\n")
        selected.map{|announce| 
            linesX.select{|i| i["announce"] == announce }.map{|i| i["line"] }.first 
        }
        .compact
    end

    # Utils::selectLineOrNullUsingInteractiveInterface(lines) : String
    def self.selectLineOrNullUsingInteractiveInterface(lines)

        # Temporary measure to remove stress on Utils::selectLinesUsingInteractiveInterface / peco after 
        # we added the videos from video stream
        lines = lines.reject{|line| line.include?('.mkv') }
        
        lines = Utils::selectLinesUsingInteractiveInterface(lines)
        if lines.size == 0 then
            return nil
        end
        if lines.size == 1 then
            return lines[0]
        end
        LucilleCore::selectEntityFromListOfEntitiesOrNull("select", lines)
    end

    # Utils::selectOneObjectOrNullUsingInteractiveInterface(items, toString = lambda{|item| item })
    def self.selectOneObjectOrNullUsingInteractiveInterface(items, toString = lambda{|item| item })
        lines = items.map{|item| toString.call(item) }
        line = Utils::selectLineOrNullUsingInteractiveInterface(lines)
        return nil if line.nil?
        items
            .select{|item| toString.call(item) == line }
            .first
    end


    # ----------------------------------------------------

    # Utils::fsck()
    def self.fsck()
        Anniversaries::anniversaries().each{|item|
            puts Anniversaries::toString(item)
        }
        Calendar::items().each{|item|
            puts Calendar::toString(item)
        }
        Waves::items().each{|item|
            puts Waves::toString(item)
            status = CoreData5::fsck(item["atom"])
            raise "[error: cfda30da-73a6-4ad9-a3e4-23ed1a2cbc76, #{item}, #{item["atom"]}]" if !status
        }
        TxFloats::items().each{|item|
            puts TxFloats::toString(item)
            status = CoreData5::fsck(item["atom"])
            raise "[error: 0dbec1f7-6c22-4fa2-b288-300bb95b8bba, #{item}, #{item["atom"]}]" if !status
        }
        Mx49s::items().each{|item|
            puts Mx49s::toString(item)
            status = CoreData5::fsck(item["atom"])
            raise "[error: d9154d97-9bf6-43bb-9517-12c8a9d34509, #{item}, #{item["atom"]}]" if !status
        }
        Mx51s::items().each{|item|
            puts Mx51s::toString(item)
            status = CoreData5::fsck(item["atom"])
            raise "[error: f6d0341c-7636-4fe8-93dd-9d0968760f1f, #{item}, #{item["atom"]}]" if !status
        }
        Nx50s::nx50s().each{|item|
            puts Nx50s::toString(item)
            status = CoreData5::fsck(item["atom"])
            raise "[error: bf252b78-6341-4715-ae52-931f3eed0d9d, #{item}, #{item["atom"]}]" if !status   
        }
    end
end
