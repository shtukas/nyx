# encoding: UTF-8

class NxAfterHours

    # --------------------------------------------------
    # IO

    # NxAfterHours::itemsFolderPath()
    def self.itemsFolderPath()
        "/Users/pascal/Galaxy/DataBank/Catalyst/items/NxAfterHours"
    end

    # NxAfterHours::commitFloatToDisk(float)
    def self.commitFloatToDisk(float)
        filename = "#{float["uuid"]}.json"
        filepath = "#{NxAfterHours::itemsFolderPath()}/#{filename}"
        File.open(filepath, "w") {|f| f.puts(JSON.pretty_generate(float)) }
    end

    # NxAfterHours::items()
    def self.items()
        LucilleCore::locationsAtFolder(NxAfterHours::itemsFolderPath())
            .select{|location| location[-5, 5] == ".json" }
            .map{|location| JSON.parse(IO.read(location)) }
            .sort{|f1, f2| f1["unixtime"] <=> f2["unixtime"] }
    end

    # NxAfterHours::getItemByUUIDOrNull(uuid)
    def self.getItemByUUIDOrNull(uuid)
        filename = "#{uuid}.json"
        filepath = "#{NxAfterHours::itemsFolderPath()}/#{filename}"
        return nil if !File.exists?(filepath)
        JSON.parse(IO.read(filepath))
    end

    # NxAfterHours::destroy(item)
    def self.destroy(item)
        NxAxioms::destroy(NxAfterHours::axiomsFolderPath(), item["axiomId"])

        filename = "#{item["uuid"]}.json"
        filepath = "#{NxAfterHours::itemsFolderPath()}/#{filename}"
        return if !File.exists?(filepath)
        FileUtils.rm(filepath)
    end

    # NxAfterHours::axiomsFolderPath()
    def self.axiomsFolderPath()
        "/Users/pascal/Galaxy/DataBank/Catalyst/items/NxAfterHours-axioms"
    end

    # --------------------------------------------------
    # Making

    # NxAfterHours::interactivelyCreateNewOrNull()
    def self.interactivelyCreateNewOrNull()
        uuid = LucilleCore::timeStringL22()

        description = LucilleCore::askQuestionAnswerAsString("description (empty for abort): ")
        if description == "" then
            return nil
        end

        unixtime = Time.new.to_f

        axiomId = NxAxioms::interactivelyCreateNewAxiom_EchoIdOrNull(NxAfterHours::axiomsFolderPath(), LucilleCore::timeStringL22())
    
        item = {
          "uuid"           => uuid,
          "unixtime"       => unixtime,
          "description"    => description,
          "axiomId"        => axiomId
        }

        NxAfterHours::commitFloatToDisk(item)

        item
    end

    # NxAfterHours::issueNx50UsingURL(url)
    def self.issueNx50UsingURL(url)
        uuid         = LucilleCore::timeStringL22()
        description  = url
        axiomId      = NxA002::make(NxAfterHours::itemsFolderPath(), LucilleCore::timeStringL22(), url)
        NxAfterHours::commitFloatToDisk({
            "uuid"        => uuid,
            "unixtime"    => Time.new.to_f,
            "description" => description,
            "axiomId"     => axiomId,
        })
        NxAfterHours::getItemByUUIDOrNull(uuid)
    end

    # NxAfterHours::issueNx50UsingLocation(location)
    def self.issueNx50UsingLocation(location)
        uuid        = LucilleCore::timeStringL22()
        unixtime    = Time.new.to_f
        description = File.basename(location)
        axiomId     = NxA003::make(NxAfterHours::axiomsFolderPath(), LucilleCore::timeStringL22(), location)
        NxAfterHours::commitFloatToDisk({
            "uuid"        => uuid,
            "unixtime"    => unixtime,
            "description" => description,
            "axiomId"     => axiomId,
        })
        NxAfterHours::getItemByUUIDOrNull(uuid)
    end

    # --------------------------------------------------
    # Operations

    # NxAfterHours::toString(item)
    def self.toString(item)
        "[aftw] #{item["description"]}"
    end

    # NxAfterHours::toStringForNS16(item, rt, timeReq)
    def self.toStringForNS16(item, rt, timeReq)
        "[aftw] (#{"%4.2f" % rt} of #{"%4.2f" % timeReq}) #{item["description"]}"
    end

    # NxAfterHours::accessContent(item)
    def self.accessContent(item)
        if item["axiomId"].nil? then
            puts "description: #{item["description"]}"
            LucilleCore::pressEnterToContinue()
            return
        end
        NxAxioms::accessWithOptionToEdit(NxAfterHours::axiomsFolderPath(), item["axiomId"])
    end

    # --------------------------------------------------
    # nx16s

    # NxAfterHours::run(item)
    def self.run(item)

        uuid = item["uuid"]

        puts "Running #{NxAfterHours::toString(item)}".green
        puts "DoNotDisplayUntil: #{DoNotShowUntil::getDateTimeOrNull(item["uuid"])}".yellow
        puts "Starting at #{Time.new.to_s}"

        nxball = NxBalls::makeNxBall([uuid, "ELEMENTS-BE92-4874-85F1-54F140E3B243"])

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

        NxAfterHours::accessContent(item)

        loop {

            puts "running: #{NxAfterHours::toString(item)} (#{BankExtended::runningTimeString(nxball)})".green
            puts "DoNotDisplayUntil: #{DoNotShowUntil::getDateTimeOrNull(item["uuid"])}".yellow

            note = StructuredTodoTexts::getNoteOrNull(uuid)
            if note then
                puts "Note ---------------------"
                puts note.green
                puts "--------------------------"
            end

            puts "exit (default) | note | [] | <datecode> | detach running | pause | pursue | update description | update contents | destroy".yellow
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

            if (unixtime = Utils::codeToUnixtimeOrNull(command.gsub(" ", ""))) then
                DoNotShowUntil::setUnixtime(uuid, unixtime)
                break
            end

            if Interpreting::match("detach running", command) then
                DetachedRunning::issueNew2(NxAfterHours::toString(item), Time.new.to_i, [uuid, "ELEMENTS-BE92-4874-85F1-54F140E3B243"])
                break
            end

            if Interpreting::match("pause", command) then
                NxBalls::closeNxBall(nxball, true)
                puts "Starting pause at #{Time.new.to_s}"
                LucilleCore::pressEnterToContinue()
                nxball = NxBalls::makeNxBall([uuid, "ELEMENTS-BE92-4874-85F1-54F140E3B243"])
                next
            end

            if command == "pursue" then
                # We close the ball and issue a new one
                NxBalls::closeNxBall(nxball, true)
                nxball = NxBalls::makeNxBall([uuid, "ELEMENTS-BE92-4874-85F1-54F140E3B243"])
                next
            end

            if Interpreting::match("update description", command) then
                description = Utils::editTextSynchronously(item["description"])
                next if description.size == 0
                item["description"] = description
                NxAfterHours::commitFloatToDisk(item)
                next
            end

            if Interpreting::match("update contents", command) then
                puts "Not implemented yet"
                LucilleCore::pressEnterToContinue()
                next
            end

            if command == "destroy" then
                if LucilleCore::askQuestionAnswerAsBoolean("detroy '#{NxAfterHours::toString(item)}' ? ", true) then
                    NxAfterHours::destroy(item)
                    break
                end
                next
            end
        }

        thr.exit

        NxBalls::closeNxBall(nxball, true)
    end

    # NxAfterHours::ns16OrNull(item, integersEnumerator)
    def self.ns16OrNull(item, integersEnumerator)
        uuid = item["uuid"]
        return nil if !DoNotShowUntil::isVisible(uuid)
        rt = BankExtended::stdRecoveredDailyTimeInHours(uuid)
        timeRequirementInHours = 1/(2 ** integersEnumerator.next()) # first value is 1/(2 ** 0) = 1
        return nil if rt > timeRequirementInHours
        announce = NxAfterHours::toStringForNS16(item, rt, timeRequirementInHours)
        note = StructuredTodoTexts::getNoteOrNull(uuid)
        noteStr = note ? " [note]" : ""
        announce = "#{announce}#{noteStr}"
        {
            "uuid"     => uuid,
            "announce" => announce,
            "commands"    => ["..", "done"],
            "interpreter" => lambda {|command|
                if command == ".." then
                    NxAfterHours::run(item)
                end
                if command == "done" then
                    if LucilleCore::askQuestionAnswerAsBoolean("destroy '#{NxAfterHours::toString(item)}' ? ", true) then
                        NxAfterHours::destroy(item)
                    end
                end
            },
            "run" => lambda {
                NxAfterHours::run(item)
            },
            "rt" => rt
        }
    end

    # NxAfterHours::ns16s()
    def self.ns16s()
        LucilleCore::locationsAtFolder("/Users/pascal/Desktop/NxAfterWork (Inbox)").each{|location|
            NxAfterHours::issueNx50UsingLocation(location)
            LucilleCore::removeFileSystemLocation(location)
        }
        return [] if Work::shouldDisplayWorkItems()
        integersEnumerator = LucilleCore::integerEnumerator()
        NxAfterHours::items()
            .sort{|n1, n2| n1["unixtime"] <=> n2["unixtime"] }
            .reduce([]){|ns16s, item|
                if ns16s.size < 5 then
                    ns16 = NxAfterHours::ns16OrNull(item, integersEnumerator)
                    if ns16 then
                        ns16s << ns16
                    end
                end
                ns16s
            }
    end

    # --------------------------------------------------

    # NxAfterHours::nx19s()
    def self.nx19s()
        NxAfterHours::items().map{|item|
            {
                "uuid"     => item["uuid"],
                "announce" => NxAfterHours::toString(item),
                "lambda"   => lambda { NxAfterHours::run(item) }
            }
        }
    end
end
