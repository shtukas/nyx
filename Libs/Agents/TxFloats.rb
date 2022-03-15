j# encoding: UTF-8

class TxFloats

    # TxFloats::items()
    def self.items()
        Librarian6Objects::getObjectsByMikuType("TxFloat")
    end

    # TxFloats::destroy(uuid)
    def self.destroy(uuid)
        Librarian6Objects::destroy(uuid)
    end

    # --------------------------------------------------
    # Makers

    # TxFloats::interactivelyCreateNewOrNull()
    def self.interactivelyCreateNewOrNull()
        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return nil if description == ""

        atom = Librarian5Atoms::interactivelyCreateNewAtomOrNull()
        return nil if atom.nil?

        Librarian6Objects::commit(atom)

        uuid     = SecureRandom.uuid
        unixtime = Time.new.to_i
        datetime = Time.new.utc.iso8601

        item = {
          "uuid"        => uuid,
          "mikuType"    => "TxFloat",
          "description" => description,
          "unixtime"    => unixtime,
          "datetime"    => datetime,
          "atomuuid"    => atom["uuid"]
        }
        Librarian6Objects::commit(item)
        ObjectUniverseMapping::interactivelySetObjectUniverseMapping(uuid)
        item
    end

    # --------------------------------------------------
    # toString

    # TxFloats::toString(float)
    def self.toString(float)
        "[floa] #{float["description"]}#{AgentsUtils::atomTypeForToStrings(" ", float["atomuuid"])}"
    end

    # TxFloats::toStringForNS19(float)
    def self.toStringForNS19(float)
        "[floa] #{float["description"]}"
    end

    # --------------------------------------------------
    # Operations

    # TxFloats::complete(float)
    def self.complete(float)
        TxFloats::destroy(float["uuid"])
    end

    # TxFloats::landing(float)
    def self.landing(float)

        system("clear")

        uuid = float["uuid"]

        loop {

            system("clear")

            puts TxFloats::toString(float).green
            puts "uuid: #{uuid}".yellow

            Librarian7Notes::getObjectNotes(uuid).each{|note|
                puts "note: #{note["text"]}"
            }

            AgentsUtils::atomLandingPresentation(float["atomuuid"])

            puts "access | <datecode> | description | atom | note | notes | universe | transmute | show json | >nyx |destroy (gg) | exit (xx)".yellow

            command = LucilleCore::askQuestionAnswerAsString("> ")

            break if command == "exit"
            break if command == "xx"

            if (unixtime = Utils::codeToUnixtimeOrNull(command.gsub(" ", ""))) then
                DoNotShowUntil::setUnixtime(uuid, unixtime)
                break
            end

            if Interpreting::match("access", command) then
                AgentsUtils::accessAtom(float["atomuuid"])
                next
            end

            if Interpreting::match("description", command) then
                description = Utils::editTextSynchronously(float["description"]).strip
                next if description == ""
                float["description"] = description
                Librarian6Objects::commit(float)
                next
            end

            if Interpreting::match("atom", command) then
                atom = Librarian5Atoms::interactivelyCreateNewAtomOrNull()
                next if atom.nil?
                atom["uuid"] = float["atomuuid"]
                Librarian6Objects::commit(atom)
                next
            end

            if Interpreting::match("note", command) then
                text = Utils::editTextSynchronously("").strip
                Librarian7Notes::addNote(float["uuid"], text)
                next
            end

            if Interpreting::match("notes", command) then
                Librarian7Notes::notesLanding(float["uuid"])
                next
            end

            if Interpreting::match("universe", command) then
                ObjectUniverseMapping::interactivelySetObjectUniverseMapping(float["uuid"])
                break
            end

            if Interpreting::match("transmute", command) then
                Transmutation::transmutation2(float, "TxFloat")
                break
            end

            if Interpreting::match("show json", command) then
                puts JSON.pretty_generate(float)
                LucilleCore::pressEnterToContinue()
                break
            end

            if command == "destroy" then
                if LucilleCore::askQuestionAnswerAsBoolean("destroy '#{TxFloats::toString(float)}' ? ", true) then
                    TxFloats::complete(float)
                    break
                end
                next
            end

            if command == "gg" then
                if LucilleCore::askQuestionAnswerAsBoolean("destroy '#{TxFloats::toString(float)}' ? ", true) then
                    TxFloats::complete(float)
                    break
                end
                next
            end

            if command == ">nyx" then
                NyxAdapter::floatToNyx(float)
                break
            end
        }
    end

    # --------------------------------------------------
    # nx16s

    # TxFloats::ns16(float)
    def self.ns16(float)
        uuid = float["uuid"]
        {
            "uuid"     => uuid,
            "mikuType" => "NS16:TxFloat",
            "announce" => "#{float["description"]}#{AgentsUtils::atomTypeForToStrings(" ", float["atomuuid"])}",
            "TxFloat"  => float
        }
    end

    # TxFloats::ns16s(universe)
    def self.ns16s(universe)
        return [] if universe.nil?
        TxFloats::items()
            .select{|item| 
                objuniverse = ObjectUniverseMapping::getObjectUniverseMappingOrNull(item["uuid"])
                universe.nil? or objuniverse.nil? or (objuniverse == universe)
            }
            .sort{|i1, i2| i1["unixtime"] <=> i2["unixtime"] }
            .map{|item| TxFloats::ns16(item) }
    end

    # --------------------------------------------------

    # TxFloats::nx19s()
    def self.nx19s()
        TxFloats::items().map{|item|
            {
                "uuid"     => item["uuid"],
                "announce" => TxFloats::toStringForNS19(item),
                "lambda"   => lambda { TxFloats::landing(item) }
            }
        }
    end
end
