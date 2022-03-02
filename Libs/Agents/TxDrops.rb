j# encoding: UTF-8

class TxDrops

    # TxDrops::mikus()
    def self.mikus()
        Librarian6Objects::getObjectsByMikuType("TxDrop")
    end

    # TxDrops::destroy(uuid)
    def self.destroy(uuid)
        Librarian6Objects::destroy(uuid)
    end

    # --------------------------------------------------
    # Makers

    # TxDrops::interactivelyCreateNewOrNull()
    def self.interactivelyCreateNewOrNull()
        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return nil if description == ""

        atom       = Librarian5Atoms::interactivelyCreateNewAtomOrNull()
        return nil if atom.nil?

        Librarian6Objects::commit(atom)

        uuid       = SecureRandom.uuid
        unixtime   = Time.new.to_i
        datetime   = Time.new.utc.iso8601

        item = {
          "uuid"        => uuid,
          "mikuType"    => "TxDrop",
          "description" => description,
          "unixtime"    => unixtime,
          "datetime"    => datetime,
          "atomuuid"    => atom["uuid"]
        }
        Librarian6Objects::commit(item)
        item
    end

    # --------------------------------------------------
    # toString

    # TxDrops::toString(nx70)
    def self.toString(nx70)
        "[drop] #{nx70["description"]}#{AgentsUtils::atomTypeForToStrings(" ", nx70["atomuuid"])}"
    end

    # TxDrops::toStringForNS19(nx70)
    def self.toStringForNS19(nx70)
        "[drop] #{nx70["description"]}"
    end

    # --------------------------------------------------
    # Operations

    # TxDrops::complete(nx70)
    def self.complete(nx70)
        TxDrops::destroy(nx70["uuid"])
    end

    # TxDrops::access(nx70)
    def self.access(nx70)

        system("clear")

        uuid = nx70["uuid"]

        loop {

            system("clear")

            puts TxDrops::toString(nx70).green
            puts "uuid: #{uuid}".yellow
            puts "RT: #{BankExtended::stdRecoveredDailyTimeInHours(uuid)}".yellow

            Librarian7Notes::getObjectNotes(uuid).each{|note|
                puts "note: #{note["text"]}"
            }

            AgentsUtils::atomLandingPresentation(nx70["atomuuid"])

            #Librarian::notes(uuid).each{|note|
            #    puts "note: #{note["text"]}"
            #}

            puts "access | <datecode> | description | atom | note | show json | transmute | destroy (gg) | exit (xx)".yellow

            command = LucilleCore::askQuestionAnswerAsString("> ")

            break if command == "exit"
            break if command == "xx"

            if (unixtime = Utils::codeToUnixtimeOrNull(command.gsub(" ", ""))) then
                DoNotShowUntil::setUnixtime(uuid, unixtime)
                break
            end

            if Interpreting::match("access", command) then
                AgentsUtils::accessAtom(nx70["atomuuid"])
                next
            end

            if Interpreting::match("description", command) then
                description = Utils::editTextSynchronously(nx70["description"]).strip
                next if description == ""
                nx70["description"] = description
                Librarian6Objects::commit(nx70)
                next
            end

            if Interpreting::match("atom", command) then
                atom = Librarian5Atoms::interactivelyCreateNewAtomOrNull()
                next if atom.nil?
                atom["uuid"] = nx70["atomuuid"]
                Librarian6Objects::commit(atom)
                next
            end

            if Interpreting::match("note", command) then
                text = Utils::editTextSynchronously("").strip
                Librarian7Notes::addNote(nx70["uuid"], text)
                next
            end

            if Interpreting::match("transmute", command) then
                TerminalUtils::transmutation2(nx70, "TxDrop")
                break
            end

            if Interpreting::match("show json", command) then
                puts JSON.pretty_generate(nx70)
                LucilleCore::pressEnterToContinue()
                break
            end

            if command == "destroy" then
                if LucilleCore::askQuestionAnswerAsBoolean("destroy '#{TxDrops::toString(nx70)}' ? ", true) then
                    TxDrops::complete(nx70)
                    break
                end
                next
            end

            if command == "gg" then
                if LucilleCore::askQuestionAnswerAsBoolean("destroy '#{TxDrops::toString(nx70)}' ? ", true) then
                    TxDrops::complete(nx70)
                    break
                end
                next
            end
        }
    end

    # --------------------------------------------------
    # nx16s

    # TxDrops::ns16(nx70)
    def self.ns16(nx70)
        uuid = nx70["uuid"]
        rt = BankExtended::stdRecoveredDailyTimeInHours(uuid)
        {
            "uuid"     => uuid,
            "mikuType" => "NS16:TxDrop",
            "announce" => "(drop) #{nx70["description"]}#{AgentsUtils::atomTypeForToStrings(" ", nx70["atomuuid"])}",
            "commands" => ["..", "done", "transmute"],
            "TxDrop"   => nx70,
            "rt"       => rt
        }
    end

    # TxDrops::ns16s(universe)
    def self.ns16s(universe)
        TxDrops::mikus()
            .select{|item| Multiverse::getUniverseOrDefault(item["uuid"]) == universe }
            .map{|item| TxDrops::ns16(item) }
    end

    # TxDrops::ns16sOverflowing(universe)
    def self.ns16sOverflowing(universe)
        TxDrops::mikus()
            .select{|item| Multiverse::getUniverseOrDefault(item["uuid"]) == universe }
            .map{|item| TxDrops::ns16(item) }
            .select{|ns16| ns16["rt"] > 1 }
    end

    # --------------------------------------------------

    # TxDrops::nx19s()
    def self.nx19s()
        TxDrops::mikus().map{|item|
            {
                "uuid"     => item["uuid"],
                "announce" => TxDrops::toStringForNS19(item),
                "lambda"   => lambda { TxDrops::access(item) }
            }
        }
    end
end
