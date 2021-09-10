# encoding: UTF-8

class NxAfterWorks

    # --------------------------------------------------
    # IO

    # NxAfterWorks::itemsFolderPath()
    def self.itemsFolderPath()
        "/Users/pascal/Galaxy/DataBank/Catalyst/items/NxAfterWorks"
    end

    # NxAfterWorks::commitFloatToDisk(float)
    def self.commitFloatToDisk(float)
        filename = "#{float["uuid"]}.json"
        filepath = "#{NxAfterWorks::itemsFolderPath()}/#{filename}"
        File.open(filepath, "w") {|f| f.puts(JSON.pretty_generate(float)) }
    end

    # NxAfterWorks::items()
    def self.items()
        LucilleCore::locationsAtFolder(NxAfterWorks::itemsFolderPath())
            .select{|location| location[-5, 5] == ".json" }
            .map{|location| JSON.parse(IO.read(location)) }
            .sort{|f1, f2| f1["unixtime"] <=> f2["unixtime"] }
    end

    # NxAfterWorks::getItemByUUIDOrNull(uuid)
    def self.getItemByUUIDOrNull(uuid)
        filename = "#{uuid}.json"
        filepath = "#{NxAfterWorks::itemsFolderPath()}/#{filename}"
        return nil if !File.exists?(filepath)
        JSON.parse(IO.read(filepath))
    end

    # NxAfterWorks::destroy(item)
    def self.destroy(item)
        NxAxioms::destroy(NxAfterWorks::axiomsFolderPath(), item["axiomId"])

        filename = "#{item["uuid"]}.json"
        filepath = "#{NxAfterWorks::itemsFolderPath()}/#{filename}"
        return if !File.exists?(filepath)
        FileUtils.rm(filepath)
    end

    # NxAfterWorks::axiomsFolderPath()
    def self.axiomsFolderPath()
        "/Users/pascal/Galaxy/DataBank/Catalyst/items/NxAfterWorks-axioms"
    end

    # --------------------------------------------------
    # Making

    # NxAfterWorks::interactivelyCreateNewOrNull()
    def self.interactivelyCreateNewOrNull()
        uuid = LucilleCore::timeStringL22()

        description = LucilleCore::askQuestionAnswerAsString("description (empty for abort): ")
        if description == "" then
            return nil
        end

        unixtime = Time.new.to_f

        axiomId = NxAxioms::interactivelyCreateNewAxiom_EchoIdOrNull(NxAfterWorks::axiomsFolderPath(), LucilleCore::timeStringL22())
    
        item = {
          "uuid"           => uuid,
          "unixtime"       => unixtime,
          "description"    => description,
          "axiomId"        => axiomId
        }

        NxAfterWorks::commitFloatToDisk(item)

        item
    end

    # NxAfterWorks::issueNx50UsingURL(url)
    def self.issueNx50UsingURL(url)
        uuid         = LucilleCore::timeStringL22()
        description  = url
        axiomId      = NxA002::make(NxAfterWorks::itemsFolderPath(), LucilleCore::timeStringL22(), url)
        NxAfterWorks::commitFloatToDisk({
            "uuid"        => uuid,
            "unixtime"    => Time.new.to_f,
            "description" => description,
            "axiomId"     => axiomId,
        })
        NxAfterWorks::getItemByUUIDOrNull(uuid)
    end

    # NxAfterWorks::issueNx50UsingLocation(location)
    def self.issueNx50UsingLocation(location)
        uuid        = LucilleCore::timeStringL22()
        unixtime    = Time.new.to_f
        description = File.basename(location)
        axiomId     = NxA003::make(NxAfterWorks::axiomsFolderPath(), LucilleCore::timeStringL22(), location)
        NxAfterWorks::commitFloatToDisk({
            "uuid"        => uuid,
            "unixtime"    => unixtime,
            "description" => description,
            "axiomId"     => axiomId,
        })
        NxAfterWorks::getItemByUUIDOrNull(uuid)
    end

    # --------------------------------------------------
    # Operations

    # NxAfterWorks::toString(item)
    def self.toString(item)
        "[aftw] #{item["description"]}"
    end

    # NxAfterWorks::accessContent(item)
    def self.accessContent(item)
        if item["axiomId"].nil? then
            puts "description: #{item["description"]}"
            LucilleCore::pressEnterToContinue()
            return
        end
        NxAxioms::accessWithOptionToEdit(NxAfterWorks::axiomsFolderPath(), item["axiomId"])
    end

    # NxAfterWorks::landing(item)
    def self.landing(item)

        uuid = item["uuid"]

        system("clear")

        loop {

            item = NxAfterWorks::getItemByUUIDOrNull(uuid)

            return if item.nil?

            system("clear")

            puts NxAfterWorks::toString(item)

            puts "note:\n#{StructuredTodoTexts::getNoteOrNull(uuid)}".green

            puts ""

            puts "uuid: #{uuid}".yellow
            puts "axiomId: #{item["axiomId"]}".yellow
            puts "DoNotDisplayUntil: #{DoNotShowUntil::getDateTimeOrNull(item["uuid"])}".yellow

            puts ""

            puts "[item   ] access | note | [] | <datecode> | update description | update contents | exit | destroy".yellow

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
                note = Utils::editTextSynchronously(StructuredTodoTexts::getNoteOrNull(item["uuid"]) || "")
                StructuredTodoTexts::setNote(uuid, note)
                next
            end

            if command == "[]" then
                StructuredTodoTexts::applyT(uuid)
                next
            end

            if Interpreting::match("access", command) then
                NxAfterWorks::accessContent(item)
                next
            end

            if Interpreting::match("update description", command) then
                description = Utils::editTextSynchronously(item["description"])
                next if description.size == 0
                item["description"] = description
                NxAfterWorks::commitFloatToDisk(item)
                next
            end

            if Interpreting::match("update contents", command) then
                puts "Not implemented yet"
                LucilleCore::pressEnterToContinue()
                next
            end

            if Interpreting::match("destroy", command) then
                NxAfterWorks::destroy(item)
                break
            end

            Interpreters::mainMenuInterpreter(command)
        }
    end

    # --------------------------------------------------
    # nx16s

    # NxAfterWorks::run(item)
    def self.run(item)

        uuid = item["uuid"]

        puts "Running #{NxAfterWorks::toString(item)}".green
        puts "Starting at #{Time.new.to_s}"

        nxball = NxBalls::makeNxBall([uuid, "MISC-BE92-4874-85F1-54F140E3B243"])

        thr = Thread.new {
            loop {
                sleep 60

                if (Time.new.to_i - nxball["cursorUnixtime"]) >= 600 then
                    nxball = NxBalls::upgradeNxBall(nxball, false)
                end

                if (Time.new.to_i - nxball["startUnixtime"]) >= 3600 then
                    Utils::onScreenNotification("Catalyst", "NxAfterWork item running for more than an hour")
                end
            }
        }

        note = StructuredTodoTexts::getNoteOrNull(uuid)
        if note then
            puts "Note ---------------------"
            puts note.green
            puts "--------------------------"
        end

        NxAfterWorks::accessContent(item)

        loop {

            puts "running: #{NxAfterWorks::toString(item)} (#{BankExtended::runningTimeString(nxball)})".green

            note = StructuredTodoTexts::getNoteOrNull(uuid)
            if note then
                puts "Note ---------------------"
                puts note.green
                puts "--------------------------"
            end

            puts "exit (default) | note | [] | detach running | pause | pursue | landing | destroy".yellow
            command = LucilleCore::askQuestionAnswerAsString("> ")
            
            if command == "" then
                break
            end

            if command == "exit" then
                break
            end

            if command == "note" then
                note = Utils::editTextSynchronously(StructuredTodoTexts::getNoteOrNull(item["uuid"]) || "")
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
                next
            end

            if Interpreting::match("detach running", command) then
                DetachedRunning::issueNew2(NxAfterWorks::toString(item), Time.new.to_i, [uuid, "MISC-BE92-4874-85F1-54F140E3B243"])
                break
            end

            if Interpreting::match("pause", command) then
                NxBalls::closeNxBall(nxball, true)
                puts "Starting pause at #{Time.new.to_s}"
                LucilleCore::pressEnterToContinue()
                nxball = NxBalls::makeNxBall([uuid, "MISC-BE92-4874-85F1-54F140E3B243"])
                next
            end

            if command == "pursue" then
                # We close the ball and issue a new one
                NxBalls::closeNxBall(nxball, true)
                nxball = NxBalls::makeNxBall([uuid, "MISC-BE92-4874-85F1-54F140E3B243"])
                next
            end

            if command == "landing" then
                NxAfterWorks::landing(item)
                next
            end

            if command == "destroy" then
                if LucilleCore::askQuestionAnswerAsBoolean("detroy '#{NxAfterWorks::toString(item)}' ? ", true) then
                    NxAfterWorks::destroy(item)
                    break
                end
                next
            end
        }

        thr.exit

        NxBalls::closeNxBall(nxball, true)
    end

    # NxAfterWorks::ns16OrNull(item)
    def self.ns16OrNull(item)
        uuid = item["uuid"]
        return nil if !DoNotShowUntil::isVisible(uuid)
        note = StructuredTodoTexts::getNoteOrNull(uuid)
        noteStr = note ? " [note]" : ""
        announce = "#{NxAfterWorks::toString(item)}#{noteStr}"
        {
            "uuid"     => uuid,
            "announce" => announce,
            "commands"    => ["..", "landing", "done"],
            "interpreter" => lambda {|command|
                if command == ".." then
                    NxAfterWorks::run(item)
                end
                if command == "landing" then
                    NxAfterWorks::landing(item)
                end
                if command == "done" then
                    if LucilleCore::askQuestionAnswerAsBoolean("destroy '#{NxAfterWorks::toString(item)}' ? ", true) then
                        NxAfterWorks::destroy(item)
                    end
                end
            },
            "run" => lambda {
                NxAfterWorks::run(item)
            }
        }
    end

    # NxAfterWorks::ns16s()
    def self.ns16s()
        LucilleCore::locationsAtFolder("/Users/pascal/Desktop/NxAfterWork (Inbox)").each{|location|
            NxAfterWorks::issueNx50UsingLocation(location)
            LucilleCore::removeFileSystemLocation(location)
        }

        return [] if Work::shouldDisplayWorkItems()
        NxAfterWorks::items()
            .map{|item| NxAfterWorks::ns16OrNull(item) }
            .compact
            .sort{|n1, n2| n1["unixtime"] <=> n2["unixtime"] }
    end

    # --------------------------------------------------

    # NxAfterWorks::nx19s()
    def self.nx19s()
        NxAfterWorks::items().map{|item|
            {
                "uuid"     => item["uuid"],
                "announce" => NxAfterWorks::toString(item),
                "lambda"   => lambda { NxAfterWorks::landing(item) }
            }
        }
    end
end