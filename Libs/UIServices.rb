# encoding: UTF-8

# ------------------------------------------------------------------------------------------

class Fitness
    # Fitness::ns16s()
    def self.ns16s()
        ns16s = JSON.parse(`/Users/pascal/Galaxy/LucilleOS/Binaries/fitness ns16s`)
        ns16s.map{|ns16|
            ns16["access"] = lambda { system("/Users/pascal/Galaxy/LucilleOS/Binaries/fitness doing") }
            ns16
        }
    end
end

class Todo

    # Todo::ns16s()
    def self.ns16s()
        BTreeSets::values(nil, "e1a10102-9e16-4ae9-af66-1a72bae89df2")
            .sort{|n1, n2| n1["ordinal"] <=> n2["ordinal"] }
            .map{|todo|
                {
                    "uuid"     => todo["uuid"],
                    "announce" => "[todo] (#{"%.3f" % todo["ordinal"]}) #{todo["description"]}".green,
                    "access"   => lambda {
                        if LucilleCore::askQuestionAnswerAsBoolean("done '#{todo["description"]}' ? ") then
                            BTreeSets::destroy(nil, "e1a10102-9e16-4ae9-af66-1a72bae89df2", todo["uuid"])
                        end
                        newordinal = LucilleCore::askQuestionAnswerAsString("new ordinal (empty for nothing): ")
                        return if  newordinal == ""
                        newordinal = newordinal.to_f
                        todo["ordinal"] = newordinal
                        BTreeSets::set(nil, "e1a10102-9e16-4ae9-af66-1a72bae89df2", todo["uuid"], todo)
                    },
                    "done"     => lambda {
                        BTreeSets::destroy(nil, "e1a10102-9e16-4ae9-af66-1a72bae89df2", todo["uuid"])
                    },
                    "metric"   => 0.5
                }

            }
    end
end

class NS16sOperator

    # NS16sOperator::ns16s()
    def self.ns16s()
        items1 = [
            DetachedRunning::ns16s(),
            PriorityFile::ns16OrNull("/Users/pascal/Desktop/Priority Now.txt"),
            Nx60Queue::ns16s(),
            Anniversaries::ns16s(),
            Calendar::ns16s(),
            Nx31s::ns16s(),
            Waves::ns16s(),
            Fitness::ns16s(),
            Work::ns16s(),
            Nx50s::ns16s(),
            Todo::ns16s(),
            NxFloat::ns16s(),
        ]
            .flatten
            .compact
            .select{|item| DoNotShowUntil::isVisible(item["uuid"]) }
            .sort{|n1, n2| n1["metric"] <=> n2["metric"] }
    end

end

class UIServices

    # UIServices::programmableListingDisplay(getItems: Lambda: () -> Array[NS16], processItems: Lambda: Array[NS16] -> Status)
    def self.programmableListingDisplay(getItems, processItems)
        loop {
            items = getItems.call()
            status = processItems.call(items)
            raise "error: 2681e316-4a5b-447f-a822-1820355fb0e5" if !["ns:loop", "ns:exit"].include?(status)
            break if status == "ns:exit"
        }
    end

    # UIServices::mainMenuCommands()
    def self.mainMenuCommands()
        "todo | float | wave | ondate | calendar item | Nx50 | floats | waves | ondates | calendar | Nx50s | anniversaries | work-start | work-not-today | work-reset | search | >nyx"
    end

    # UIServices::mainMenuInterpreter(command)
    def self.mainMenuInterpreter(command)

        if Interpreting::match("todo", command) then
            description = LucilleCore::askQuestionAnswerAsString("description: ")
            ordinal = LucilleCore::askQuestionAnswerAsString("ordinal (empty for next): ")
            if ordinal == '' then
                ordinal = ([1] + BTreeSets::values(nil, "e1a10102-9e16-4ae9-af66-1a72bae89df2").map{|n| n["ordinal"] }).max + 1
            else
                ordinal = ordinal.to_f
            end
            todo = {
                "uuid"        => SecureRandom.uuid,
                "description" => description,
                "ordinal"     => ordinal
            }
            BTreeSets::set(nil, "e1a10102-9e16-4ae9-af66-1a72bae89df2", todo["uuid"], todo)
        end

        if Interpreting::match("float", command) then
            float = NxFloat::interactivelyCreateNewOrNull()
            puts JSON.pretty_generate(float)
        end

        if Interpreting::match("wave", command) then
            Waves::issueNewWaveInteractivelyOrNull()
        end

        if Interpreting::match("ondate", command) then
            nx31 = Nx31s::interactivelyIssueNewOrNull()
            puts JSON.pretty_generate(nx31)
        end

        if Interpreting::match("calendar item", command) then
            Calendar::interactivelyIssueNewCalendarItem()
        end

        if Interpreting::match("Nx50", command) then
            nx50 = Nx50s::interactivelyCreateNewOrNull()
            if nx50 then
                puts JSON.pretty_generate(nx50)
            end
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

        if Interpreting::match("Nx50s", command) then
            ns16 = LucilleCore::selectEntityFromListOfEntitiesOrNull("nx50", Nx50s::ns16sExtended(), lambda {|ns50| ns50["announce"] })
            return if ns16.nil?
            ns16["access"].call()
        end

        if Interpreting::match("work-start", command) then
            DetachedRunning::issueNew2("Work", Time.new.to_i, ["WORK-E4A9-4BCD-9824-1EEC4D648408"])
        end

        if Interpreting::match("work-not-today", command) then
            KeyValueStore::set(nil, "ce621184-51d7-456a-8ad1-20e7d9acb350:#{Utils::today()}", "ns:false")
        end

        if Interpreting::match("work-reset", command) then
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
        getItems1 = lambda {
            ns16s = NS16sOperator::ns16s()
            if ns16s.size>0 and ns16s[0]["announce"]=="" then
                ns16s.shift
            end
            ns16s
        }

        getItems2 = lambda {
            NS16sOperator::ns16s()
        }

        processItems = lambda {|items|

            accessItem = lambda { |item| 
                return if item.nil? 
                return if item["access"].nil?
                item["access"].call()
            }

            system("clear")

            vspaceleft = Utils::screenHeight()-6

            puts ""

            items.each_with_index{|item, indx|
                indexStr   = "(#{"%3d" % indx})"
                announce   = "#{indexStr}#{item["metric"] ? " (#{"%3.2f" % item["metric"]})".red : ""} #{item["announce"]}"
                break if ((indx > 0) and ((vspaceleft - Utils::verticalSize(announce)) < 0))
                puts announce
                vspaceleft = vspaceleft - Utils::verticalSize(announce)
            }

            puts [
                "(waves: rt: #{BankExtended::stdRecoveredDailyTimeInHours("WAVES-A81E-4726-9F17-B71CAD66D793").round(2)}) ",
                "(queue: rt: #{BankExtended::stdRecoveredDailyTimeInHours("Nx60-69315F2A-BE92-4874-85F1-54F140E3B243").round(2)}) ",
                "(Nx50s: rt: #{BankExtended::stdRecoveredDailyTimeInHours("Nx50s-14F461E4-9387-4078-9C3A-45AE08205CA7").round(2)}, #{CoreDataTx::getObjectsBySchema("Nx50").size} items, done: today: #{Nx50s::completionLogSize(1)}, week: #{Nx50s::completionLogSize(7)}, month: #{Nx50s::completionLogSize(30)}) "
            ].join().yellow

            if !items.empty? then
                puts "top : .. | select (<n>) | done (<n>) | hide <n> | <datecode> | exit".yellow
            end
            puts UIServices::mainMenuCommands().yellow

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

            if command.start_with?('f:') and (ordinal = Interpreting::readAsIntegerOrNull(command[2, 99])) then
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
                return "ns:loop" if item.nil? 
                return "ns:loop" if item["[]"].nil?
                item["[]"].call()
                return "ns:loop"
            end

            if Interpreting::match("exit", command) then
                return "ns:exit"
            end

            UIServices::mainMenuInterpreter(command)

            "ns:loop"
        }

        UIServices::programmableListingDisplay(getItems2, processItems)
    end
end
