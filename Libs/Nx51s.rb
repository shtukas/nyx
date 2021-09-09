# encoding: UTF-8

class Nx51s

    # Nx51s::repositoryFolderPath()
    def self.repositoryFolderPath()
        "/Users/pascal/Galaxy/DataBank/Catalyst/items/Nx51s"
    end

    # Nx51s::commitItemToDisk(item)
    def self.commitItemToDisk(item)
        filename = "#{item["uuid"]}.json"
        filepath = "#{Nx51s::repositoryFolderPath()}/#{filename}"
        File.open(filepath, "w") {|f| f.puts(JSON.pretty_generate(item)) }
    end

    # Nx51s::nx51s()
    def self.nx51s()
        LucilleCore::locationsAtFolder(Nx51s::repositoryFolderPath())
            .select{|location| location[-5, 5] == ".json" }
            .map{|location| JSON.parse(IO.read(location)) }
    end

    # Nx51s::getNx51ByUUIDOrNull(uuid)
    def self.getNx51ByUUIDOrNull(uuid)
        filename = "#{uuid}.json"
        filepath = "#{Nx51s::repositoryFolderPath()}/#{filename}"
        return nil if !File.exists?(filepath)
        JSON.parse(IO.read(filepath))
    end

    # Nx51s::axiomsRepositoryFolderPath()
    def self.axiomsRepositoryFolderPath()
        "/Users/pascal/Galaxy/DataBank/Catalyst/items/Nx51s-axioms"
    end

    # Nx51s::nx51sPerOrdinal()
    def self.nx51sPerOrdinal()
        Nx51s::nx51s()
            .sort{|n1, n2| n1["ordinal"]<=>n2["ordinal"] }
    end

    # Nx51s::interactivelyCreateNewOrNull()
    def self.interactivelyCreateNewOrNull()
        uuid = LucilleCore::timeStringL22()

        unixtime     = Time.new.to_f

        description = LucilleCore::askQuestionAnswerAsString("description (empty for abort): ")
        if description == "" then
            return nil
        end

        axiomId = NxAxioms::interactivelyCreateNewAxiom_EchoIdOrNull(Nx51s::axiomsRepositoryFolderPath(), LucilleCore::timeStringL22())

        ordinal = Nx51s::decideOrdinal(description)

        item = {
              "uuid"         => uuid,
              "unixtime"     => Time.new.to_i,
              "description"  => description,
              "ordinal"      => ordinal,
              "axiomId"      => axiomId
            }

        Nx51s::commitItemToDisk(item)

        item
    end

    # Nx51s::minusOneUnixtime()
    def self.minusOneUnixtime()
        items = Nx51s::nx51s()
        return Time.new.to_i if items.empty?
        items.map{|item| item["unixtime"] }.min - 1
    end

    # Nx51s::interactivelyDetermineNewItemOrdinal()
    def self.interactivelyDetermineNewItemOrdinal()
        system('clear')
        items = Nx51s::nx51s()
        return 1 if items.empty?
        items.each{|item|
            puts "- #{Nx51s::toString(item)}"
        }
        LucilleCore::askQuestionAnswerAsString("ordinal: ").to_f
    end

    # Nx51s::destroy(item)
    def self.destroy(item)
        filename = "#{item["uuid"]}.json"
        filepath = "#{Nx51s::repositoryFolderPath()}/#{filename}"
        return if !File.exists?(filepath)
        FileUtils.rm(filepath)
    end

    # --------------------------------------------------
    # Operations

    # Nx51s::toString(nx51)
    def self.toString(nx51)
        "[nx51] (#{"%6.3f" % nx51["ordinal"]}) #{nx51["description"]}"
    end

    # Nx51s::complete(nx51)
    def self.complete(nx51)
        NxAxioms::destroy(Nx51s::axiomsRepositoryFolderPath(), nx51["axiomId"]) # function accepts null ids
        Nx51s::destroy(nx51)
    end

    # Nx51s::getNextOrdinal()
    def self.getNextOrdinal()
        (([1]+Nx51s::nx51s().map{|nx51| nx51["ordinal"] }).max + 1).floor
    end

    # Nx51s::decideOrdinal(description)
    def self.decideOrdinal(description)
        system("clear")
        puts ""
        puts description.green
        puts ""
        Nx51s::nx51s()
            .sort{|n1, n2| n1["ordinal"] <=> n2["ordinal"] }
            .each{|nx51|
                puts "(#{"%7.3f" % nx51["ordinal"]}) #{Nx51s::toString(nx51)}"
            }
        puts ""
        ordinal = LucilleCore::askQuestionAnswerAsString("ordinal (empty for last position): ")
        if ordinal == "" then
            Nx51s::getNextOrdinal()
        else
            ordinal.to_f
        end
    end

    # Nx51s::selectOneNx51OrNull()
    def self.selectOneNx51OrNull()
        nx51s = Nx51s::nx51sPerOrdinal()
        LucilleCore::selectEntityFromListOfEntitiesOrNull("Nx51", nx51s, lambda{|nx51| "(#{"%7.3f" % nx51["ordinal"]}) #{Nx51s::toString(nx51)}" })
    end

    # Nx51s::accessContent(item)
    def self.accessContent(item)
        if item["axiomId"].nil? then
            puts "description: #{item["description"]}"
            LucilleCore::pressEnterToContinue()
            return
        end
        NxAxioms::accessWithOptionToEdit(Nx51s::axiomsRepositoryFolderPath(), item["axiomId"])
    end

    # Nx51s::landing(nx51)
    def self.landing(nx51)
        uuid = nx51["uuid"]

        system("clear")

        loop {

            nx51 = Nx51s::getNx51ByUUIDOrNull(uuid)

            return if nx51.nil?

            system("clear")

            rt = BankExtended::stdRecoveredDailyTimeInHours(uuid)

            puts "running: #{Nx51s::toString(nx51)} (#{BankExtended::runningTimeString(nxball)})".green

            puts "note:\n#{StructuredTodoTexts::getNoteOrNull(uuid)}".green

            puts ""

            puts "uuid: #{uuid}".yellow
            puts "axiom id: #{nx51["axiomId"]}".yellow
            puts "DoNotDisplayUntil: #{DoNotShowUntil::getDateTimeOrNull(nx51["uuid"])}".yellow

            puts ""

            puts "access | <datecode> | note | [] | update description | update contents | update ordinal | exit | destroy".yellow

            puts Interpreters::mainMenuCommands().yellow

            command = LucilleCore::askQuestionAnswerAsString("> ")

            break if command == "exit"

            if Interpreting::match("access", command) then
                Nx51s::accessContent(nx51)
                next
            end

            if (unixtime = Utils::codeToUnixtimeOrNull(command.gsub(" ", ""))) then
                DoNotShowUntil::setUnixtime(uuid, unixtime)
                break
            end

            if Interpreting::match("note", command) then
                note = Utils::editTextSynchronously(StructuredTodoTexts::getNoteOrNull(nx51["uuid"]) || "")
                StructuredTodoTexts::setNote(uuid, note)
                next
            end

            if command == "[]" then
                StructuredTodoTexts::applyT(uuid)
                next
            end

            if Interpreting::match("update description", command) then
                description = Utils::editTextSynchronously(nx51["description"])
                if description.size > 0 then
                    nx51["description"] = description
                    Nx51s::commitItemToDisk(nx51)
                end
                next
            end

            if Interpreting::match("update contents", command) then
                puts "update contents against the new NxAxiom library is not implemented yet"
                LucilleCore::pressEnterToContinue()
                next
            end

            if Interpreting::match("update ordinal", command) then
                ordinal = Nx51s::decideOrdinal(Nx51s::toString(nx51))
                nx51["ordinal"] = ordinal
                Nx51s::commitItemToDisk(nx51)
                break
            end

            if Interpreting::match("destroy", command) then
                Nx51s::complete(nx51)
                break
            end

            Interpreters::mainMenuInterpreter(command)
        }
    end

    # --------------------------------------------------
    # nx16s

    # Nx51s::run(nx51)
    def self.run(nx51)

        uuid = nx51["uuid"]

        puts "#{Nx51s::toString(nx51)}".green
        puts "Starting at #{Time.new.to_s}"

        nxball = NxBalls::makeNxBall([uuid, Work::bankaccount()])

        thr = Thread.new {
            loop {
                sleep 60

                if (Time.new.to_i - nxball["cursorUnixtime"]) >= 600 then
                    nxball = NxBalls::upgradeNxBall(nxball, false)
                end

                if (Time.new.to_i - nxball["startUnixtime"]) >= 3600 then
                    Utils::onScreenNotification("Catalyst", "Nx51 item running for more than an hour")
                end
            }
        }

        note = StructuredTodoTexts::getNoteOrNull(uuid)
        if note then
            puts "Note ---------------------"
            puts note.green
            puts "--------------------------"
        end

        Nx51s::accessContent(nx51)
        
        loop {

            system("clear")

            puts "#{Nx51s::toString(nx51)} (#{BankExtended::runningTimeString(nxball)})".green

            note = StructuredTodoTexts::getNoteOrNull(uuid)
            if note then
                puts "Note ---------------------"
                puts note.green
                puts "--------------------------"
            end

            puts "exit (default) | note | [] | detach running | pause | pursue | landing | destroy"

            command = LucilleCore::askQuestionAnswerAsString("> ")

            break if command == ""

            break if command == "exit"

            if Interpreting::match("note", command) then
                note = Utils::editTextSynchronously(StructuredTodoTexts::getNoteOrNull(nx51["uuid"]) || "")
                StructuredTodoTexts::setNote(uuid, note)
                next
            end

            if command == "[]" then
                StructuredTodoTexts::applyT(uuid)
                note = StructuredTodoTexts::getNoteOrNull(uuid)
                if note then
                    puts "Note ---------------------"
                    puts note.green
                    puts "--------------------------" 
                end
            end

            if command == "detach running" then
                DetachedRunning::issueNew2(Nx51s::toString(nx51), Time.new.to_i, [uuid, Work::bankaccount()])
                break
            end

            if command == "pause" then
                NxBalls::closeNxBall(nxball, true)
                puts "Starting pause at #{Time.new.to_s}"
                LucilleCore::pressEnterToContinue()
                nxball = NxBalls::makeNxBall([uuid, Work::bankaccount()])
                next
            end

            if command == "pursue" then
                # We close the ball and issue a new one
                NxBalls::closeNxBall(nxball, true)
                nxball = NxBalls::makeNxBall([uuid, Work::bankaccount()])
                next
            end

            if command == "landing" then
                Nx51s::landing(nx51)
                break if Nx51s::getNx51ByUUIDOrNull(nx51["uuid"]).nil? # Could hve been destroyed
            end

            if command == "destroy" then
                if LucilleCore::askQuestionAnswerAsBoolean("detroy '#{Nx51s::toString(nx51)}' ? ", true) then
                    Nx51s::complete(nx51)
                    break
                end
            end
        }

        thr.exit

        NxBalls::closeNxBall(nxball, true)
    end

    # Nx51s::ns16OrNull(nx51)
    def self.ns16OrNull(nx51)
        uuid = nx51["uuid"]
        rt = BankExtended::stdRecoveredDailyTimeInHours(uuid)
        note = StructuredTodoTexts::getNoteOrNull(uuid)
        noteStr = note ? " [note]" : ""
        announce = "#{Nx51s::toString(nx51)}#{noteStr} (rt: #{rt.round(2)})"
            .gsub("( 0.00)", "       ")
            .gsub("( 1.00)", "       ")
        {
            "uuid"     => uuid,
            "announce" => announce,
            "commands"    => ["..", "landing", "done"],
            "interpreter" => lambda {|command|
                if command == ".." then
                    Nx51s::run(nx51)
                end
                if command == "landing" then
                    Nx51s::landing(nx51)
                end
                if command == "done" then
                    if LucilleCore::askQuestionAnswerAsBoolean("done '#{Nx51s::toString(nx51)}' ? ", true) then
                        Nx51s::complete(nx51)
                    end
                end
            },
            "run" => lambda {
                Nx51s::run(nx51)
            },
            "rt" => rt
        }
    end

    # Nx51s::ns16s()
    def self.ns16s()
        return [] if !Work::shouldDisplayWorkItems()
        Nx51s::nx51sPerOrdinal()
            .map{|nx51| Nx51s::ns16OrNull(nx51) }
            .compact
            .select{|item| DoNotShowUntil::isVisible(item["uuid"]) }
    end

    # --------------------------------------------------

    # Nx51s::nx19s()
    def self.nx19s()
        Nx51s::nx51s().map{|item|
            {
                "uuid"     => item["uuid"],
                "announce" => Nx51s::toString(item),
                "lambda"   => lambda { Nx51s::landing(item) }
            }
        }
    end
end
