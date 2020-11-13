
# encoding: UTF-8

class Miscellaneous

    # Miscellaneous::catalystDataCenterFolderpath()
    def self.catalystDataCenterFolderpath()
        "/Users/pascal/Galaxy/DataBank/Catalyst"
    end

    # Miscellaneous::l22()
    def self.l22()
        "#{Time.new.strftime("%Y%m%d-%H%M%S-%6N")}"
    end

    # Miscellaneous::isDateTime_UTC_ISO8601(datetime)
    def self.isDateTime_UTC_ISO8601(datetime)
        DateTime.parse(datetime).to_time.utc.iso8601 == datetime
    end

    # Miscellaneous::onScreenNotification(title, message)
    def self.onScreenNotification(title, message)
        title = title.gsub("'","")
        message = message.gsub("'","")
        message = message.gsub("[","|")
        message = message.gsub("]","|")
        command = "terminal-notifier -title '#{title}' -message '#{message}'"
        system(command)
    end

    # Miscellaneous::levenshteinDistance(s, t)
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

    # Miscellaneous::nyxStringDistance(str1, str2)
    def self.nyxStringDistance(str1, str2)
        # This metric takes values between 0 and 1
        return 1 if str1.size == 0
        return 1 if str2.size == 0
        Miscellaneous::levenshteinDistance(str1, str2).to_f/[str1.size, str2.size].max
    end

    # Miscellaneous::getNewValueEveryNSeconds(uuid, n)
    def self.getNewValueEveryNSeconds(uuid, n)
      Digest::SHA1.hexdigest("6bb2e4cf-f627-43b3-812d-57ff93012588:#{uuid}:#{(Time.new.to_f/n).to_i.to_s}")
    end

    # Miscellaneous::screenWidth()
    def self.screenWidth()
        `/usr/bin/env tput cols`.to_i
    end

    # Miscellaneous::horizontalRule()
    def self.horizontalRule()
      puts "-" * (Miscellaneous::screenWidth()-1)
    end

    # Miscellaneous::fileByFilenameIsSafelyOpenable(filename)
    def self.fileByFilenameIsSafelyOpenable(filename)
        safelyOpeneableExtensions = [".txt", ".jpg", ".jpeg", ".png", ".eml", ".webloc", ".pdf"]
        safelyOpeneableExtensions.any?{|extension| filename.downcase[-extension.size, extension.size] == extension }
    end

    # Miscellaneous::today()
    def self.today()
        Time.new.to_s[0, 10]
    end

    # Miscellaneous::todayAsLowercaseEnglishWeekDayName()
    def self.todayAsLowercaseEnglishWeekDayName()
        ["sunday", "monday", "tuesday", "wednesday", "thursday", "friday", "saturday"][Time.new.wday]
    end

    # Miscellaneous::nDaysInTheFuture(n)
    def self.nDaysInTheFuture(n)
        (Time.now+86400*n).utc.iso8601[0,10]
    end

    # Miscellaneous::screenHeight()
    def self.screenHeight()
        `/usr/bin/env tput lines`.to_i
    end

    # Miscellaneous::screenWidth()
    def self.screenWidth()
        `/usr/bin/env tput cols`.to_i
    end

    # Miscellaneous::selectDateOfNextNonTodayWeekDay(weekday) #2
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

    # Miscellaneous::codeToUnixtimeOrNull(code)
    def self.codeToUnixtimeOrNull(code)

        return nil if code.nil?
        return nil if code == ""

        # +<weekdayname>
        # +<integer>day(s)
        # +<integer>hour(s)
        # +YYYY-MM-DD
        # +1@12:34

        code = code[1,99].strip

        # <weekdayname>
        # <integer>day(s)
        # <integer>hour(s)
        # YYYY-MM-DD
        # 1@12:34

        localsuffix = Time.new.to_s[-5,5]
        morningShowTime = "07:00:00 #{localsuffix}"
        weekdayNames = ["sunday", "monday", "tuesday", "wednesday", "thursday", "friday", "saturday"]

        if weekdayNames.include?(code) then
            # We have a week day
            weekdayName = code
            date = Miscellaneous::selectDateOfNextNonTodayWeekDay(weekdayName)
            datetime = "#{date} #{morningShowTime}"
            return DateTime.parse(datetime).to_time.to_i
        end

        if code.include?("hour") then
            return Time.new.to_i + code.to_f*3600
        end

        if code.include?("day") then
            return Time.new.to_i + code.to_f*86400
        end

        if code[4,1]=="-" and code[7,1]=="-" then
            return DateTime.parse("#{code} #{morningShowTime}").to_time.to_i
        end

        if code.include?('@') then
            p1, p2 = code.split('@') # 1 12:34
            return DateTime.parse("#{Miscellaneous::nDaysInTheFuture(p1.to_i)[0, 10]} #{p2}:00 #{localsuffix}").to_time.to_i
        end

        nil
    end

    # Miscellaneous::onScreenNotification(title, message)
    def self.onScreenNotification(title, message)
        title = title.gsub("'","")
        message = message.gsub("'","")
        message = message.gsub("[","|")
        message = message.gsub("]","|")
        command = "terminal-notifier -title '#{title}' -message '#{message}'"
        system(command)
    end

    # Miscellaneous::isInteger(str)
    def self.isInteger(str)
        str == str.to_i.to_s
    end

    # Miscellaneous::importFromLucilleInbox()
    def self.importFromLucilleInbox()
        getNextLocationAtTheInboxOrNull = lambda {
            Dir.entries("/Users/pascal/Desktop/Todo-Inbox")
                .reject{|filename| filename[0, 1] == '.' }
                .map{|filename| "/Users/pascal/Desktop/Todo-Inbox/#{filename}" }
                .first
        }
        while (location = getNextLocationAtTheInboxOrNull.call()) do
            if File.basename(location).include?("'") then
                basename2 = File.basename(location).gsub("'", "-")
                location2 = "#{File.dirname(location)}/#{basename2}"
                FileUtils.mv(location, location2)
                next
            end
            quark = Quarks::issueAionFileSystemLocation(location)
            puts JSON.pretty_generate(quark)
            asteroid = Asteroids::issueAsteroidInboxFromQuark(quark)
            puts JSON.pretty_generate(asteroid)
            LucilleCore::removeFileSystemLocation(location)
        end
    end

    # Miscellaneous::openFilepathWithInvite(filepath)
    def self.openFilepathWithInvite(filepath)
        system("open '#{filepath}'")
        LucilleCore::pressEnterToContinue()
    end

    # Miscellaneous::openFilepath(filepath)
    def self.openFilepath(filepath)
        system("open '#{filepath}'")
    end

    # Miscellaneous::editTextSynchronously(text)
    def self.editTextSynchronously(text)
      filename = SecureRandom.hex
      filepath = "/tmp/#{filename}"
      File.open(filepath, 'w') {|f| f.write(text)}
      system("open '#{filepath}'")
      print "> press enter when done: "
      input = STDIN.gets
      IO.read(filepath)
    end

    # Miscellaneous::metricCircle(phase)
    def self.metricCircle(phase)
        Math.sin((Time.new.to_f + phase).to_f/3600)
    end

    # Miscellaneous::applyNextTransformationToFile(filepath)
    def self.applyNextTransformationToFile(filepath)
        content = IO.read(filepath).strip
        content = SectionsType0141::applyNextTransformationToContent(content)
        File.open(filepath, "w"){|f| f.puts(content) }
    end

    # Miscellaneous::pecoStyleSelectionOrNull(lines)
    def self.pecoStyleSelectionOrNull(lines)
        lines  = [""] + lines
        line = `echo '#{lines.join("\n")}' | /usr/local/bin/peco`.strip
        return line if line.size > 0
        nil
    end

    # Miscellaneous::ncurseSelection1410(lambda1, lambda2)
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

        win1 = Curses::Window.new(1, Miscellaneous::screenWidth(), 0, 0)
        win2 = Curses::Window.new(Miscellaneous::screenHeight()-1, Miscellaneous::screenWidth(), 1, 0)

        win1.refresh
        win2.refresh

        # windowUpdate.call(win1, ["line1"])
        # windowUpdate.call(win2, ["line3", "line4"])

        windowUpdate.call(win1, [""])

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
                windowUpdate.call(win1, [inputString])
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
                windowUpdate.call(win1, [inputString])
                next
            end

            if char == '10' then
                # enter
                break
            end

            inputString = inputString + char
            inputString_lastModificationUnixtime = Time.new.to_f
            windowUpdate.call(win1, [inputString])
        }

        thread1.terminate

        win1.close
        win2.close

        Curses::close_screen # this method restore our terminal's settings

        # -----------------------------------------------------------------------

        system("clear")

        line = LucilleCore::selectEntityFromListOfEntitiesOrNull("", currentLines)
        return nil if line.nil?
        lambda2.call(line) # this returns an object or null
    end

end
