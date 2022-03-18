j# encoding: UTF-8

class TxFyres

    # TxFyres::mikus()
    def self.mikus()
        Librarian6Objects::getObjectsByMikuType("TxFyre")
    end

    # TxFyres::destroy(uuid)
    def self.destroy(uuid)
        Librarian6Objects::destroy(uuid)
    end

    # --------------------------------------------------
    # Makers

    # TxFyres::interactivelyCreateNewOrNull()
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
          "mikuType"    => "TxFyre",
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

    # TxFyres::toString(nx70)
    def self.toString(nx70)
        "[fyre] #{nx70["description"]}#{Libriarian16SpecialCircumstances::atomTypeForToStrings(" ", nx70["atomuuid"])}"
    end

    # TxFyres::toStringForNS16(nx70, rt)
    def self.toStringForNS16(nx70, rt)
        "[fyre] (#{"%4.2f" % rt}) #{nx70["description"]}#{Libriarian16SpecialCircumstances::atomTypeForToStrings(" ", nx70["atomuuid"])}"
    end

    # TxFyres::toStringForNS19(nx70)
    def self.toStringForNS19(nx70)
        "[fyre] #{nx70["description"]}"
    end

    # --------------------------------------------------
    # Operations

    # TxFyres::complete(nx70)
    def self.complete(nx70)
        TxFyres::destroy(nx70["uuid"])
    end

    # TxFyres::landing(nx70)
    def self.landing(nx70)

        system("clear")

        uuid = nx70["uuid"]

        loop {

            system("clear")

            puts TxFyres::toString(nx70).green
            puts "uuid: #{uuid}".yellow
            puts "RT: #{BankExtended::stdRecoveredDailyTimeInHours(uuid)}".yellow

            Librarian7Notes::getObjectNotes(uuid).each{|note|
                puts "note: #{note["text"]}"
            }

            Libriarian16SpecialCircumstances::atomLandingPresentation(nx70["atomuuid"])

            #Librarian::notes(uuid).each{|note|
            #    puts "note: #{note["text"]}"
            #}

            puts "access | <datecode> | description | atom | note | notes | show json | universe | transmute | destroy (gg) | exit (xx)".yellow

            command = LucilleCore::askQuestionAnswerAsString("> ")

            break if command == "exit"
            break if command == "xx"

            if (unixtime = Utils::codeToUnixtimeOrNull(command.gsub(" ", ""))) then
                DoNotShowUntil::setUnixtime(uuid, unixtime)
                break
            end

            if Interpreting::match("access", command) then
                Libriarian16SpecialCircumstances::accessAtom(nx70["atomuuid"])
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

            if Interpreting::match("notes", command) then
                Librarian7Notes::notesLanding(nx70["uuid"])
                next
            end

            if Interpreting::match("transmute", command) then
                Transmutation::transmutation2(nx70, "TxFyre")
                break
            end

            if Interpreting::match("universe", command) then
                ObjectUniverseMapping::interactivelySetObjectUniverseMapping(nx70["uuid"])
                next
            end

            if Interpreting::match("show json", command) then
                puts JSON.pretty_generate(nx70)
                LucilleCore::pressEnterToContinue()
                break
            end

            if command == "destroy" then
                if LucilleCore::askQuestionAnswerAsBoolean("destroy '#{TxFyres::toString(nx70)}' ? ", true) then
                    TxFyres::complete(nx70)
                    break
                end
                next
            end

            if command == "gg" then
                if LucilleCore::askQuestionAnswerAsBoolean("destroy '#{TxFyres::toString(nx70)}' ? ", true) then
                    TxFyres::complete(nx70)
                    break
                end
                next
            end
        }
    end

    # --------------------------------------------------
    # nx16s

    # TxFyres::ns16(nx70)
    def self.ns16(nx70)
        uuid = nx70["uuid"]
        rt = BankExtended::stdRecoveredDailyTimeInHours(uuid)
        announce = TxFyres::toStringForNS16(nx70, rt)
        if rt < 1 then
            announce = announce.red
        end
        {
            "uuid"     => uuid,
            "mikuType" => "NS16:TxFyre",
            "announce" => announce,
            "TxFyre"   => nx70,
            "rt"       => rt
        }
    end

    # TxFyres::ns16s(universe)
    def self.ns16s(universe)
        TxFyres::mikus()
            .select{|item| 
                objuniverse = ObjectUniverseMapping::getObjectUniverseMappingOrNull(item["uuid"])
                universe.nil? or objuniverse.nil? or (objuniverse == universe)
            }
            .map{|item| TxFyres::ns16(item) }
            .sort{|x1, x2| x1["rt"] <=> x2["rt"]}
    end

    # --------------------------------------------------

    # TxFyres::nx19s()
    def self.nx19s()
        TxFyres::mikus().map{|item|
            {
                "uuid"     => item["uuid"],
                "announce" => TxFyres::toStringForNS19(item),
                "lambda"   => lambda { TxFyres::landing(item) }
            }
        }
    end
end
