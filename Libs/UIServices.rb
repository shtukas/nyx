# encoding: UTF-8

# ------------------------------------------------------------------------------------------

class Fitness
    # Fitness::ns16s()
    def self.ns16s()
        status = JSON.parse(`/Users/pascal/Galaxy/LucilleOS/Binaries/fitness should-show`)
        return [] if !status[0]
        ns16 = {
            "uuid"     => "9d70d5fd-a48c-45f4-a573-a8e357490a97",
            "announce" => "fitness: #{status}",
            "access"   => lambda { system("/Users/pascal/Galaxy/LucilleOS/Binaries/fitness doing") },
            "done"     => lambda { }
        }
        [ns16]
    end
end

class NS16sOperator

    # NS16sOperator::replaceOrPutAtTheEnd(objs, obj)
    def self.replaceOrPutAtTheEnd(objs, obj)
        objs.take_while{|o| o["uuid"] != obj["uuid"] } + [obj] + objs.drop_while{|o| o["uuid"] != obj["uuid"] }.drop(1)
    end

    # NS16sOperator::rotate(items)
    def self.rotate(items)
        items.drop(1) + items.take(1)
    end

    # NS16sOperator::ns16s()
    def self.ns16s()
        items1 = UIServices::priorityNS16s()

        items2 = JSON.parse(KeyValueStore::getOrDefaultValue(nil, "ad4508cf-d3c6-4bfd-b64f-45fd0b86c2b6", "[]"))
        items2 = UIServices::nonPriorityNS16s().reduce(items2){|present, incoming|
            NS16sOperator::replaceOrPutAtTheEnd(present, incoming)
        }
        # Note one thing that we somehow need to ensure is that all elements in items2 are fresh, meaning have been actually replaced to carry the right lambdas
        items2 = items2.select{|item| item["access"].class.to_s != "String" }
        items2 = items2.select{|item| DoNotShowUntil::isVisible(item["uuid"]) }  
        KeyValueStore::set(nil, "ad4508cf-d3c6-4bfd-b64f-45fd0b86c2b6", JSON.generate(NS16sOperator::rotate(items2)))

        items1 + items2
    end
end

class UIServices

    # UIServices::priorityNS16s()
    def self.priorityNS16s()
        [
            DetachedRunning::ns16s(),
            PriorityFile::ns16OrNull("/Users/pascal/Desktop/Priority Now.txt"),
            Work::ns16s(),
        ]
            .flatten
            .compact
            .select{|item| DoNotShowUntil::isVisible(item["uuid"])}
    end

    # UIServices::nonPriorityNS16s()
    def self.nonPriorityNS16s()
        [
            Nx60Queue::ns16s(),
            Anniversaries::ns16s(),
            Calendar::ns16s(),
            Nx31s::ns16s(),
            Waves::ns16s(),
            Fitness::ns16s(),
            PriorityFile::ns16OrNull("/Users/pascal/Desktop/Priority Evening.txt"),
            Nx50s::ns16s()
        ]
            .flatten
            .compact
            .select{|item| DoNotShowUntil::isVisible(item["uuid"]) }
    end

    # UIServices::ns16s()
    def self.ns16s()
        UIServices::priorityNS16s() + UIServices::nonPriorityNS16s()
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
            ns16s = UIServices::ns16s()
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
                announce   = "#{indexStr} #{item["announce"]}"
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
