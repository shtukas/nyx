# encoding: UTF-8

$ListedNS16s = nil

class UIServices

    # UIServices::servicesFront()
    def self.servicesFront()
        loop {

            ms = LCoreMenuItemsNX1.new()

            ms.item("Anniversaries", lambda { Anniversaries::main() })

            ms.item("Waves", lambda { Waves::main() })

            puts ""

            ms.item("new wave", lambda { Waves::issueNewWaveInteractivelyOrNull() })

            ms.item("new quark", lambda { Quarks::interactivelyIssueNewElbramQuarkOrNull() })

            puts ""

            status = ms.promptAndRunSandbox()
            break if !status
        }
    end

    # UIServices::waveLikeNS16s()
    def self.waveLikeNS16s()
        Anniversaries::ns16s() + Waves::ns16s()
    end

    # UIServices::getDocNetMorningNS16s()
    def self.getDocNetMorningNS16s()
        isWeekday = Utils::isWeekday()
        isDocNetTime = ((Time.new.hour >= 7) and ((isWeekday and Time.new.hour < 10) or (!isWeekday and Time.new.hour < 12)))
        return [] if !isDocNetTime
        [ UIServices::todoFilepathToNS16OrNull(Utils::locationByUniqueStringOrNull("ab25a8f8-0578")) ].compact
    end

    # UIServices::todoFilepathToNS16OrNull(filepath)
    def self.todoFilepathToNS16OrNull(filepath)
        raise "c2f47ddb-c278-4e03-b350-0a204040b224" if filepath.nil? # can happen because some of those filepath are unique string lookups
        filename = File.basename(filepath)
        contents = IO.read(filepath)
        return nil if contents.strip == ""
        hash1 = Digest::SHA1.file(filepath).hexdigest
        announce = "\n#{contents.strip.lines.map{|line| "      #{line}" }.join().green}"

        {
            "uuid"     => hash1,
            "announce" => announce,
            "access"    => lambda { 
                system("open '#{filepath}'")
            },
            "done"     => lambda { },
            "[]"       => lambda {
                contents = IO.read(filepath)
                return if contents.strip == ""
                hash2 = Digest::SHA1.file(filepath).hexdigest
                return if hash1 != hash2
                contents = SectionsType0141::applyNextTransformationToText(contents)
                File.open(filepath, "w"){|f| f.puts(contents)}
                next
            }
        }
    end

    # UIServices::getPriority1NS16s()
    def self.getPriority1NS16s()
        [ UIServices::todoFilepathToNS16OrNull("/Users/pascal/Desktop/Priority 1.txt") ].compact
    end

    # UIServices::getTodoListNS20OrNull()
    def self.getTodoListNS20OrNull()
        filepath = "/Users/pascal/Desktop/Todo.txt"
        ns16 = UIServices::todoFilepathToNS16OrNull(filepath)
        return nil if ns16.nil?
        bankAccount = filepath
        recoveryTime = BankExtended::stdRecoveredDailyTimeInHours(bankAccount)
        {
            "announce"     => File.basename(filepath),
            "recoveryTime" => recoveryTime,
            "ns16s"        => [ns16]
        }
    end

    # UIServices::ns16sAtTheBottomTheNS20Type()
    def self.ns16sAtTheBottomTheNS20Type()
        ns20s = Quarks::ns20s() + [UIServices::getTodoListNS20OrNull()].compact
        ns20s = ns20s.sort{|x1, x2| x1["recoveryTime"] <=> x2["recoveryTime"] }

        ns16representative = ns20s.map{|ns20|
            {
                "uuid"     => SecureRandom.hex,
                "announce" => "(#{"%5.3f" % ns20["recoveryTime"]}) #{ns20["announce"].green}",
                "access"   => nil,
                "done"     => nil
            }
        }

        first = ns20s.first
        others = ns20s.drop(1)
        first["ns16s"].first(3) + ns16representative + first["ns16s"].drop(3)
    end

    # UIServices::ns16s()
    def self.ns16s()
        (DetachedRunning::ns16s() + Calendar::ns16s() + UIServices::getPriority1NS16s() + UIServices::getDocNetMorningNS16s() + UIServices::waveLikeNS16s() + WorkInterface::ns16s() + ns16sAtTheBottomTheNS20Type())
            .select{|item| DoNotShowUntil::isVisible(item["uuid"]) }
    end

    # UIServices::catalystDisplayLoop()
    def self.catalystDisplayLoop()

        loop {

            system("clear")

            status = Anniversaries::dailyBriefingIfNotDoneToday()
            next if status

            vspaceleft = Utils::screenHeight()-4

            items = UIServices::ns16s()

            $ListedNS16s = items.clone

            puts ""
            vspaceleft = vspaceleft - 1

            items.each_with_index{|item, indx|
                announce = "(#{"%3d" % indx}) #{item["announce"]}"
                break if ((indx > 0) and ((vspaceleft - Utils::verticalSize(announce)) < 0))
                puts announce
                vspaceleft = vspaceleft - Utils::verticalSize(announce)
            }

            puts "listing: .. (access top) | select <n> | start (<n>) | done (<n>) | / | new wave | new quark | new work item | no work today | new calendar item".yellow
            puts "top    : [] (Priority.txt) | ++ by an hour | + <weekday> | + <float> <datecode unit> | not today".yellow

            command = LucilleCore::askQuestionAnswerAsString("> ")

            next if command == ""

            # -- listing -----------------------------------------------------------------------------

            if Interpreting::match("..", command) then
                item = items[0]
                next if item.nil? 
                next if item["access"].nil?
                item["access"].call()
            end

            if Interpreting::match("select *", command) then
                _, ordinal = Interpreting::tokenizer(command)
                ordinal = ordinal.to_i
                item = items[ordinal]
                next if item.nil?
                next if item["access"].nil?
                item["access"].call()
            end

            if Interpreting::match("access", command) then
                item = items[0]
                next if item.nil? 
                next if item["access"].nil?
                item["access"].call()
            end

            if Interpreting::match("start *", command) then
                _, ordinal = Interpreting::tokenizer(command)
                ordinal = ordinal.to_i
                item = items[ordinal]
                next if item.nil?
                next if item["access"].nil?
                item["access"].call()
            end

            if Interpreting::match("done", command) then
                item = items[0]
                next if item.nil? 
                next if item["done"].nil?
                item["done"].call()
            end

            if Interpreting::match("done *", command) then
                _, ordinal = Interpreting::tokenizer(command)
                ordinal = ordinal.to_i
                item = items[ordinal]
                next if item.nil?
                next if item["done"].nil?
                item["done"].call()
            end

            if Interpreting::match("/", command) then
                UIServices::servicesFront()
            end

            if Interpreting::match("new wave", command) then
                Waves::issueNewWaveInteractivelyOrNull()
            end

            if Interpreting::match("new quark", command) then
                Quarks::interactivelyIssueNewElbramQuarkOrNull()
            end

            if Interpreting::match("new work item", command) then
                WorkInterface::interactvelyIssueNewItem()
            end

            if Interpreting::match("new calendar item", command) then
                Calendar::interactivelyIssueNewCalendarItem()
            end

            if Interpreting::match("no work today", command) then
                KeyValueStore::setFlagTrue(nil, "865cb030-537a-4af8-b1af-202cff383ea1:#{Utils::today()}")
            end

            # -- top -----------------------------------------------------------------------------

            if Interpreting::match("[]", command) then
                item = items[0]
                next if item.nil? 
                next if item["[]"].nil?
                item["[]"].call()
                next
            end

            if Interpreting::match("not today", command) then
                unixtime = Utils::unixtimeAtComingMidnightAtGivenTimeZone(Utils::getLocalTimeZone())
                DoNotShowUntil::setUnixtime(items[0]["uuid"], unixtime)
            end

            if Interpreting::match("++", command) then
                DoNotShowUntil::setUnixtime(items[0]["uuid"], Time.new.to_i+3600)
            end

            if Interpreting::match("+ *", command) then
                _, weekdayname = Interpreting::tokenizer(command)
                unixtime = Utils::codeToUnixtimeOrNull("+#{weekdayname}")
                next if unixtime.nil?
                item = items[0]
                DoNotShowUntil::setUnixtime(item["uuid"], unixtime)
            end

            if Interpreting::match("+ * *", command) then
                _, amount, unit = Interpreting::tokenizer(command)
                unixtime = Utils::codeToUnixtimeOrNull("+#{amount}#{unit}")
                next if unixtime.nil?
                item = items[0]
                DoNotShowUntil::setUnixtime(item["uuid"], unixtime)
            end

            if Interpreting::match("exit", command) then
                break
            end
        }
    end
end

Thread.new {
    trace = lambda {|items|
        items.map{|item| item["uuid"] }.sort.join(";")
    }
    loop {
        sleep 60
        items = UIServices::ns16s()
        if trace.call(UIServices::ns16s()) != trace.call($ListedNS16s) then
            Utils::onScreenNotification("Catalyst", "New listing items")
        end
    }
}
