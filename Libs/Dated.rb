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
        mapping = CoreData2::getSet(Dated::coreData2SetUUID())
            .map{|atom|
                if atom["date"].nil? then
                    atom["date"] = Utils::today()
                end
                atom
            }
            .reduce({}){|mapping, atom|
                if mapping[atom["date"]].nil? then
                    mapping[atom["date"]] = []
                end
                mapping[atom["date"]] << atom
                mapping
            }
        mapping.keys.sort.map{|date| mapping[date].sort{|i1, i2| i1["unixtime"] <=> i2["unixtime"] } }.flatten
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

    # Dated::interactivelyIssueNewTodayOrNull()
    def self.interactivelyIssueNewTodayOrNull()
        atom = CoreData2::interactivelyCreateANewAtomOrNull([Dated::coreData2SetUUID()])
        return nil if atom.nil?

        atom["date"] = Utils::today()
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
        "[date] (#{atom["date"]}) #{CoreData2::toString(atom).gsub("[atom] ", "")} (#{atom["type"]})"
    end

    # Dated::run(atom)
    def self.run(atom)

        system("clear")

        uuid = atom["uuid"]

        NxBallsService::issue(uuid, Dated::toString(atom), [uuid])

        loop {

            system("clear")

            puts "#{Dated::toString(atom)}#{NxBallsService::runningStringOrEmptyString(" (", uuid, ")")}".green
            puts "DoNotDisplayUntil: #{DoNotShowUntil::getDateTimeOrNull(atom["uuid"])}".yellow

            puts CoreData2::atomPayloadToText(atom)

            note = StructuredTodoTexts::getNoteOrNull(atom["uuid"])
            if note then
                puts "note:\n#{note}".green
            end

            puts "access | <datecode> | note | update description | date | update contents | >todo | exit | destroy (gg)".yellow

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

            if Interpreting::match("date", command) then
                date = Dated::interactivelySelectADateOrNull()
                next if date.nil?
                atom["date"] = date
                CoreData2::commitAtom2(atom)
                break
            end

            if Interpreting::match("update contents", command) then
                atom = CoreData2::interactivelyUpdateAtomTypePayloadPairOrNothing(atom)
                next
            end

            if Interpreting::match(">todo", command) then
                atom["unixtime"] = Nx50s::getNewUnixtime()
                CoreData2::addAtomToSet(atom["uuid"], [Nx50s::coreData2SetUUID()])
                CoreData2::removeAtomFromSet(atom["uuid"], [Dated::coreData2SetUUID()])
                break
            end

            if Interpreting::match("exit", command) then
                break
            end

            if command == "destroy" or command == "gg" then
                Dated::destroy(atom)
                NxBallsService::close(uuid, true)
                break
            end
        }

        NxBallsService::closeWithAsking(uuid)
    end

    # Dated::itemToNS16(item)
    def self.itemToNS16(item)
        {
            "uuid"     => item["uuid"],
            "NS198"    => "ns16:dated1",
            "announce" => Dated::toString(item),
            "commands" => ["..", "redate", "done"],
            "atom"     => item
        }
    end

    # Dated::ns16s()
    def self.ns16s()
        Dated::items()
            .select{|item| DoNotShowUntil::isVisible(item["uuid"]) }
            .select{|item| item["date"] <= Time.new.to_s[0, 10] }
            .map{|item| Dated::itemToNS16(item) }
            .select{|ns16| InternetStatus::ns16ShouldShow(ns16["uuid"]) }
    end

    # Dated::main()
    def self.main()
        loop {
            system("clear")

            items = Dated::items()

            items.each_with_index{|item, indx| 
                puts "[#{indx}] #{Dated::toString(item)}"
            }

            puts "<item index> | (empty) # exit".yellow
            puts UIServices::makersAndDiversCommands().yellow

            command = LucilleCore::askQuestionAnswerAsString("> ")

            break if command == ""

            if (indx = Interpreting::readAsIntegerOrNull(command)) then
                item = items[indx]
                next if item.nil?
                Dated::run(item)
            end
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
