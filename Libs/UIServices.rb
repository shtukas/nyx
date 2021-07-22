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

class NS16sOperator

    # NS16sOperator::ns16s()
    def self.ns16s()

        items2 = UIServices::secondaryNS16s()
                    .map {|ns16|
                        if ns16["metric"].nil? then
                            ns16["metric"] = 0.5
                        end
                        ns16
                    }
                    .sort{|n1, n2| n1["metric"] <=> n2["metric"] }

        UIServices::priorityNS16s() + items2 + UIServices::terniaryNS16s()
    end
end

class UIServices

    # UIServices::priorityNS16s()
    def self.priorityNS16s()
        [
            DetachedRunning::ns16s(),
            PriorityFile::ns16OrNull("/Users/pascal/Desktop/Priority Now.txt"),
        ]
            .flatten
            .compact
            .select{|item| DoNotShowUntil::isVisible(item["uuid"])}
    end

    # UIServices::secondaryNS16s()
    def self.secondaryNS16s()
        [
            Nx60Queue::ns16s(),
            Anniversaries::ns16s(),
            Calendar::ns16s(),
            Nx31s::ns16s(),
            Waves::ns16s(),
            Fitness::ns16s(),
            Work::ns16s(),
            Nx50s::ns16sOfScheduleTypes(["indefinite-daily-commitment", "indefinite-weekly-commitment"]),
        ]
            .flatten
            .compact
            .select{|item| DoNotShowUntil::isVisible(item["uuid"]) }
    end

    # UIServices::terniaryNS16s()
    def self.terniaryNS16s()
        [
            PriorityFile::ns16OrNull("/Users/pascal/Desktop/Priority Evening.txt"),
            Nx50s::ns16sOfScheduleTypes(["regular"])
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

    # UIServices::mainMenuCommands()
    def self.mainMenuCommands()
        "new float / wave / ondate / calendar item / Nx50 | floats | waves | ondates | calendar | Nx50s | anniversaries | work-start, work-not-today, work-reset | search | >nyx"
    end

    # UIServices::mainMenuInterpreter(command)
    def self.mainMenuInterpreter(command)
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

        if Interpreting::match("new Nx50", command) then
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

            ns16sfloats = NxFloat::ns16s()

            if ns16sfloats.size > 0 then
                puts ""
                vspaceleft = vspaceleft - 1
                ns16sfloats.each_with_index{|item, indx|
                    indexStr   = "(f:#{indx})"
                    announce   = "#{indexStr} #{item["announce"]}"
                    puts announce.green
                    vspaceleft = vspaceleft - Utils::verticalSize(announce)
                }
            end

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
                puts "top : .. | select (<n>) | done (<n>) | hide <n> | <datecode> | [] | '' (extended menu) | exit".yellow
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
