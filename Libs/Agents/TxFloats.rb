j# encoding: UTF-8

class TxFloats

    # TxFloats::shapeX()
    def self.shapeX()
        [
            ["uuid"           , "string"],
            ["description"    , "string"],
            ["unixtime"       , "float"],
            ["datetime"       , "string"],
            ["classification" , "string"],
            ["atom"           , "json"],
            ["domainx"        , "string"],
        ]
    end

    # TxFloats::items()
    def self.items()
        Librarian::classifierToShapeXeds("TxFloat", TxFloats::shapeX())
    end

    # TxFloats::destroy(uuid)
    def self.destroy(uuid)
        Librarian::destroy(uuid)
    end

    # --------------------------------------------------
    # Makers

    # TxFloats::interactivelyCreateNewOrNull()
    def self.interactivelyCreateNewOrNull()
        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return nil if description == ""

        uuid       = SecureRandom.uuid
        unixtime   = Time.new.to_i
        datetime   = Time.new.utc.iso8601
        classifier = "TxFloat"
        atom       = Atoms5::interactivelyCreateNewAtomOrNull()
        domainx    = DomainsX::interactivelySelectDomainX()

        Librarian::issueNewFileMxClassic(uuid, description, unixtime, datetime, classifier, atom, domainx, 0)

        Librarian::getMikuOrNull(uuid)
    end

    # --------------------------------------------------
    # toString

    # TxFloats::toString(mx48)
    def self.toString(mx48)
        "[floa] #{mx48["description"]} (#{mx48["atom"]["type"]})"
    end

    # TxFloats::toStringForNS19(mx48)
    def self.toStringForNS19(mx48)
        "[floa] #{mx48["description"]}"
    end

    # --------------------------------------------------
    # Operations

    # TxFloats::complete(mx48)
    def self.complete(mx48)
        TxFloats::destroy(mx48["uuid"])
    end

    # TxFloats::run(mx48)
    def self.run(mx48)

        system("clear")

        uuid = mx48["uuid"]

        NxBallsService::issue(
            uuid, 
            TxFloats::toString(mx48), 
            [uuid, DomainsX::domainXToAccountNumber(mx48["domainx"])]
        )

        loop {

            system("clear")

            puts TxFloats::toString(mx48).green
            puts "uuid: #{uuid}".yellow
            puts "domain: #{mx48["domainx"]}".yellow

            if text = Atoms5::atomPayloadToTextOrNull(mx48["atom"]) then
                puts "text:\n#{text}"
            end

            Librarian::notes(uuid).each{|note|
                puts "note: #{note["text"]}"
            }

            puts "access | <datecode> | description | atom | note | show json | destroy (gg) | exit (xx)".yellow

            command = LucilleCore::askQuestionAnswerAsString("> ")

            break if command == "exit"
            break if command == "xx"

            if (unixtime = Utils::codeToUnixtimeOrNull(command.gsub(" ", ""))) then
                DoNotShowUntil::setUnixtime(uuid, unixtime)
                break
            end

            if Interpreting::match("access", command) then
                Librarian::accessMikuAtom(mx48)
                mx48 = Librarian::getMikuOrNull(mx48["uuid"])
                next
            end

            if Interpreting::match("description", command) then
                description = Utils::editTextSynchronously(mx48["description"]).strip
                next if description == ""
                mx48["description"] = description
                Librarian::setValue(mx48["uuid"], "description", description)
                next
            end

            if Interpreting::match("atom", command) then
                atom = Atoms5::interactivelyCreateNewAtomOrNull()
                next if atom.nil?
                Librarian::setValue(mx48["uuid"], "atom", JSON.generate(atom))
                mx48["atom"] = atom
                next
            end

            if Interpreting::match("note", command) then
                text = Utils::editTextSynchronously("").strip
                Librarian::addNote(mx48["uuid"], SecureRandom.uuid, Time.new.to_i, text)
                next
            end

            if Interpreting::match("show json", command) then
                puts JSON.pretty_generate(mx48)
                LucilleCore::pressEnterToContinue()
                break
            end

            if command == "destroy" then
                if LucilleCore::askQuestionAnswerAsBoolean("destroy '#{TxFloats::toString(mx48)}' ? ", true) then
                    TxFloats::complete(mx48)
                    break
                end
                next
            end

            if command == "gg" then
                if LucilleCore::askQuestionAnswerAsBoolean("destroy '#{TxFloats::toString(mx48)}' ? ", true) then
                    TxFloats::complete(mx48)
                    break
                end
                next
            end
        }

        NxBallsService::closeWithAsking(uuid)
    end

    # --------------------------------------------------
    # nx16s

    # TxFloats::ns16(mx48)
    def self.ns16(mx48)
        uuid = mx48["uuid"]
        ItemStoreOps::delistForDefault(uuid)
        {
            "uuid"     => uuid,
            "NS198"    => "NS16:TxFloat",
            "announce" => "#{mx48["description"]} (#{mx48["atom"]["type"]})",
            "commands" => [],
            "TxFloat"     => mx48
        }
    end

    # TxFloats::ns16s()
    def self.ns16s()
        TxFloats::items()
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
                "lambda"   => lambda { TxFloats::run(item) }
            }
        }
    end
end
