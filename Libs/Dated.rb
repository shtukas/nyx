# encoding: UTF-8

class Dated # OnDate

    # Dated::setuuid()
    def self.setuuid()
        "catalyst:908fffc7-19a5-41cc-a2ff-e316711b373f"
    end

    # Dated::getDatedByUUIDOrNull(atomuuid)
    def self.getDatedByUUIDOrNull(atomuuid)
        ObjectStore4::getObjectByUUIDOrNull(atomuuid)
    end

    # Dated::items()
    def self.items()
        mapping = ObjectStore4::getSet(Dated::setuuid())
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

    # Dated::itemsForDomain(domain)
    def self.itemsForDomain(domain)
        Dated::items().select{|item|
            item["domain"].nil? or (item["domain"] == domain)
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

        item = CoreData3::interactivelyCreateNewAtomOrNull()
        return nil if item.nil?

        item["date"] = date
        ObjectStore4::store(item, Dated::setuuid())
        item
    end

    # Dated::interactivelyIssueNewTodayOrNull()
    def self.interactivelyIssueNewTodayOrNull()
        item = CoreData3::interactivelyCreateNewAtomOrNull()
        return nil if item.nil?

        item["date"] = Utils::today()
        ObjectStore4::store(item, Dated::setuuid())
        item
    end

    # Dated::issueItemUsingText(text, unixtime, date)
    def self.issueItemUsingText(text, unixtime, date)
        text = text.strip
        return if text.size == 0
        description = text.lines.first.strip
        item = CoreData3::issueTextAtomUsingText(SecureRandom.uuid, description, text)
        item["date"] = date
        ObjectStore4::store(item, Dated::setuuid())
        item
    end

    # Dated::destroy(item)
    def self.destroy(item)
        ObjectStore4::removeObjectFromSet(Dated::setuuid(), item["uuid"])
    end

    # -------------------------------------
    # Operations

    # Dated::toString(item)
    def self.toString(item)
        "[date] (#{item["date"]}) #{CoreData3::toString(item).gsub("[atom] ", "")} (#{item["type"]})"
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

            puts CoreData3::atomPayloadToText(atom)

            note = StructuredTodoTexts::getNoteOrNull(atom["uuid"])
            if note then
                puts "note:\n#{note}".green
            end

            puts "access | <datecode> | note | description | date | domain | update contents | >todo | exit (xx) | destroy (gg)".yellow

            command = LucilleCore::askQuestionAnswerAsString("> ")

            if Interpreting::match("access", command) then
                CoreData3::accessWithOptionToEdit(atom)
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

            if Interpreting::match("description", command) then
                description = LucilleCore::askQuestionAnswerAsString("description: ")
                return if description == ""
                atom["description"] = description
                ObjectStore4::store(atom, Dated::setuuid())
                next
            end

            if Interpreting::match("domain", command) then
                atom["domain"] = Domain::interactivelySelectDomainOrNull()
                ObjectStore4::store(atom, Dated::setuuid())
                break
            end

            if Interpreting::match("date", command) then
                date = Dated::interactivelySelectADateOrNull()
                next if date.nil?
                atom["date"] = date
                ObjectStore4::store(atom, Dated::setuuid())
                break
            end

            if Interpreting::match("update contents", command) then
                atom = CoreData3::interactivelyMakeNewContentOrIdentity(atom)
                ObjectStore4::store(atom, Dated::setuuid())
                next
            end

            if Interpreting::match(">todo", command) then
                atom["unixtime"] = Time.new.to_f
                CoreData2::addAtomToSet(atom["uuid"], [Nx50s::setuuid()])
                ObjectStore4::removeObjectFromSet(Dated::setuuid(), atom["uuid"])
                break
            end

            if Interpreting::match("exit", command) or command == "xx" then
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
            "commands" => ["..", "redate", "domain", "done"],
            "atom"     => item
        }
    end

    # Dated::ns16s(domain)
    def self.ns16s(domain)
        Dated::itemsForDomain(domain)
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
