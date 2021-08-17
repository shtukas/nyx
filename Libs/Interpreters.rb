# encoding: UTF-8

# ------------------------------------------------------------------------------------------

class Interpreters

    # Interpreters::listingCommands()
    def self.listingCommands()
        "[listing] .. | [] (Priority.txt) | done | domain | <datecode> | <n> | select <n> | done <n> | hide <n> <datecode> | expose"
    end

    # Interpreters::listingInterpreter(ns16s, command)
    def self.listingInterpreter(ns16s, command)
        accessItem = lambda { |ns16| 
            return if ns16.nil? 
            return if ns16["access"].nil?
            ns16["access"].call()
        }

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
    end

    # Interpreters::mainMenuCommands()
    def self.mainMenuCommands()
        "[general] inbox: <line> | inbox text | wave | ondate | calendar item | Nx50 | Nx51 | waves | ondates | calendar | Nx50s | Nx51 ops | anniversaries | search | nyx"
    end

    # Interpreters::mainMenuInterpreter(command)
    def self.mainMenuInterpreter(command)



        if command.start_with?("inbox: ") then
            line = command[6, command.size].strip
            InboxLines::issueNewLine(line)
        end

        if command == "inbox text" then
            InboxText::issueNewText()
        end

        if Interpreting::match("wave", command) then
            Waves::issueNewWaveInteractivelyOrNull()
        end

        if Interpreting::match("ondate", command) then
            nx31 = NxOnDate::interactivelyIssueNewOrNull()
            if nx31 then
                puts JSON.pretty_generate(nx31)
            end
        end

        if Interpreting::match("calendar item", command) then
            Calendar::interactivelyIssueNewCalendarItem()
        end

        if Interpreting::match("Nx50", command) then
            nx50 = Nx50s::interactivelyCreateNewOrNull()
            return if nx50.nil?
            puts JSON.pretty_generate(nx50)
            before = Nx50s::nx50s().take_while{|nx| nx["uuid"] != nx50["uuid"] }
            puts "In position #{before.size+1}"
            sleep 1
        end

        if Interpreting::match("Nx51", command) then
            nx51 = Nx51s::interactivelyCreateNewOrNull()
            return if nx51.nil? 
            puts JSON.pretty_generate(nx51)
        end

        if Interpreting::match("ondates", command) then
            NxOnDate::main()
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
            nx50s = Nx50s::nx50s()
            if LucilleCore::askQuestionAnswerAsBoolean("limit to 100 ? ", true) then
                nx50s = nx50s.first(100)
            end
            nx50 = LucilleCore::selectEntityFromListOfEntitiesOrNull("nx50", nx50s, lambda {|nx50| Nx50s::toString(nx50) })
            return if nx50.nil?
            Nx50s::access(nx50)
        end

        if Interpreting::match("Nx51 ops", command) then
            Nx51s::operations()
        end

        if Interpreting::match("search", command) then
            Search::search()
        end

        if Interpreting::match("nyx", command) then
            system("/Users/pascal/Galaxy/Software/Nyx/nyx")
        end
    end
end
