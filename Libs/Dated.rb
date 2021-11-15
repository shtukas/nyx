# encoding: UTF-8

class Dated # OnDate

    # Dated::coreData2SetUUID()
    def self.coreData2SetUUID()
        "catalyst:908fffc7-19a5-41cc-a2ff-e316711b373f"
    end

    # Dated::getDatedByUUIDOrNull(atomuuid)
    def self.getDatedByUUIDOrNull(atomuuid)
        CoreData2::getAtomOrNull(atomuuid)
    end

    # Dated::items()
    def self.items()
        CoreData2::getSet(Dated::coreData2SetUUID())
            .map{|atom|
                if atom["date"].nil? then
                    atom["date"] = Utils::today()
                end
                atom
            }
    end

    # Dated::interactivelySelectADateOrNull()
    def self.interactivelySelectADateOrNull()
        datecode = LucilleCore::askQuestionAnswerAsString("date code +<weekdayname>, +<integer>day(s), +YYYY-MM-DD (empty to abort): ")
        unixtime = Utils::codeToUnixtimeOrNull(datecode)
        return nil if unixtime.nil?
        Time.at(unixtime).to_s[0, 10]
    end

    # Dated::interactivelyIssueNewOrNull()
    def self.interactivelyIssueNewOrNull()
        date = Dated::interactivelySelectADateOrNull()
        return nil if date.nil?

        atom = CoreData2::interactivelyCreateANewAtomOrNull([Dated::coreData2SetUUID()])
        return nil if atom.nil?

        atom["date"] = date
        CoreData2::commitAtom2(atom)
        atom
    end

    # Dated::issueItemUsingText(text, unixtime, date)
    def self.issueItemUsingText(text, unixtime, date)
        text = text.strip
        return if text.size == 0
        description = text.lines.first.strip
        atom = CoreData2::issueTextAtomUsingText(SecureRandom.uuid, description, text, [Dated::coreData2SetUUID()])
        atom["date"] = date
        CoreData2::commitAtom2(atom)
        atom
    end

    # Dated::destroy(atom)
    def self.destroy(atom)
        CoreData2::removeAtomFromSet(atom["uuid"], Dated::coreData2SetUUID())
    end

    # -------------------------------------
    # Operations

    # Dated::toString(atom)
    def self.toString(atom)
        "[date] (#{atom["date"]}) #{CoreData2::toString(atom)}"
    end

    # Dated::run(atom)
    def self.run(atom)

        system("clear")

        uuid = atom["uuid"]

        puts "running #{Dated::toString(atom)}".green
        puts "DoNotDisplayUntil: #{DoNotShowUntil::getDateTimeOrNull(atom["uuid"])}".yellow
        puts "Starting at #{Time.new.to_s}"

        nxball = NxBalls::makeNxBall([uuid])

        thr = Thread.new {
            loop {
                sleep 60
                if (Time.new.to_i - nxball["cursorUnixtime"]) >= 600 then
                    nxball = NxBalls::upgradeNxBall(nxball, false)
                end
            }
        }

        puts "note:\n#{StructuredTodoTexts::getNoteOrNull(atom["uuid"])}".green

        loop {

            system("clear")

            puts "running #{Dated::toString(atom)}".green
            puts "DoNotDisplayUntil: #{DoNotShowUntil::getDateTimeOrNull(atom["uuid"])}".yellow

            puts "note:\n#{StructuredTodoTexts::getNoteOrNull(atom["uuid"])}".green

            puts "access | <datecode> | note | update description | update date | update contents | >todo | exit | destroy".yellow

            command = LucilleCore::askQuestionAnswerAsString("> ")

            if Interpreting::match("access", command) then
                CoreData2::accessWithOptionToEdit(atom)
                next
            end

            if (unixtime = Utils::codeToUnixtimeOrNull(command.gsub(" ", ""))) then
                DoNotShowUntil::setUnixtime(atom["uuid"], unixtime)
                break
            end

            if Interpreting::match("note", command) then
                note = Utils::editTextSynchronously(StructuredTodoTexts::getNoteOrNull(atom["uuid"]) || "")
                StructuredTodoTexts::setNote(atom["uuid"], note)
                next
            end

            if Interpreting::match("update description", command) then
                description = LucilleCore::askQuestionAnswerAsString("description: ")
                return if description == ""
                atom["description"] = description
                CoreData2::commitAtom2(atom)
                next
            end

            if Interpreting::match("update date", command) then
                date = Dated::interactivelySelectADateOrNull()
                next if date.nil?
                atom["date"] = date
                CoreData2::commitAtom2(atom)
                next
            end

            if Interpreting::match("update contents", command) then
                atom = CoreData2::interactivelyUpdateAtomTypePayloadPairOrNothing(atom)
                next
            end

            if Interpreting::match(">todo", command) then
                domain = Domain::interactivelySelectDomain()
                atom["unixtime"] = Nx50s::interactivelyDetermineNewItemUnixtime(domain)
                CoreData2::addAtomToSet(atom["uuid"], [Nx50s::coreData2SetUUID()])
                CoreData2::removeAtomFromSet(atom["uuid"], [Dated::coreData2SetUUID()])
                break
            end

            if Interpreting::match("exit", command) then
                return
            end

            if Interpreting::match("destroy", command) then
                Dated::destroy(atom)
                break
            end
        }

        thr.exit

        NxBalls::closeNxBall(nxball, true)
    end

    # Dated::itemToNS16(item)
    def self.itemToNS16(item)
        {
            "uuid"        => item["uuid"],
            "announce"    => Dated::toString(item),
            "commands"    => ["..", "redate", "done"],
            "interpreter" => lambda {|command|
                if command == ".." then
                    Dated::run(item)
                end
                if command == "redate" then
                    date = Dated::interactivelySelectADateOrNull()
                    return if date.nil?
                    item["date"] = date
                    puts JSON.pretty_generate(item)
                    CoreData2::commitAtom2(item)
                end
                if command == "done" then
                    if LucilleCore::askQuestionAnswerAsBoolean("done '#{Dated::toString(item)}' ? ", true) then
                        Dated::destroy(item)
                    end
                end
            },
            "run" => lambda {
                Dated::run(item)
            }
        }
    end

    # Dated::ns16s()
    def self.ns16s()
        Dated::items()
            .select{|item| DoNotShowUntil::isVisible(item["uuid"]) }
            .select{|item| item["date"] <= Time.new.to_s[0, 10] }
            .sort{|i1, i2| i1["date"] <=> i2["date"] }
            .map{|item| Dated::itemToNS16(item) }
            .select{|ns16| InternetStatus::ns16ShouldShow(ns16["uuid"]) }
    end

    # Dated::main()
    def self.main()
        loop {
            system("clear")

            items = Dated::items()
                        .sort{|i1, i2| i1["date"] <=> i2["date"] }

            items.each_with_index{|item, indx| 
                puts "[#{indx}] #{Dated::toString(item)}"
            }

            puts "<item index> | (empty) # exit".yellow
            puts Interpreters::makersAndDiversCommands().yellow

            command = LucilleCore::askQuestionAnswerAsString("> ")

            break if command == ""

            if (indx = Interpreting::readAsIntegerOrNull(command)) then
                item = items[indx]
                next if item.nil?
                Dated::run(item)
            end

            Interpreters::makersAndDiversInterpreter(command)
        }
    end

    # Dated::nx19s()
    def self.nx19s()
        Dated::items().map{|item|
            {
                "uuid"     => item["uuid"],
                "announce" => Dated::toString(item),
                "lambda"   => lambda { Dated::run(item) }
            }
        }
    end
end
