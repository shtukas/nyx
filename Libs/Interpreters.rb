# encoding: UTF-8

# ------------------------------------------------------------------------------------------

class Interpreters

    # Interpreters::listingCommands()
    def self.listingCommands()
        "[listing] [] | next | <datecode> | <n> | select <n> | hide <n> <datecode> | expose"
    end

    # Interpreters::listingInterpreter(ns16s, command, priorityFileHash): Boolean # Indicate if was captured
    def self.listingInterpreter(ns16s, command, priorityFileHash)
        selected = lambda { |ns16| 
            return if ns16.nil?
            ns16["run"].call()
        }

        if Interpreting::match("[]", command) then
            return if (priorityFileHash != Digest::SHA1.file("/Users/pascal/Desktop/Priority.txt").hexdigest)
            PriorityFile::applyNextTransformation("/Users/pascal/Desktop/Priority.txt")
        end

        if Interpreting::match("expose", command) then
            ns16 = ns16s[0]
            return if ns16.nil? 
            puts JSON.pretty_generate(ns16)
            LucilleCore::pressEnterToContinue()
        end

        if (unixtime = Utils::codeToUnixtimeOrNull(command.gsub(" ", ""))) then
            ns16 = ns16s[0]
            return if ns16.nil? 
            DoNotShowUntil::setUnixtime(ns16["uuid"], unixtime)
            puts "Hidden until: #{Time.at(unixtime).to_s}"
        end

        if Interpreting::match("select *", command) then
            _, ordinal = Interpreting::tokenizer(command)
            ordinal = ordinal.to_i
            selected.call(ns16s[ordinal])
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
        "[general] inbox: <line> | inbox text | float | wave | ondate | calendar item | anniversary | Nx50 | Nx51 | waves | ondates | calendar | Nx50s | Nx51s | anniversaries | search | nyx"
    end

    # Interpreters::mainMenuInterpreter(command)
    def self.mainMenuInterpreter(command)

        if command.start_with?("inbox: ") then
            line = command[6, command.size].strip
            nx50 = Nx50s::issueNx50UsingLineInteractively(line)
            puts JSON.pretty_generate(nx50)
            puts "Position: #{Nx50s::determineItemPositionOrNull(nx50)}"
        end

        if command == "inbox text" then
            description = LucilleCore::askQuestionAnswerAsString("description: ")
            text = Utils::editTextSynchronously("")
            nx50 = Nx50s::issueNx50UsingDescriptionAndTextInteractively(description, text)
            puts JSON.pretty_generate(nx50)
            puts "Position: #{Nx50s::determineItemPositionOrNull(nx50)}"
        end

        if Interpreting::match("float", command) then
            NxFloats::interactivelyCreateNewOrNull()
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
            puts "Position: #{Nx50s::determineItemPositionOrNull(nx50)}"
        end

        if Interpreting::match("Nx51", command) then
            nx51 = Nx51s::interactivelyCreateNewOrNull()
            return if nx51.nil? 
            puts JSON.pretty_generate(nx51)
        end

        if Interpreting::match("anniversary", command) then
            Anniversaries::issueNewAnniversaryOrNullInteractively()
        end

        if Interpreting::match("ondates", command) then
            NxOnDate::main()
        end

        if Interpreting::match("anniversaries", command) then
            Anniversaries::anniversariesDive()
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
            Nx50s::landing(nx50)
        end

        if Interpreting::match("Nx51s", command) then
            loop {
                system("clear")
                nx51 = Nx51s::selectOneNx51OrNull()
                break if nx51.nil?
                Nx51s::landing(nx51)
            }
        end

        if Interpreting::match("search", command) then
            Search::search()
        end

        if Interpreting::match("nyx", command) then
            system("/Users/pascal/Galaxy/Software/Nyx/nyx")
        end
    end
end
