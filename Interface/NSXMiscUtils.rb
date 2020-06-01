
# encoding: UTF-8

require "/Users/pascal/Galaxy/LucilleOS/Libraries/Ruby-Libraries/KeyValueStore.rb"
=begin
    KeyValueStore::setFlagTrue(repositorylocation or nil, key)
    KeyValueStore::setFlagFalse(repositorylocation or nil, key)
    KeyValueStore::flagIsTrue(repositorylocation or nil, key)

    KeyValueStore::set(repositorylocation or nil, key, value)
    KeyValueStore::getOrNull(repositorylocation or nil, key)
    KeyValueStore::getOrDefaultValue(repositorylocation or nil, key, defaultValue)
    KeyValueStore::destroy(repositorylocation or nil, key)
=end

require "/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/Catalyst/DataPoint.rb"
require "/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/Catalyst/Cliques.rb"
require "/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/Catalyst/Starlight.rb"
require "/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/TimePods/TimePods.rb"
require "/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/Todo/Todo.rb"

require 'securerandom'
# SecureRandom.hex    #=> "eb693ec8252cd630102fd0d0fb7c3485"
# SecureRandom.hex(4) #=> "eb693123"
# SecureRandom.uuid   #=> "2d931510-d99f-494a-8c67-87feb05e1594"

class NSXMiscUtils
 
    # NSXMiscUtils::nDaysInTheFuture(n)
    def self.nDaysInTheFuture(n)
        (Time.now+86400*n).utc.iso8601[0,10]
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

    # NSXMiscUtils::codeToUnixtimeOrNull(code)
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
            date = NSXMiscUtils::selectDateOfNextNonTodayWeekDay(weekdayName)
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
            return DateTime.parse("#{NSXMiscUtils::nDaysInTheFuture(p1.to_i)[0, 10]} #{p2}:00 #{localsuffix}").to_time.to_i
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

    # NSXMiscUtils::onScreenNotification(title, message)
    def self.onScreenNotification(title, message)
        title = title.gsub("'","")
        message = message.gsub("'","")
        message = message.gsub("[","|")
        message = message.gsub("]","|")
        command = "terminal-notifier -title '#{title}' -message '#{message}'"
        system(command)
    end

    # NSXMiscUtils::isInteger(str)
    def self.isInteger(str)
        str == str.to_i.to_s
    end

    # NSXMiscUtils::importFromLucilleInbox()
    def self.importFromLucilleInbox()
        getNextLocationAtTheInboxOrNull = lambda {
            Dir.entries("/Users/pascal/Desktop/Lucille-Inbox")
                .reject{|filename| filename[0, 1] == '.' }
                .map{|filename| "/Users/pascal/Desktop/Lucille-Inbox/#{filename}" }
                .first
        }
        while (location = getNextLocationAtTheInboxOrNull.call()) do
            if File.basename(location).include?("'") then
                basename2 = File.basename(location).gsub("'", ",")
                location2 = "#{File.dirname(location)}/#{basename2}"
                FileUtils.mv(location, location2)
                next
            end
            target = DataPoint::locationToFileOrFolderDataPoint(location)
            item = {
                "nyxType"          => "todo-cc6d8717-98cf-4a7c-b14d-2261f0955b37",
                "uuid"             => SecureRandom.uuid,
                "creationUnixtime" => Time.new.to_f,
                "projectname"      => "Inbox",
                "projectuuid"      => "44caf74675ceb79ba5cc13bafa102509369c2b53",
                "description"      => File.basename(location),
                "target"           => target
            }
            puts JSON.pretty_generate(item)
            Nyx::commitToDisk(item)
            LucilleCore::removeFileSystemLocation(location)
        end
    end

    # NSXMiscUtils::startlightNodeBuildAround(node)
    def self.startlightNodeBuildAround(node)

        if LucilleCore::askQuestionAnswerAsBoolean("Would you like to determine startlight parents for '#{StarlightNodes::nodeToString(node)}' ? ") then
            loop {
                puts "Selecting new parent..."
                parent = StarlightMakeAndOrSelectNodeQuest::makeAndOrSelectNodeOrNull()
                if parent.nil? then
                    puts "Did not determine a parent for '#{StarlightNodes::nodeToString(node)}'. Aborting parent determination."
                    break
                end
                StarlightPaths::issuePathFromFirstNodeToSecondNodeOrNull(parent, node)
                break if !LucilleCore::askQuestionAnswerAsBoolean("Would you like to determine a new startlight parents for '#{StarlightNodes::nodeToString(node)}' ? ")
            }
            puts "Completed determining parents for '#{StarlightNodes::nodeToString(node)}'"
        end

        if LucilleCore::askQuestionAnswerAsBoolean("Would you like to build starlight children for '#{StarlightNodes::nodeToString(node)}' ? ") then
            loop {
                puts "Making new child..."
                child = StarlightMakeAndOrSelectNodeQuest::makeAndOrSelectNodeOrNull()
                if child.nil? then
                    puts "Did not make a child for '#{StarlightNodes::nodeToString(node)}'. Aborting child building."
                    break
                end
                puts JSON.pretty_generate(child)
                path = StarlightPaths::issuePathFromFirstNodeToSecondNodeOrNull(node, child)
                puts JSON.pretty_generate(path)
                break if !LucilleCore::askQuestionAnswerAsBoolean("Would you like to build a new startlight child for '#{StarlightNodes::nodeToString(node)}' ? ")
            }
            puts "Completed building children for '#{StarlightNodes::nodeToString(node)}'"
        end

        if LucilleCore::askQuestionAnswerAsBoolean("Would you like to build cliques for '#{StarlightNodes::nodeToString(node)}' ? ") then
            loop {
                puts "Making new clique..."
                clique = Cliques::issueCliqueInteractivelyOrNull(false)
                if clique.nil? then
                    puts "Did not make a clique for '#{StarlightNodes::nodeToString(node)}'. Aborting clique building."
                    break
                end
                puts JSON.pretty_generate(clique)
                claim = StarlightContents::issueClaimGivenNodeAndEntity(node, clique)
                puts JSON.pretty_generate(claim)
                break if !LucilleCore::askQuestionAnswerAsBoolean("Would you like to build a new clique for '#{StarlightNodes::nodeToString(node)}' ? ")
            }
        end

        node
    end

    # NSXMiscUtils::startLightNodeExistingOrNewThenBuildAroundThenReturnNode()
    def self.startLightNodeExistingOrNewThenBuildAroundThenReturnNode()
        node = StarlightUserInterface::selectNodeFromExistingOrCreateOneOrNull()
        if node.nil? then
            puts "Could not determine a Startlight node. Aborting build sequence."
            return
        end
        node = NSXMiscUtils::startlightNodeBuildAround(node)
        node
    end

    # NSXMiscUtils::attachTargetToStarlightNodeExistingOrNew(target)
    def self.attachTargetToStarlightNodeExistingOrNew(target)
        return if target.nil?
        node = StarlightUserInterface::selectNodeFromExistingOrCreateOneOrNull()
        return if node.nil?
        claim = StarlightContents::issueClaimGivenNodeAndEntity(node, target)
        puts JSON.pretty_generate(claim)
    end
end
