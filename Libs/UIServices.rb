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

    # NS16sOperator::ns16s(domain)
    def self.ns16s(domain)
        ns16s = [
            DetachedRunning::ns16s(),
            Anniversaries::ns16s(),
            Calendar::ns16s(),
            Fitness::ns16s(),
            Nx31s::ns16s(),
            PriorityFile::ns16OrNull("/Users/pascal/Desktop/Priority.txt"),
            Waves::ns16s(),
            Inbox::ns16s(),
            DrivesBackups::ns16s(),
            Work::ns16s(),
            Nx50s::ns16s(domain),

        ]
            .flatten
            .compact
            .select{|item| item["domain"].nil? or (item["domain"]["uuid"] == domain["uuid"]) }
            .select{|item| DoNotShowUntil::isVisible(item["uuid"]) }


        # If it exists we maintain isRunningWorkC7DB is second position
        if ns16s.size >= 2 and ns16s[0]["isRunningWorkC7DB"] then
            ns16s = [ns16s[1]] + [ns16s[0]] + ns16s.drop(2) 
        end

        ns16s
    end
end

class UIServices

    # UIServices::mainMenuCommands()
    def self.mainMenuCommands()
        "inbox: <line> | wave | ondate | calendar item | Nx50 | waves | ondates | calendar | Nx50s | anniversaries | search | nyx-make"
    end

    # UIServices::mainMenuInterpreter(command)
    def self.mainMenuInterpreter(command)

        if command.start_with?("inbox: ") then
            description = command[6, command.size].strip
            item = {
                "uuid"        => SecureRandom.uuid,
                "unixtime"    => Time.new.to_i,
                "description" => description
            }
            puts JSON.pretty_generate(item)
            BTreeSets::set(nil, "e1a10102-9e16-4ae9-af66-1a72bae89df2", item["uuid"], item)
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
            nx50 = LucilleCore::selectEntityFromListOfEntitiesOrNull("nx50", CoreDataTx::getObjectsBySchema("Nx50"), lambda {|nx50| Nx50s::toString(nx50) })
            return if nx50.nil?
            Nx50s::access(nx50)
        end

        if Interpreting::match("search", command) then
            Search::search()
        end

        if Interpreting::match("nyx-make", command) then
            system("/Users/pascal/Galaxy/Software/Nyx/x-lucille-maker")
        end
    end

    # UIServices::catalystMainInterface()
    def self.catalystMainInterface()

        getNS16s = lambda {
            NS16sOperator::ns16s(Domains::getCurrentDomain())
        }

        processNS16s = lambda {|ns16s|

            accessItem = lambda { |ns16| 
                return if ns16.nil? 
                return if ns16["access"].nil?
                ns16["access"].call()
            }

            system("clear")

            vspaceleft = Utils::screenHeight()-8

            puts ""
            vspaceleft = vspaceleft - 1

            indx15 = -1

            ns16s
                .each_with_index{|ns16, indx|
                    indexStr   = "(#{"%3d" % indx})"
                    announce   = "#{indexStr} #{ns16["announce"]}"
                    break if ((indx > 0) and ((vspaceleft - Utils::verticalSize(announce)) < 0))
                    puts announce
                    vspaceleft = vspaceleft - Utils::verticalSize(announce)
                }

            puts ""

            puts "(#{Domains::getCurrentDomain()["name"]})".green
            puts [
                "(inbox: rt: #{BankExtended::stdRecoveredDailyTimeInHours("Nx60-69315F2A-BE92-4874-85F1-54F140E3B243").round(2)})",
                "(waves: rt: #{BankExtended::stdRecoveredDailyTimeInHours("WAVES-A81E-4726-9F17-B71CAD66D793").round(2)})",
                "(work: rt: #{BankExtended::stdRecoveredDailyTimeInHours("WORK-E4A9-4BCD-9824-1EEC4D648408").round(2)})",
                "(Nx50s: rt: #{BankExtended::stdRecoveredDailyTimeInHours("Nx50s-14F461E4-9387-4078-9C3A-45AE08205CA7").round(2)}, #{CoreDataTx::getObjectsBySchema("Nx50").size} items, done: today: #{Nx50s::completionLogSize(1)}, week: #{Nx50s::completionLogSize(7)}, month: #{Nx50s::completionLogSize(30)})"
            ].join(" ").yellow

            if !ns16s.empty? then
                puts "top : .. | [] (Priority.txt) | done | domain | <datecode> | <n> | select <n> | done <n> | hide <n> <datecode> | exit".yellow
            end
            puts UIServices::mainMenuCommands().yellow

            command = LucilleCore::askQuestionAnswerAsString("> ")

            return "ns:loop" if command == ""

            # -- listing -----------------------------------------------------------------------------

            if Interpreting::match("..", command) then
                accessItem.call(ns16s[0])
                return "ns:loop"
            end

            if Interpreting::match("[]", command) then
                ns16 = ns16s[0]
                return "ns:loop" if ns16.nil? 
                return "ns:loop" if ns16["[]"].nil?
                ns16["[]"].call()
                return "ns:loop"
            end

            if Interpreting::match("expose", command) then
                ns16 = ns16s[0]
                return "ns:loop" if ns16.nil? 
                puts JSON.pretty_generate(ns16)
                LucilleCore::pressEnterToContinue()
                return "ns:loop"
            end

            if Interpreting::match("done", command) then
                ns16 = ns16s[0]
                return "ns:loop" if ns16.nil? 
                return "ns:loop" if ns16["done"].nil?
                ns16["done"].call()
                return "ns:loop"
            end

            if Interpreting::match("domain", command) then
                ns16 = ns16s[0]
                return "ns:loop" if ns16.nil?
                domain = Domains::selectDomainOrNull()
                Domains::setDomainForItem(ns16["uuid"], domain)
                return "ns:loop"
            end

            if (unixtime = Utils::codeToUnixtimeOrNull(command.gsub(" ", ""))) then
                ns16 = ns16s[0]
                return "ns:loop" if ns16.nil? 
                DoNotShowUntil::setUnixtime(ns16["uuid"], unixtime)
                puts "Hidden until: #{Time.at(unixtime).to_s}"
                return "ns:loop"
            end

            if (ordinal = Interpreting::readAsIntegerOrNull(command)) then
                accessItem.call(ns16s[ordinal])
                return "ns:loop"
            end

            if Interpreting::match("select *", command) then
                _, ordinal = Interpreting::tokenizer(command)
                ordinal = ordinal.to_i
                accessItem.call(ns16s[ordinal])
                return "ns:loop"
            end

            if Interpreting::match("done *", command) then
                _, ordinal = Interpreting::tokenizer(command)
                ordinal = ordinal.to_i
                ns16 = ns16s[ordinal]
                return "ns:loop" if ns16.nil?
                return "ns:loop" if ns16["done"].nil?
                ns16["done"].call()
                return "ns:loop"
            end

            if Interpreting::match("hide * *", command) then
                _, ordinal, datecode = Interpreting::tokenizer(command)
                ordinal = ordinal.to_i
                ns16 = ns16s[ordinal]
                return "ns:loop" if ns16.nil?
                unixtime = Utils::codeToUnixtimeOrNull(datecode)
                return "ns:loop" if unixtime.nil?
                DoNotShowUntil::setUnixtime(ns16["uuid"], unixtime)
                return "ns:loop"
            end

            if Interpreting::match("exit", command) then
                return "ns:exit"
            end

            UIServices::mainMenuInterpreter(command)

            "ns:loop"
        }

        loop {
            ns16s = getNS16s.call()
            status = processNS16s.call(ns16s)
            raise "error: 2681e316-4a5b-447f-a822-1820355fb0e5" if !["ns:loop", "ns:exit"].include?(status)
            break if status == "ns:exit"
        }
    end
end
