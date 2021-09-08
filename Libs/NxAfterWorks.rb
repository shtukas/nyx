# encoding: UTF-8

class NxAfterWorks

    # --------------------------------------------------
    # IO

    # NxAfterWorks::repositoryFolderPath()
    def self.repositoryFolderPath()
        "/Users/pascal/Galaxy/DataBank/Catalyst/items/NxAfterWorks"
    end

    # NxAfterWorks::commitFloatToDisk(float)
    def self.commitFloatToDisk(float)
        filename = "#{float["uuid"]}.json"
        filepath = "#{NxAfterWorks::repositoryFolderPath()}/#{filename}"
        File.open(filepath, "w") {|f| f.puts(JSON.pretty_generate(float)) }
    end

    # NxAfterWorks::items()
    def self.items()
        LucilleCore::locationsAtFolder(NxAfterWorks::repositoryFolderPath())
            .select{|location| location[-5, 5] == ".json" }
            .map{|location| JSON.parse(IO.read(location)) }
            .sort{|f1, f2| f1["unixtime"] <=> f2["unixtime"] }
    end

    # NxAfterWorks::getItemByUUIDOrNull(uuid)
    def self.getItemByUUIDOrNull(uuid)
        filename = "#{uuid}.json"
        filepath = "#{NxAfterWorks::repositoryFolderPath()}/#{filename}"
        return nil if !File.exists?(filepath)
        JSON.parse(IO.read(filepath))
    end

    # NxAfterWorks::destroy(item)
    def self.destroy(item)
        filename = "#{item["uuid"]}.json"
        filepath = "#{NxAfterWorks::repositoryFolderPath()}/#{filename}"
        return if !File.exists?(filepath)
        FileUtils.rm(filepath)
    end

    # --------------------------------------------------
    # Making

    # NxAfterWorks::interactivelyCreateNewOrNull()
    def self.interactivelyCreateNewOrNull()
        uuid = SecureRandom.uuid

        description = LucilleCore::askQuestionAnswerAsString("description (empty for abort): ")
        if description == "" then
            return nil
        end

        coordinates  = Axion::interactivelyIssueNewCoordinatesOrNull()

        unixtime     = Time.new.to_f

        contentType     = coordinates ? coordinates["contentType"] : nil
        contentPayload  = coordinates ? coordinates["contentPayload"] : nil

        float = {
          "uuid"           => uuid,
          "unixtime"       => unixtime,
          "description"    => description,
          "catalystType"   => "NxAfterWork",
          "contentType"    => contentType,
          "contentPayload" => contentPayload
        }

        NxAfterWorks::commitFloatToDisk(float)

        float
    end

    # --------------------------------------------------
    # Operations

    # NxAfterWorks::toString(item)
    def self.toString(item)
        contentType = item["contentType"]
        str1 = (contentType and contentType.size > 0) ? " (#{contentType})" : ""
        "[aftw] #{item["description"]}#{str1}"
    end

    # NxAfterWorks::toStringForNS16(item, rt)
    def self.toStringForNS16(item, rt)
        contentType = item["contentType"]
        str1 = (contentType and contentType.size > 0) ? " (#{contentType})" : ""
        "[aftw] (#{"%4.2f" % rt}) #{item["description"]}#{str1}"
    end

    # NxAfterWorks::accessContent(item)
    def self.accessContent(item)
        update = lambda {|contentType, contentPayload|
            item["contentType"] = contentType
            item["contentPayload"] = contentPayload
            NxAfterWorks::commitFloatToDisk(item)
        }
        Axion::access(item["contentType"], item["contentPayload"], update)
    end

    # NxAfterWorks::landing(item)
    def self.landing(item)

        uuid = item["uuid"]

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

        system("clear")

        loop {

            item = NxAfterWorks::getItemByUUIDOrNull(uuid)

            return if item.nil?

            system("clear")

            rt = BankExtended::stdRecoveredDailyTimeInHours(uuid)

            puts "running: (#{"%.3f" % rt}) #{NxAfterWorks::toString(item)} (#{BankExtended::runningTimeString(nxball)})".green

            puts "note:\n#{StructuredTodoTexts::getNoteOrNull(uuid)}".green

            puts ""

            puts "uuid: #{uuid}".yellow
            puts "coordinates: #{item["contentType"]}, #{item["contentPayload"]}".yellow
            puts "DoNotDisplayUntil: #{DoNotShowUntil::getDateTimeOrNull(item["uuid"])}".yellow

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
                note = Utils::editTextSynchronously(StructuredTodoTexts::getNoteOrNull(item["uuid"]) || "")
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
                NxAfterWorks::accessContent(item)
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
                DetachedRunning::issueNew2(NxAfterWorks::toString(item), Time.new.to_i, [uuid, "MISC-BE92-4874-85F1-54F140E3B243"])
                break
            end

            if Interpreting::match("completed", command) then
                NxAfterWorks::destroy(item)
                break
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

        thr.exit

        NxBalls::closeNxBall(nxball, true)

        Axion::postAccessCleanUp(item["contentType"], item["contentPayload"])
    end

    # --------------------------------------------------
    # nx16s

    # NxAfterWorks::run(item)
    def self.run(item)
        uuid = item["uuid"]
        puts "Starting at #{Time.new.to_s}"
        nxball = NxBalls::makeNxBall([uuid, "MISC-BE92-4874-85F1-54F140E3B243"])
        NxAfterWorks::accessContent(item)

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
                NxAfterWorks::landing(item)
                next
            end
            if option == "destroy" then
                if LucilleCore::askQuestionAnswerAsBoolean("detroy '#{NxAfterWorks::toString(item)}' ? ", true) then
                    NxAfterWorks::destroy(item)
                    break
                end
                next
            end
        }
    end

    # NxAfterWorks::ns16OrNull(item)
    def self.ns16OrNull(item)
        uuid = item["uuid"]
        return nil if !DoNotShowUntil::isVisible(uuid)
        rt = BankExtended::stdRecoveredDailyTimeInHours(uuid)
        note = StructuredTodoTexts::getNoteOrNull(uuid)
        noteStr = note ? " [note]" : ""
        announce = "#{NxAfterWorks::toStringForNS16(item, rt)}#{noteStr}"
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
            },
            "rt" => rt
        }
    end

    # NxAfterWorks::ns16s()
    def self.ns16s()
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
