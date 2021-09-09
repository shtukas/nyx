# encoding: UTF-8

class NxFloats

    # --------------------------------------------------
    # IO

    # NxFloats::repositoryFolderPath()
    def self.repositoryFolderPath()
        "/Users/pascal/Galaxy/DataBank/Catalyst/items/NxFloats"
    end

    # NxFloats::commitFloatToDisk(float)
    def self.commitFloatToDisk(float)
        filename = "#{float["uuid"]}.json"
        filepath = "#{NxFloats::repositoryFolderPath()}/#{filename}"
        File.open(filepath, "w") {|f| f.puts(JSON.pretty_generate(float)) }
    end

    # NxFloats::nxfloats()
    def self.nxfloats()
        LucilleCore::locationsAtFolder(NxFloats::repositoryFolderPath())
            .select{|location| location[-5, 5] == ".json" }
            .map{|location| JSON.parse(IO.read(location)) }
            .sort{|f1, f2| f1["unixtime"] <=> f2["unixtime"] }
    end

    # NxFloats::getNxFloatByUUIDOrNull(uuid)
    def self.getNxFloatByUUIDOrNull(uuid)
        filename = "#{uuid}.json"
        filepath = "#{NxFloats::repositoryFolderPath()}/#{filename}"
        return nil if !File.exists?(filepath)
        JSON.parse(IO.read(filepath))
    end

    # NxFloats::destroy(item)
    def self.destroy(item)
        filename = "#{item["uuid"]}.json"
        filepath = "#{NxFloats::repositoryFolderPath()}/#{filename}"
        return if !File.exists?(filepath)
        FileUtils.rm(filepath)
    end

    # NxFloats::axiomsRepositoryFolderPath()
    def self.axiomsRepositoryFolderPath()
        "/Users/pascal/Galaxy/DataBank/Catalyst/items/NxFloats-axioms"
    end

    # --------------------------------------------------
    # Making

    # NxFloats::interactivelyCreateNewOrNull()
    def self.interactivelyCreateNewOrNull()
        uuid = SecureRandom.uuid

        description = LucilleCore::askQuestionAnswerAsString("description (empty for abort): ")
        if description == "" then
            return nil
        end

        unixtime     = Time.new.to_f

        axiomId  = LucilleCore::timeStringL22()
        NxAxioms::interactivelyCreateNewAxiom(NxFloats::axiomsRepositoryFolderPath(), axiomId)

        float = {
          "uuid"           => uuid,
          "unixtime"       => unixtime,
          "description"    => description,
          "axiomId"        => axiomId
        }

        NxFloats::commitFloatToDisk(float)

        float
    end

    # --------------------------------------------------
    # Operations

    # NxFloats::contentType(item)
    def self.contentType(item)
        "unknown content type"
    end

    # NxFloats::toString(item)
    def self.toString(item)
        contentType = NxFloats::contentType(item)
        str1 = (contentType and contentType.size > 0) ? " (#{contentType})" : ""
        "[float] #{item["description"]}#{str1}"
    end

    # NxFloats::accessContent(item)
    def self.accessContent(item)
        if item["axiomId"].nil? then
            puts "description: #{item["description"]}"
            LucilleCore::pressEnterToContinue()
            return
        end
        NxAxioms::accessWithOptionToEdit(NxFloats::axiomsRepositoryFolderPath(), item["axiomId"])
    end

    # NxFloats::landing(nxfloat)
    def self.landing(nxfloat)

        uuid = nxfloat["uuid"]

        nxball = NxBalls::makeNxBall([uuid, "MISC-BE92-4874-85F1-54F140E3B243"])

        thr = Thread.new {
            loop {
                sleep 60

                if (Time.new.to_i - nxball["cursorUnixtime"]) >= 600 then
                    nxball = NxBalls::upgradeNxBall(nxball, false)
                end

                if (Time.new.to_i - nxball["startUnixtime"]) >= 3600 then
                    Utils::onScreenNotification("Catalyst", "NxFloat item running for more than an hour")
                end
            }
        }

        system("clear")

        loop {

            nxfloat = NxFloats::getNxFloatByUUIDOrNull(uuid)

            return if nxfloat.nil?

            system("clear")

            rt = BankExtended::stdRecoveredDailyTimeInHours(uuid)

            puts "running: (#{"%.3f" % rt}) #{NxFloats::toString(nxfloat)} (#{BankExtended::runningTimeString(nxball)})".green

            puts "note:\n#{StructuredTodoTexts::getNoteOrNull(uuid)}".green

            puts ""

            puts "uuid: #{uuid}".yellow
            puts "axiom id: #{nxfloat["axiomId"]}".yellow
            puts "DoNotDisplayUntil: #{DoNotShowUntil::getDateTimeOrNull(nxfloat["uuid"])}".yellow

            puts ""

            puts "[item   ] access | note | [] | <datecode> | detach running | pause | exit | pursue | completed | update description | update contents | destroy".yellow

            puts Interpreters::mainMenuCommands().yellow

            command = LucilleCore::askQuestionAnswerAsString("> ")

            break if command == "exit"

            if command == "++" then
                DoNotShowUntil::setUnixtime(uuid, Time.new.to_i+3600)
                break
            end

            if (unixtime = Utils::codeToUnixtimeOrNull(command.gsub(" ", ""))) then
                DoNotShowUntil::setUnixtime(uuid, unixtime)
                break
            end

            if Interpreting::match("note", command) then
                note = Utils::editTextSynchronously(StructuredTodoTexts::getNoteOrNull(nxfloat["uuid"]) || "")
                StructuredTodoTexts::setNote(uuid, note)
                next
            end

            if command == "[]" then
                StructuredTodoTexts::applyT(uuid)
                next
            end

            if command == "pursue" then
                # We close the ball and issue a new one
                NxBalls::closeNxBall(nxball, true)
                nxball = NxBalls::makeNxBall([uuid, "MISC-BE92-4874-85F1-54F140E3B243"])
                next
            end

            if Interpreting::match("access", command) then
                NxFloats::accessContent(nxfloat)
                next
            end

            if Interpreting::match("pause", command) then
                NxBalls::closeNxBall(nxball, true)
                puts "Starting pause at #{Time.new.to_s}"
                LucilleCore::pressEnterToContinue()
                nxball = NxBalls::makeNxBall([uuid, "MISC-BE92-4874-85F1-54F140E3B243"])
                next
            end

            if Interpreting::match("detach running", command) then
                DetachedRunning::issueNew2(NxFloats::toString(nxfloat), Time.new.to_i, [uuid, "MISC-BE92-4874-85F1-54F140E3B243"])
                break
            end

            if Interpreting::match("completed", command) then
                NxFloats::destroy(nxfloat)
                break
            end

            if Interpreting::match("update description", command) then
                description = Utils::editTextSynchronously(nxfloat["description"])
                next if description.size == 0
                nxfloat["description"] = description
                NxFloats::commitFloatToDisk(nxfloat)
                next
            end

            if Interpreting::match("update contents", command) then
                puts "Not implemented yet"
                LucilleCore::pressEnterToContinue()
                next
            end

            if Interpreting::match("destroy", command) then
                NxFloats::destroy(nxfloat)
                break
            end

            Interpreters::mainMenuInterpreter(command)
        }

        thr.exit

        NxBalls::closeNxBall(nxball, true)
    end

    # --------------------------------------------------
    # nx16s

    # NxFloats::run(nxfloat)
    def self.run(nxfloat)
        uuid = nxfloat["uuid"]
        puts "Starting at #{Time.new.to_s}"
        nxball = NxBalls::makeNxBall([uuid, "MISC-BE92-4874-85F1-54F140E3B243"])
        NxFloats::accessContent(nxfloat)

        note = StructuredTodoTexts::getNoteOrNull(uuid)
        if note then
            puts "Note ---------------------"
            puts note.green
            puts "--------------------------"
        end

        LucilleCore::pressEnterToContinue()

        loop {
            options = ["exit (default)", "[]", "landing", "destroy"]
            option = LucilleCore::selectEntityFromListOfEntitiesOrNull("option", options)
            NxBalls::closeNxBall(nxball, true)
            if option.nil? then
                break
            end
            if option == "exit (default)" then
                break
            end
            if option == "[]" then
                StructuredTodoTexts::applyT(uuid)
                note = StructuredTodoTexts::getNoteOrNull(uuid)
                if note then
                    puts "Note ---------------------"
                    puts note.green
                    puts "--------------------------"
                end
                next
            end
            if option == "landing" then
                NxFloats::landing(nxfloat)
                next
            end
            if option == "destroy" then
                if LucilleCore::askQuestionAnswerAsBoolean("detroy '#{NxFloats::toString(nxfloat)}' ? ", true) then
                    NxFloats::destroy(nxfloat)
                    break
                end
                next
            end
        }
    end

    # NxFloats::ns16OrNull(nxfloat)
    def self.ns16OrNull(nxfloat)
        uuid = nxfloat["uuid"]
        return nil if !DoNotShowUntil::isVisible(uuid)
        rt = BankExtended::stdRecoveredDailyTimeInHours(uuid)
        note = StructuredTodoTexts::getNoteOrNull(uuid)
        noteStr = note ? " [note]" : ""
        announce = "(#{"%4.2f" % rt}) #{NxFloats::toString(nxfloat)}#{noteStr}".gsub("(0.00)", "      ")
        {
            "uuid"     => uuid,
            "announce" => announce.green,
            "commands"    => ["..", "landing", "done"],
            "interpreter" => lambda {|command|
                if command == ".." then
                    NxFloats::run(nxfloat)
                end
                if command == "landing" then
                    NxFloats::landing(nxfloat)
                end
                if command == "done" then
                    if LucilleCore::askQuestionAnswerAsBoolean("destroy '#{NxFloats::toString(nxfloat)}' ? ", true) then
                        NxFloats::destroy(nxfloat)
                    end
                end
            },
            "run" => lambda {
                NxFloats::run(nxfloat)
            },
            "rt" => rt
        }
    end

    # NxFloats::ns16s()
    def self.ns16s()
        NxFloats::nxfloats()
            .map{|nxfloat| NxFloats::ns16OrNull(nxfloat) }
            .compact
            .sort{|n1, n2| n1["unixtime"] <=> n2["unixtime"] }
    end

    # --------------------------------------------------

    # NxFloats::nx19s()
    def self.nx19s()
        NxFloats::nxfloats().map{|item|
            {
                "uuid"     => item["uuid"],
                "announce" => NxFloats::toString(item),
                "lambda"   => lambda { NxFloats::landing(item) }
            }
        }
    end
end
