# encoding: UTF-8

# ------------------------------------------------------------------------------------------

class Interpreters

    # Interpreters::listingCommands()
    def self.listingCommands()
        "[listing] .. | <n> | <datecode> | hide <n> <datecode> | expose"
    end

    # Interpreters::listingInterpreter(store, command)
    def self.listingInterpreter(store, command)

        # The case <n> should hve already been captured by UIServices

        # The case [] should have already been caputred by UIServices

        if (unixtime = Utils::codeToUnixtimeOrNull(command.gsub(" ", ""))) then
            ns16 = store.getDefault()
            return if ns16.nil? 
            DoNotShowUntil::setUnixtime(ns16["uuid"], unixtime)
            puts "Hidden until: #{Time.at(unixtime).to_s}"
        end

        if Interpreting::match("hide * *", command) then
            _, ordinal, datecode = Interpreting::tokenizer(command)
            ordinal = ordinal.to_i
            ns16 = store.get(ordinal)
            return if ns16.nil?
            unixtime = Utils::codeToUnixtimeOrNull(datecode)
            return if unixtime.nil?
            DoNotShowUntil::setUnixtime(ns16["uuid"], unixtime)
        end

        if Interpreting::match("expose", command) then
            ns16 = store.getDefault()
            return if ns16.nil? 
            puts JSON.pretty_generate(ns16)
            LucilleCore::pressEnterToContinue()
        end
    end

    # Interpreters::mainMenuCommands()
    def self.mainMenuCommands()
        "[general] Nx08 | Nx25 | float | wave | ondate | calendar item | anniversary | Nx50 | Nx51 | vector (work wave) | Nx61 (work floatings) | waves | ondates | calendar | Nx50s | anniversaries | search | fsck | >> | nyx"
    end

    # Interpreters::mainMenuInterpreter(command)
    def self.mainMenuInterpreter(command)

        if command.start_with?("in:") then
            item = Nx08s::interactivelyIssueNewOrNull()
            return if item.nil?
            JSON.pretty_generate(item)
        end

        if Interpreting::match("float", command) then
            item = NxFloats::interactivelyCreateNewOrNull()
            return if item.nil?
            JSON.pretty_generate(item)
        end

        if Interpreting::match("wave", command) then
            item = Waves::issueNewWaveInteractivelyOrNull()
            return if item.nil?
            JSON.pretty_generate(item)
        end

        if Interpreting::match("wave", command) then
            item = Vectors::issueNewWaveInteractivelyOrNull()
            return if item.nil?
            JSON.pretty_generate(item)
        end

        if Interpreting::match("ondate", command) then
            item = NxOnDate::interactivelyIssueNewOrNull()
            return if item.nil?
            JSON.pretty_generate(item)
        end

        if Interpreting::match("calendar item", command) then
            item = Calendar::interactivelyIssueNewCalendarItem()
            return if item.nil?
            JSON.pretty_generate(item)
        end

        if Interpreting::match("Nx25", command) then
            item = Nx25s::interactivelyIssueNewOrNull()
            return if item.nil?
            puts JSON.pretty_generate(item)
        end

        if Interpreting::match("Nx50", command) then
            item = Nx50s::interactivelyCreateNewOrNull()
            return if item.nil?
            puts JSON.pretty_generate(item)
        end

        if Interpreting::match("Nx51", command) then
            item = Nx51s::interactivelyCreateNewOrNull()
            return if item.nil?
            puts JSON.pretty_generate(item)
        end

        if command == "Nx61" then
            item = Nx61s::interactivelyIssueNewOrNull()
            return if item.nil?
            puts JSON.pretty_generate(item)
        end

        if Interpreting::match("anniversary", command) then
            item = Anniversaries::issueNewAnniversaryOrNullInteractively()
            return if item.nil?
            JSON.pretty_generate(item)
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
            loop {
                nx50 = LucilleCore::selectEntityFromListOfEntitiesOrNull("nx50", nx50s, lambda {|nx50| Nx50s::toString(nx50) })
                return if nx50.nil?
                Nx50s::run(nx50)
            }
        end

        if Interpreting::match(">>", command) then
            key = "4b23af4b-4536-44f6-a85a-d4e8cb320b30"
            Nx50s::nx50s().each{|nx50|

                next if KeyValueStore::flagIsTrue(nil, "#{key}:#{nx50["uuid"]}")

                nxball = NxBalls::makeNxBall([nx50["uuid"]])

                Nx50s::accessContent(nx50)

                command = LucilleCore::askQuestionAnswerAsString("#{Nx50s::toString(nx50).green} (>> (done), landing, skip (default), exit) : ")

                NxBalls::closeNxBall(nxball, false)

                if command == ">>" then
                    Nx50s::complete(nx50)
                end

                if command == "landing" then
                    Nx50s::run(nx50)
                end

                if command == "exit" then
                    break
                end

                KeyValueStore::setFlagTrue(nil, "#{key}:#{nx50["uuid"]}")
            }
        end

        if Interpreting::match("search", command) then
            Search::search()
        end

        if Interpreting::match("fsck", command) then
            Fsck::fsck()
        end

        if Interpreting::match("nyx", command) then
            system("/Users/pascal/Galaxy/Software/Nyx/nyx")
        end
    end
end
