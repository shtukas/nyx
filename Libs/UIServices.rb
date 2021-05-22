# encoding: UTF-8

# ------------------------------------------------------------------------------------------

=begin

["time", unixtime, timeInSeconds]
["done", unixtime]

=end

class CounterX
    
    def initialize()
        @data = JSON.parse(KeyValueStore::getOrDefaultValue(nil, "9caea594-40d3-449d-afcf-3f2fe63535b2", '[]'))
    end

    def garbageCollection(data)
        data.select{|item| (Time.new.to_i - item[1]) < 86400*7 } # one week
    end

    def registerTimeInSeconds(timeInSeconds)
        @data << ["time", Time.new.to_i, timeInSeconds]
        @data = garbageCollection(@data)
        KeyValueStore::set(nil, "9caea594-40d3-449d-afcf-3f2fe63535b2", JSON.generate(@data))
    end

    def registerDone()
        @data << ["done", Time.new.to_i]
        @data = garbageCollection(@data)
        KeyValueStore::set(nil, "9caea594-40d3-449d-afcf-3f2fe63535b2", JSON.generate(@data))
    end

    def doneCount()
        @data.select{|item| item[0] == "done" }.count
    end

    def timeCount()
        @data.select{|item| item[0] == "time" }.map{|item| item[2] }.inject(0, :+)
    end
end

$counterx = CounterX.new()

# ------------------------------------------------------------------------------------------

$NS16sTrace = nil

class UIServices

    # UIServices::ns16sAtTheBottomTheNS20Type()
    def self.ns16sAtTheBottomTheNS20Type()
        ns20s = Quarks::ns20s() + [Todos::ns20()]
        ns20s = ns20s.select{|ns20| ns20["ns16s"].size>0 }
        ns20s = ns20s.sort{|x1, x2| x1["recoveryTime"] <=> x2["recoveryTime"] }

        ns16representatives = ns20s.map{|ns20|
            {
                "uuid"     => SecureRandom.hex,
                "metric"   => Metrics::metric("running", nil, nil),
                "announce" => "(#{"%5.3f" % ns20["recoveryTime"]}) #{ns20["announce"].green}",
                "access"   => nil,
                "done"     => nil
            }
        }

        ns16s = (ns20s.map{|ns20| ns20["ns16s"].first(3) } + ns20s.map{|ns20| ns20["ns16s"].drop(3) }).flatten

        ns16s.first(3) + ns16representatives + ns16s.drop(3)
    end

    # UIServices::ns16s()
    def self.ns16s()
        [
            DetachedRunning::ns16s(),
            Calendar::ns16s(),
            TodoFiles::filepathToNS16s("/Users/pascal/Desktop/Priority 1.txt", true),
            TodoFiles::docnetNS16s(),
            Anniversaries::ns16s(),
            Waves::ns16s(),
            WorkInterface::ns16s(),
            Quarks::ns16s(),
            Todos::ns16s()
        ]
            .flatten
            .select{|item| DoNotShowUntil::isVisible(item["uuid"]) }
            .sort{|item1, item2| item1["metric"][3] <=> item2["metric"][3] }
            .reverse
    end

    # UIServices::ns16sToTrace(ns16s)
    def self.ns16sToTrace(ns16s)
        ns16s.first(3).map{|item| item["uuid"] }.join(";")
    end

    # UIServices::catalystDisplayLoop()
    def self.catalystDisplayLoop()

        loop {

            system("clear")

            status = Anniversaries::dailyBriefingIfNotDoneToday()
            next if status

            vspaceleft = Utils::screenHeight()-4

            items = UIServices::ns16s()

            $NS16sTrace = UIServices::ns16sToTrace(items)

            puts (" "*(Utils::screenWidth()-30)) + "done: #{$counterx.doneCount()}, time: #{($counterx.timeCount().to_f/3600).round(2)} hours"
            vspaceleft = vspaceleft - 1

            items.each_with_index{|item, indx|
                announce = "(#{"%3d" % indx}) (#{"%5.3f" % item["metric"][3]}) #{item["announce"]}"
                break if ((indx > 0) and ((vspaceleft - Utils::verticalSize(announce)) < 0))
                puts announce
                vspaceleft = vspaceleft - Utils::verticalSize(announce)
            }

            puts "listing: .. (access top) | select <n> | start (<n>) | done (<n>) | new todo | new wave | new quark | new work item | no work today | new calendar item | anniversaries | calendar | waves".yellow
            puts "top    : [] (Priority.txt) | expose | ++ by an hour | + <weekday> | + <float> <datecode unit> | not today".yellow

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

            if Interpreting::match("new todo", command) then
                Todos::interactivelyMakeNewTodoItem()
            end

            if Interpreting::match("new wave", command) then
                Waves::issueNewWaveInteractivelyOrNull()
            end

            if Interpreting::match("new quark", command) then
                Quarks::interactivelyIssueNewElbramQuarkOrNullAtLowL22()
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

            if Interpreting::match("anniversaries", command) then
                Anniversaries::main()
            end

            if Interpreting::match("calendar", command) then
                Calendar::main()
            end

            if Interpreting::match("waves", command) then
                Waves::main()
            end

            # -- top -----------------------------------------------------------------------------

            if Interpreting::match("expose", command) then
                item = items[0]
                next if item.nil? 
                puts JSON.pretty_generate(item)
                LucilleCore::pressEnterToContinue()
                next
            end

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
    loop {
        sleep 60
        if UIServices::ns16sToTrace(UIServices::ns16s()) != $NS16sTrace then
            Utils::onScreenNotification("Catalyst", "New listing items")
        end
    }
}
