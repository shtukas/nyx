# encoding: UTF-8

# ------------------------------------------------------------------------------------------

$NS16sTrace = nil

class UIServices

    # UIServices::ns16s()
    def self.ns16s()
        [
            DetachedRunning::ns16s(),
            Calendar::ns16s(),
            Priority1::ns16OrNull(),
            Anniversaries::ns16s(),
            Waves::ns16s(),
            [Work::ns16()],
            Nx50s::ns16s(),
            Projects::ns16s(),
            Nx31s::ns16s()
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

    # UIServices::accessItem(item)
    def self.accessItem(item)
        return if item.nil? 
        return if item["access"].nil?
        system("clear")
        item["access"].call()
    end

    # UIServices::catalystDisplayLoop()
    def self.catalystDisplayLoop()

        loop {

            showNumbers = KeyValueStore::flagIsTrue(nil, "b08cad0a-3c7f-42ad-95d6-91f079adb2ba")

            system("clear")

            status = Anniversaries::dailyBriefingIfNotDoneToday()
            next if status

            vspaceleft = Utils::screenHeight()-6

            items = UIServices::ns16s()

            if items.empty? then
                items = Nx50s::ns16sExtra()
            end 

            $NS16sTrace = UIServices::ns16sToTrace(items)

            puts ""

            items.each_with_index{|item, indx|
                indexStr   = "(#{"%3d" % indx})"
                x0 = item["metric"][0]
                x1 = item["metric"][1]
                if showNumbers then
                    numbersStr = " ( #{x0.ljust(14)}, #{(x1 and x1 > 0) ? "%5.3f" % x1 : "     "} )"
                else
                    numbersStr = ""
                end

                announce   = "#{indexStr}#{numbersStr} #{item["announce"]}"
                break if ((indx > 0) and ((vspaceleft - Utils::verticalSize(announce)) < 0))
                puts announce
                vspaceleft = vspaceleft - Utils::verticalSize(announce)
            }
            puts "( Nx50s: #{CoreDataTx::getObjectsBySchema("Nx50").size} items ; rt: #{BankExtended::stdRecoveredDailyTimeInHours("QUARKS-404E-A1D2-0777E64077BA").round(2)} )"
            puts "listing: new wave / ondate / calendar item / quark / todo / work item / project | ondates | anniversaries | calendar | waves | projects | work | numbers on/off".yellow
            if !items.empty? then
                puts "top    : .. (access top) | select / expose / start / done (<n>) | [] (Priority.txt) | <datecode> | done".yellow
            end

            command = LucilleCore::askQuestionAnswerAsString("> ")

            next if command == ""

            if (unixtime = Utils::codeToUnixtimeOrNull(command.gsub(" ", ""))) then
                item = items[0]
                next if item.nil? 
                DoNotShowUntil::setUnixtime(item["uuid"], unixtime)
            end

            # -- listing -----------------------------------------------------------------------------

            if Interpreting::match("..", command) then
                UIServices::accessItem(items[0])
            end

            if Interpreting::match("select *", command) then
                _, ordinal = Interpreting::tokenizer(command)
                ordinal = ordinal.to_i
                UIServices::accessItem(items[ordinal])
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
                UIServices::accessItem(items[0])
            end

            if Interpreting::match("start *", command) then
                _, ordinal = Interpreting::tokenizer(command)
                ordinal = ordinal.to_i
                UIServices::accessItem(items[ordinal])
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

            if Interpreting::match("new ondate", command) then
                Nx31s::interactivelyIssueNewQuarkOrNull()
            end

            if Interpreting::match("new wave", command) then
                Waves::issueNewWaveInteractivelyOrNull()
            end

           if Interpreting::match("new todo", command) then
                line = LucilleCore::askQuestionAnswerAsString("line (empty to abort) : ")
                return if line == ""
                nx50 = {
                    "uuid"        => SecureRandom.uuid,
                    "schema"      => "Nx50",
                    "unixtime"    => Time.new.to_i,
                    "description" => line,
                    "contentType" => "Line",
                    "payload"     => ""
                }
                puts JSON.pretty_generate(nx50)
                CoreDataTx::commit(nx50)
            end

            if Interpreting::match("new quark", command) then
                Quarks::interactivelyIssueNewQuarkOrNull()
            end

            if Interpreting::match("new work item", command) then
                Work::interactvelyIssueNewItem()
            end

            if Interpreting::match("new calendar item", command) then
                Calendar::interactivelyIssueNewCalendarItem()
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

            if Interpreting::match("projects", command) then
                Projects::main()
            end

            if Interpreting::match("ondates", command) then
                Nx31s::main()
            end

            if Interpreting::match("work", command) then
                Work::main()
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

    # UIServices::peek()
    def self.peek()
        loop {
            items = UIServices::ns16s()
            $NS16sTrace = UIServices::ns16sToTrace(items)
            # This function is to be called from projects, work, etc, sub processes which can consume time
            item = LucilleCore::selectEntityFromListOfEntitiesOrNull("item", items.first(10), lambda{|item| item["announce"] })
            break if item.nil?
            item["access"].call()
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
