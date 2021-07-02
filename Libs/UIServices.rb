# encoding: UTF-8

# ------------------------------------------------------------------------------------------

class Fitness
    # Fitness::fitnessNs17OrNull()
    def self.fitnessNs17OrNull()
        ratios = JSON.parse(`/Users/pascal/Galaxy/LucilleOS/Binaries/fitness ratios`)

        ns16 = {
            "uuid"     => "9d70d5fd-a48c-45f4-a573-a8e357490a97",
            "announce" => "fitness: #{ratios}",
            "access"   => lambda { system("/Users/pascal/Galaxy/LucilleOS/Binaries/fitness done") },
            "done"     => lambda { }
        }

        {
            "ratio" => ratios.min,
            "ns16s" => [ ns16 ]
        }
    end

    # Fitness::fitnessCompletionRatio()
    def self.fitnessCompletionRatio()
        JSON.parse(`/Users/pascal/Galaxy/LucilleOS/Binaries/fitness ratios`).min
    end
end

class UIServices

    # UIServices::ns17sToNS16s(ns17s)
    def self.ns17sToNS16s(ns17s)
        ns17s.sort{|i1, i2| i1["ratio"] <=> i2["ratio"] }.map{|item| item["ns16s"] }.flatten
    end

    # UIServices::ns16s()
    def self.ns16s()
        [
            DetachedRunning::ns16s(),
            PriorityFile::ns16OrNull("/Users/pascal/Desktop/Priority 1.txt"),
            Work::isWorkTime() ? PriorityFile::ns16OrNull("/Users/pascal/Desktop/Priority Work.txt") : nil,
            Anniversaries::ns16s(),
            Calendar::ns16s(),
            Nx31s::ns16s(),
            Waves::ns16sHighPriority(),
            [Nx50s::getOperationalNS16ByUUIDOrNull("20210525-161532-646669")], # Guardian Jedi
            UIServices::ns17sToNS16s(
                Work::ns17s() + 
                Waves::ns17sLowPriority() + 
                Nx50s::ns17s() + 
                [Fitness::fitnessNs17OrNull()])
        ]
            .flatten
            .compact
            .select{|item| DoNotShowUntil::isVisible(item["uuid"]) }
    end

    # UIServices::programmableListingDisplay(getItems: Lambda: () -> Array[NS16], processItems: Lambda: Array[NS16] -> Status)
    def self.programmableListingDisplay(getItems, processItems)
        loop {
            items = getItems.call()
            status = processItems.call(items)
            raise "error: 2681e316-4a5b-447f-a822-1820355fb0e5" if !["ns:loop", "ns:exit"].include?(status)
            break if status == "ns:exit"
        }
    end

    # UIServices::operationalInterface()
    def self.operationalInterface()
        puts "new float / wave / ondate / calendar item / todo / todo priority / work item | ondates | floats | anniversaries | calendar | waves | work | w+/-/0 | search | ns17s | >nyx".yellow
        command = LucilleCore::askQuestionAnswerAsString("> ")
    
        return if command == ""

        if Interpreting::match("new float", command) then
            float = NxFloat::interactivelyCreateNewOrNull()
            puts JSON.pretty_generate(float)
        end

        if Interpreting::match("new wave", command) then
            Waves::issueNewWaveInteractivelyOrNull()
        end

        if Interpreting::match("new ondate", command) then
            nx31 = Nx31s::interactivelyIssueNewOrNull()
            puts JSON.pretty_generate(nx31)
        end

        if Interpreting::match("new calendar item", command) then
            Calendar::interactivelyIssueNewCalendarItem()
        end

        if Interpreting::match("new todo", command) then
            nx50 = Nx50s::interactivelyCreateNewOrNull()
            if nx50 then
                puts JSON.pretty_generate(nx50)
            end
        end

        if Interpreting::match("new todo priority", command) then
            nx50 = Nx50s::interactivelyCreateNewOrNull()
            if nx50 then
                puts JSON.pretty_generate(nx50)
            else
                exit
            end
            nx50["unixtime"] = ([Time.new.to_i] + CoreDataTx::getObjectsBySchema("Nx50").map{|n| n["unixtime"] }).min - 1
            CoreDataTx::commit(nx50)
        end

        if Interpreting::match("new work item", command) then
            Work::interactvelyIssueNewItem()
        end

        if Interpreting::match("floats", command) then
            puts "floats is not implemented"
            LucilleCore::pressEnterToContinue()
        end

        if Interpreting::match("ondates", command) then
            Nx31s::main()
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

        if Interpreting::match("work", command) then
            Work::main()
        end

        if Interpreting::match("w+", command) then
            KeyValueStore::set(nil, "ce621184-51d7-456a-8ad1-20e7d9acb350:#{Utils::today()}", "ns:true")
        end

        if Interpreting::match("w-", command) then
            KeyValueStore::set(nil, "ce621184-51d7-456a-8ad1-20e7d9acb350:#{Utils::today()}", "ns:false")
        end

        if Interpreting::match("w0", command) then
            KeyValueStore::destroy(nil, "ce621184-51d7-456a-8ad1-20e7d9acb350:#{Utils::today()}")
        end

        if Interpreting::match("search", command) then
            Search::search()
        end

        if Interpreting::match(">nyx", command) then
            system("/Users/pascal/Galaxy/Software/Nyx/x-make-new")
        end
    end

    # UIServices::catalystMainInterface()
    def self.catalystMainInterface()
        getItems = lambda {
            UIServices::ns16s()
        }

        processItems = lambda {|items|

            accessItem = lambda { |item| 
                return if item.nil? 
                return if item["access"].nil?
                item["access"].call()
            }

            system("clear")

            vspaceleft = Utils::screenHeight()-4

            ns16sfloats = NxFloat::ns16s()

            if ns16sfloats.size > 0 then
                puts ""
                vspaceleft = vspaceleft - 1
                ns16sfloats.each_with_index{|item, indx|
                    indexStr   = "(>#{"%2d" % indx})"
                    announce   = "#{indexStr} #{item["announce"]}"
                    puts announce.red
                    vspaceleft = vspaceleft - Utils::verticalSize(announce)
                }
            end

            numbers = (lambda(){
                [
                    [Fitness::fitnessCompletionRatio(), "- Fitness                          : #{Fitness::fitnessCompletionRatio()}"],
                    Work::shouldDisplayWork() ? [Work::todayTimeCompletionRatio(),  "- Work::todayTimeCompletionRatio() : #{Work::todayTimeCompletionRatio().round(2)}"] : nil,
                    [Waves::todayDoneCountRatio(),      "- Waves::todayDoneCountRatio()     : #{Waves::todayDoneCountRatio().round(2)} (done today: #{Bank::valueAtDate("WAVES-DONE-IMPACT-8F82-BFB47E4541A2", Utils::today())}, weekly average: #{Waves::dailyDoneCountAverage()})"],
                    [Nx50s::todayTimeCompletionRatio(), "- Nx50s::todayTimeCompletionRatio(): #{Nx50s::todayTimeCompletionRatio().round(2)} (#{CoreDataTx::getObjectsBySchema("Nx50").size} items; done: today: #{Nx50s::completionLogSize(1)}, week: #{Nx50s::completionLogSize(7)}, month: #{Nx50s::completionLogSize(30)})"]
                ].compact
            }).call()

            showNumbers = KeyValueStore::flagIsTrue(nil, "a7eec665-84ec-4c5f-a37c-3db170788e13")

            if showNumbers then
                vspaceleft = vspaceleft-numbers.size
            end

            puts ""

            items.each_with_index{|item, indx|
                indexStr   = "(#{"%3d" % indx})"
                announce   = "#{indexStr} #{item["announce"]}"
                break if ((indx > 0) and ((vspaceleft - Utils::verticalSize(announce)) < 0))
                puts announce
                vspaceleft = vspaceleft - Utils::verticalSize(announce)
            }

            if showNumbers then
                numbers
                    .sort{|x1, x2| x1[0]<=>x2[0] }
                    .each{|x| puts x[1].yellow }
            end

            if !items.empty? then
                puts "top : .. | select (<n>) | done (<n>) | hide <n> | <datecode> | [] (Priority.txt) | '' (extended menu) |  n+/- | exit".yellow
            end

            command = LucilleCore::askQuestionAnswerAsString("> ")

            return "ns:loop" if command == ""

            if (unixtime = Utils::codeToUnixtimeOrNull(command.gsub(" ", ""))) then
                item = items[0]
                return "ns:loop" if item.nil? 
                DoNotShowUntil::setUnixtime(item["uuid"], unixtime)
                puts "Hidden until: #{Time.at(unixtime).to_s}"
                return "ns:loop"
            end

            # -- listing -----------------------------------------------------------------------------

            if command.start_with?('>') and (ordinal = Interpreting::readAsIntegerOrNull(command[1, 99])) then
                accessItem.call(ns16sfloats[ordinal])
                return "ns:loop"
            end

            if Interpreting::match("..", command) then
                accessItem.call(items[0])
                return "ns:loop"
            end

            if (ordinal = Interpreting::readAsIntegerOrNull(command)) then
                accessItem.call(items[ordinal])
                return "ns:loop"
            end

            if Interpreting::match("select *", command) then
                _, ordinal = Interpreting::tokenizer(command)
                ordinal = ordinal.to_i
                accessItem.call(items[ordinal])
                return "ns:loop"
            end

            if Interpreting::match("done", command) then
                item = items[0]
                return "ns:loop" if item.nil? 
                return "ns:loop" if item["done"].nil?
                item["done"].call()
                return "ns:loop"
            end

            if Interpreting::match("hide *", command) then
                _, ordinal = Interpreting::tokenizer(command)
                ordinal = ordinal.to_i
                item = items[ordinal]
                DoNotShowUntil::setUnixtime(item["uuid"], Time.new.to_i+3600)
                return "ns:loop"
            end

            if Interpreting::match("done *", command) then
                _, ordinal = Interpreting::tokenizer(command)
                ordinal = ordinal.to_i
                item = items[ordinal]
                return "ns:loop" if item.nil?
                return "ns:loop" if item["done"].nil?
                item["done"].call()
                return "ns:loop"
            end

            # -- top -----------------------------------------------------------------------------

            if Interpreting::match("[]", command) then
                item = items[0]
                next if item.nil? 
                next if item["[]"].nil?
                item["[]"].call()
                return "ns:loop"
            end

            if Interpreting::match("''", command) then
                UIServices::operationalInterface()
                return "ns:loop"
            end

            if Interpreting::match("n+", command) then
                KeyValueStore::setFlagTrue(nil, "a7eec665-84ec-4c5f-a37c-3db170788e13")
                return "ns:loop"
            end

            if Interpreting::match("n-", command) then
                KeyValueStore::setFlagFalse(nil, "a7eec665-84ec-4c5f-a37c-3db170788e13")
                return "ns:loop"
            end

            if Interpreting::match("exit", command) then
                return "ns:exit"
            end

            "ns:loop"
        }

        UIServices::programmableListingDisplay(getItems, processItems)
    end
end
