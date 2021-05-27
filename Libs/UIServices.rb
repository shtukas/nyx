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

    # UIServices::ns16s()
    def self.ns16s()
        [
            DetachedRunning::ns16s(),
            Calendar::ns16s(),
            Priority1::ns16OrNull(),
            DocNetTodo::ns16s(),
            Anniversaries::ns16s(),
            Waves::ns16s(),
            WorkInterface::ns16s(),
            Nx50s::ns16s(),
            Projects::ns16s()
        ]
            .flatten
            .compact
            .select{|item| DoNotShowUntil::isVisible(item["uuid"]) }
            .map{|item|
                item["metric-float"] = Metrics::metricDataToFloat(item["metric"])
                item
            }
            .select{|item| item["metric-float"] > 0 }
            .sort{|item1, item2| item1["metric-float"] <=> item2["metric-float"] }
            .reverse
    end

    # UIServices::ns16sToTrace(ns16s)
    def self.ns16sToTrace(ns16s)
        ns16s.first(3).map{|item| item["uuid"] }.join(";")
    end

    # UIServices::catalystDisplayLoop()
    def self.catalystDisplayLoop()

        loop {

            showNumbers = KeyValueStore::flagIsTrue(nil, "b08cad0a-3c7f-42ad-95d6-91f079adb2ba")

            system("clear")

            status = Anniversaries::dailyBriefingIfNotDoneToday()
            next if status

            vspaceleft = Utils::screenHeight()-7

            items = UIServices::ns16s()

            $NS16sTrace = UIServices::ns16sToTrace(items)

            puts ""

            items.each_with_index{|item, indx|
                indexStr   = "(#{"%3d" % indx})"
                x0 = item["metric"][0]
                x1 = item["metric"][1]
                x2 = item["metric"][2]
                if showNumbers then
                    numbersStr = " ( #{x0.ljust(12)}, #{(x1 and x1 > 0) ? "%5.3f" % x1 : "     "}, #{x2 ? "%2d" % x2 : "  "} )"
                else
                    numbersStr = ""
                end

                announce   = "#{indexStr}#{numbersStr} #{item["announce"]}"
                break if ((indx > 0) and ((vspaceleft - Utils::verticalSize(announce)) < 0))
                puts announce
                vspaceleft = vspaceleft - Utils::verticalSize(announce)
            }
            puts "( Nx50s: #{CoreDataTx::getObjectsBySchema("Nx50").size} items )"
            puts "( velocity: done: #{($counterx.doneCount().to_f/7).round(2)}/day, time: #{($counterx.timeCount().to_f/(3600*7)).round(2)} hours/day )"
            puts "top    : [] (Priority.txt) | <datecode>".yellow
            puts "listing: .. (access top) | select / expose / start / done (<n>) | no work today | new wave / quark / work item / project / calendar item | anniversaries | calendar | waves | agents | numbers on/off".yellow

            command = LucilleCore::askQuestionAnswerAsString("> ")

            next if command == ""

            if (unixtime = Utils::codeToUnixtimeOrNull(command.gsub(" ", ""))) then
                item = items[0]
                next if item.nil? 
                DoNotShowUntil::setUnixtime(item["uuid"], unixtime)
            end

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

            if Interpreting::match("expose *", command) then
                _, ordinal = Interpreting::tokenizer(command)
                ordinal = ordinal.to_i
                item = items[ordinal]
                next if item.nil?
                puts JSON.pretty_generate(item)
                LucilleCore::pressEnterToContinue()
                next
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

            if Interpreting::match("new project", command) then
                Projects::interactivelyCreateNewProject()
            end

            if Interpreting::match("new wave", command) then
                Waves::issueNewWaveInteractivelyOrNull()
            end

            if Interpreting::match("new quark", command) then
                Quarks::interactivelyIssueNewQuarkOrNull()
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

            if Interpreting::match("waves", command) then
                Waves::main()
            end

            if Interpreting::match("anniversaries", command) then
                Anniversaries::main()
            end

            if Interpreting::match("calendar", command) then
                Calendar::main()
            end

            if Interpreting::match("agents", command) then
                AirTrafficControl::agents()
                .map{|agent|
                    agent["recoveryTime"] = BankExtended::stdRecoveredDailyTimeInHours(agent["uuid"])
                    agent
                }
                .sort{|a1, a2| a1["recoveryTime"] <=> a2["recoveryTime"] }
                .each{|agent|
                    puts "#{agent["name"].ljust(50)} #{agent["recoveryTime"]}"
                }
                LucilleCore::pressEnterToContinue()
            end

            if Interpreting::match("numbers on", command) then
                KeyValueStore::setFlagTrue(nil, "b08cad0a-3c7f-42ad-95d6-91f079adb2ba")
            end

            if Interpreting::match("numbers off", command) then
                KeyValueStore::setFlagFalse(nil, "b08cad0a-3c7f-42ad-95d6-91f079adb2ba")
            end

            # -- top -----------------------------------------------------------------------------

            if Interpreting::match("[]", command) then
                item = items[0]
                next if item.nil? 
                next if item["[]"].nil?
                item["[]"].call()
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
