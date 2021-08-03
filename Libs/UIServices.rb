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

    # NS16sOperator::currentDomain()
    def self.currentDomain()
        data = KeyValueStore::getOrNull(nil, "16826a70-3a04-4829-88a1-dbe50b100625")
        if data then
            data = JSON.parse(data)
            if (Time.new.to_i - data[0]) < 3600 then
                return data[1]
            end
        end
        Work::shouldBeRunning() ? Domains::workDomain() : Domains::alexandra()
        Domains::workDomain()
    end

    # NS16sOperator::ns16s()
    def self.ns16s()

        domain = NS16sOperator::currentDomain()

        ns16s = [
            DetachedRunning::ns16s(),
            Anniversaries::ns16s(),
            Calendar::ns16s(),
            Fitness::ns16s(),
            Nx31s::ns16s(),
            PriorityFile::ns16OrNull("/Users/pascal/Desktop/Priority.txt"),
            Waves::ns16s(domain),
            Inbox::ns16s(domain),
            DrivesBackups::ns16s(),
            Work::ns16s(domain),
            Nx50s::ns16s(domain),

        ]
            .flatten
            .compact
            .select{|item| DoNotShowUntil::isVisible(item["uuid"]) }

        return ns16s
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
            line = command[6, command.size].strip
            InboxLines::issueNewLine(line)
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
            NS16sOperator::ns16s()
        }

        processNS16s = lambda {|ns16s|

            accessItem = lambda { |ns16| 
                return if ns16.nil? 
                return if ns16["access"].nil?
                ns16["access"].call()
            }

            system("clear")

            vspaceleft = Utils::screenHeight()-11

            puts ""

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

            puts [
                "(inbox: rt: #{BankExtended::stdRecoveredDailyTimeInHours("Nx60-69315F2A-BE92-4874-85F1-54F140E3B243").round(2)})",
                "(waves: rt: #{BankExtended::stdRecoveredDailyTimeInHours("WAVES-A81E-4726-9F17-B71CAD66D793").round(2)})",
                "(Nx50s: rt: #{BankExtended::stdRecoveredDailyTimeInHours("Nx50s-14F461E4-9387-4078-9C3A-45AE08205CA7").round(2)})",
                "(Nx50s: #{CoreDataTx::getObjectsBySchema("Nx50").size} items, done: today: #{Nx50s::completionLogSize(1)}, week: #{Nx50s::completionLogSize(7)}, month: #{Nx50s::completionLogSize(30)})"
            ].join(" ").yellow

            puts Domains::domains()
                    .map{|domain| "(#{domain["name"]}, rt: #{BankExtended::stdRecoveredDailyTimeInHours(domain["uuid"]).round(2)})" }
                    .join(" ")
                    .yellow

            puts ""

            if !ns16s.empty? then
                puts ".. | [] (Priority.txt) | done | domain | <datecode> | <n> | select <n> | done <n> | hide <n> <datecode> | expose".yellow
            end

            puts UIServices::mainMenuCommands().yellow
            puts "domain overide".yellow

            puts ""

            command = LucilleCore::askQuestionAnswerAsString("> ")

            return if command == ""

            # -- listing -----------------------------------------------------------------------------

            if Interpreting::match("..", command) then
                accessItem.call(ns16s[0])
            end

            if Interpreting::match("[]", command) then
                ns16 = ns16s[0]
                return if ns16.nil? 
                return if ns16["[]"].nil?
                ns16["[]"].call()
            end

            if Interpreting::match("expose", command) then
                ns16 = ns16s[0]
                return if ns16.nil? 
                puts JSON.pretty_generate(ns16)
                LucilleCore::pressEnterToContinue()
            end

            if Interpreting::match("done", command) then
                ns16 = ns16s[0]
                return if ns16.nil? 
                return if ns16["done"].nil?
                ns16["done"].call()

            end

            if Interpreting::match("domain", command) then
                ns16 = ns16s[0]
                return if ns16.nil?
                domain = Domains::selectDomainOrNull()
                return if domain.nil?
                Domains::setDomainForItem(ns16["uuid"], domain)
            end

            if (unixtime = Utils::codeToUnixtimeOrNull(command.gsub(" ", ""))) then
                ns16 = ns16s[0]
                return if ns16.nil? 
                DoNotShowUntil::setUnixtime(ns16["uuid"], unixtime)
                puts "Hidden until: #{Time.at(unixtime).to_s}"
            end

            if (ordinal = Interpreting::readAsIntegerOrNull(command)) then
                accessItem.call(ns16s[ordinal])
            end

            if Interpreting::match("select *", command) then
                _, ordinal = Interpreting::tokenizer(command)
                ordinal = ordinal.to_i
                accessItem.call(ns16s[ordinal])
            end

            if Interpreting::match("done *", command) then
                _, ordinal = Interpreting::tokenizer(command)
                ordinal = ordinal.to_i
                ns16 = ns16s[ordinal]
                return if ns16.nil?
                return if ns16["done"].nil?
                ns16["done"].call()
            end

            if Interpreting::match("hide * *", command) then
                _, ordinal, datecode = Interpreting::tokenizer(command)
                ordinal = ordinal.to_i
                ns16 = ns16s[ordinal]
                return if ns16.nil?
                unixtime = Utils::codeToUnixtimeOrNull(datecode)
                return if unixtime.nil?
                DoNotShowUntil::setUnixtime(ns16["uuid"], unixtime)
            end

            if Interpreting::match("domain override", command) then
                domain = Domains::selectDomainOrNull()
                return if domain.nil?
                KeyValueStore::set(nil, "16826a70-3a04-4829-88a1-dbe50b100625", JSON.generate([Time.new.to_i, domain]))
            end

            UIServices::mainMenuInterpreter(command)
        }

        loop {
            processNS16s.call(getNS16s.call())
        }
    end
end
