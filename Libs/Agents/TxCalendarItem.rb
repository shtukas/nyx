# encoding: UTF-8

class TxCalendarItems

    # TxCalendarItems::items()
    def self.items()
        LibrarianObjects::getObjectsByMikuType("TxCalendarItem")
    end

    # TxCalendarItems::destroy(uuid)
    def self.destroy(uuid)
        LibrarianObjects::destroy(uuid)
    end

    # --------------------------------------------------
    # Makers

    # TxCalendarItems::interactivelyDecideDateAndTime()
    def self.interactivelyDecideDateAndTime()
        date = LucilleCore::askQuestionAnswerAsString("date (YYYY-MM-DD): ")
        time = LucilleCore::askQuestionAnswerAsString("time (HH:MM): ")
        {
            "date" => date,
            "time" => time
        }
    end

    # TxCalendarItems::interactivelyCreateNewOrNull()
    def self.interactivelyCreateNewOrNull()
        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return nil if description == ""

        dateAndTime = TxCalendarItems::interactivelyDecideDateAndTime()

        atom = CoreData5::interactivelyCreateNewAtomOrNull()
        return nil if atom.nil?

        LibrarianObjects::commit(atom)

        uuid = SecureRandom.uuid

        item = {
          "uuid"        => uuid,
          "mikuType"    => "TxCalendarItem",
          "description" => description,
          "date"        => dateAndTime["date"],
          "time"        => dateAndTime["time"],
          "atomuuid"    => atom["uuid"],
        }
        LibrarianObjects::commit(item)
        item
    end

    # --------------------------------------------------
    # toString

    # TxCalendarItems::toString(item)
    def self.toString(item)
        "(calendar) [#{item["date"]}] (#{item["time"]}) #{item["description"]}#{AgentsUtils::atomTypeForToStrings(" ", item["atomuuid"])}"
    end

    # TxCalendarItems::toStringForNS19(item)
    def self.toStringForNS19(item)
        "[cale] #{item["description"]}"
    end

    # --------------------------------------------------
    # Operations

    # TxCalendarItems::run(item)
    def self.run(item)

        system("clear")

        uuid = item["uuid"]

        loop {

            system("clear")

            puts TxCalendarItems::toString(item).green
            puts "uuid: #{uuid}".yellow
            puts "date: #{item["date"]}".yellow
            puts "time: #{item["time"]}".yellow

            LibrarianNotes::getObjectNotes(uuid).each{|note|
                puts "note: #{note["text"]}"
            }

            AgentsUtils::atomLandingPresentation(item["atomuuid"])

            puts "access | datetime | description | atom | note | show json | destroy (gg) | exit (xx)".yellow

            command = LucilleCore::askQuestionAnswerAsString("> ")

            break if command == "exit"
            break if command == "xx"

            if Interpreting::match("access", command) then
                AgentsUtils::accessAtom(item["atomuuid"])
                next
            end

            if Interpreting::match("datetime", command) then
                dateAndTime = TxCalendarItems::interactivelyDecideDateAndTime()
                item["date"] = dateAndTime["date"]
                item["time"] = dateAndTime["time"]
                LibrarianObjects::commit(item)
                next
            end

            if Interpreting::match("description", command) then
                description = Utils::editTextSynchronously(item["description"]).strip
                next if description == ""
                item["description"] = description
                LibrarianObjects::commit(item)
                next
            end

            if Interpreting::match("atom", command) then
                atom = CoreData5::interactivelyCreateNewAtomOrNull()
                next if atom.nil?
                atom["uuid"] = item["atomuuid"]
                LibrarianObjects::commit(atom)
                next
            end

            if Interpreting::match("note", command) then
                text = Utils::editTextSynchronously("").strip
                LibrarianNotes::addNote(item["uuid"], text)
                next
            end

            if Interpreting::match("show json", command) then
                puts JSON.pretty_generate(item)
                LucilleCore::pressEnterToContinue()
                break
            end

            if command == "destroy" then
                if LucilleCore::askQuestionAnswerAsBoolean("destroy '#{TxCalendarItems::toString(item)}' ? ", true) then
                    TxCalendarItems::destroy(item["uuid"])
                    break
                end
                next
            end

            if command == "gg" then
                if LucilleCore::askQuestionAnswerAsBoolean("destroy '#{TxCalendarItems::toString(item)}' ? ", true) then
                    TxCalendarItems::destroy(item["uuid"])
                    break
                end
                next
            end
        }
    end

    # TxCalendarItems::dive()
    def self.dive()
        loop {
            system("clear")
            items = TxCalendarItems::items().sort{|i1, i2| "#{i1["date"]} #{i1["time"]}" <=> "#{i2["date"]} #{i2["time"]}" }
            item = LucilleCore::selectEntityFromListOfEntitiesOrNull("calendar item", items, lambda{|item| TxCalendarItems::toString(item) })
            break if item.nil?
            TxCalendarItems::run(item)
        }
    end

    # --------------------------------------------------
    # nx16s

    # TxCalendarItems::ns16(item)
    def self.ns16(item)
        uuid = item["uuid"]
        {
            "uuid"     => uuid,
            "NS198"    => "NS16:TxCalendarItem",
            "announce" => "(calendar) [#{item["date"]}] (#{item["time"]}) #{item["description"]}#{AgentsUtils::atomTypeForToStrings(" ", item["atomuuid"])}",
            "commands" => ["..", "done", "redate", "transmute"],
            "item"     => item
        }
    end

    # TxCalendarItems::ns16s()
    def self.ns16s()
        TxCalendarItems::items()
            .select{|item| item["date"] <= Utils::today() }
            .sort{|i1, i2| "#{i1["date"]} #{i1["time"]}" <=> "#{i2["date"]} #{i2["time"]}" }
            .map{|item| TxCalendarItems::ns16(item) }
    end

    # --------------------------------------------------

    # TxCalendarItems::nx19s()
    def self.nx19s()
        TxCalendarItems::items().map{|item|
            {
                "uuid"     => item["uuid"],
                "announce" => TxCalendarItems::toStringForNS19(item),
                "lambda"   => lambda { TxCalendarItems::run(item) }
            }
        }
    end
end
