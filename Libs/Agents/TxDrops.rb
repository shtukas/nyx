j# encoding: UTF-8

class TxDrops

    # TxDrops::shapeX()
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

    # TxDrops::mikus()
    def self.mikus()
        Librarian::classifierToShapeXeds("TxDrop", TxDrops::shapeX())
    end

    # TxDrops::destroy(uuid)
    def self.destroy(uuid)
        Librarian::destroy(uuid)
    end

    # --------------------------------------------------
    # Makers

    # TxDrops::interactivelyCreateNewOrNull()
    def self.interactivelyCreateNewOrNull()
        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return nil if description == ""

        uuid = SecureRandom.uuid

        object = {}
        object["uuid"]           = uuid
        object["description"]    = description
        object["unixtime"]       = Time.new.to_i
        object["datetime"]       = Time.new.utc.iso8601
        object["classification"] = "TxDrop"
        object["atom"]           = Atoms5::interactivelyCreateNewAtomOrNull()
        object["domainx"]        = DomainsX::interactivelySelectDomainX()

        Librarian::issueNewFileWithShapeX(object, TxDrops::shapeX())
        Librarian::getShapeXed1OrNull(uuid, TxDrops::shapeX())
    end

    # --------------------------------------------------
    # toString

    # TxDrops::toString(nx70)
    def self.toString(nx70)
        "[drop] #{nx70["description"]} (#{nx70["atom"]["type"]})"
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

    # TxDrops::run(nx70)
    def self.run(nx70)

        system("clear")

        uuid = nx70["uuid"]

        NxBallsService::issue(
            uuid, 
            TxDrops::toString(nx70), 
            [uuid, DomainsX::domainXToAccountNumber(nx70["domainx"])]
        )

        loop {

            system("clear")

            puts TxDrops::toString(nx70).green
            puts "uuid: #{uuid}".yellow
            puts "domainx: #{nx70["domainx"]}".yellow

            if text = Atoms5::atomPayloadToTextOrNull(nx70["atom"]) then
                puts text
            end

            note = StructuredTodoTexts::getNoteOrNull(nx70["uuid"])
            if note then
                puts "note:\n#{note}".green
            end

            puts "access | note | <datecode> | description | atom | show json | transmute | destroy (gg) | exit (xx)".yellow

            command = LucilleCore::askQuestionAnswerAsString("> ")

            break if command == "exit"
            break if command == "xx"

            if (unixtime = Utils::codeToUnixtimeOrNull(command.gsub(" ", ""))) then
                DoNotShowUntil::setUnixtime(uuid, unixtime)
                break
            end

            if Interpreting::match("access", command) then
                Librarian::accessMikuAtom(nx70)
                nx70 = Librarian::getShapeXed1OrNull(nx70["uuid"], TxDrops::shapeX())
                next
            end

            if command == "note" then
                note = Utils::editTextSynchronously(StructuredTodoTexts::getNoteOrNull(nx70["uuid"]) || "")
                StructuredTodoTexts::setNote(uuid, note)
                next
            end

            if Interpreting::match("description", command) then
                description = Utils::editTextSynchronously(nx70["description"]).strip
                next if description == ""
                nx70["description"] = description
                Librarian::setValue(nx70["uuid"], "description", description)
                next
            end

            if Interpreting::match("atom", command) then
                atom = Atoms5::interactivelyCreateNewAtomOrNull()
                next if atom.nil?
                nx70 = Librarian::updateMikuAtom(nx70["uuid"], atom)
                next
            end

            if Interpreting::match("transmute", command) then
                CommandsOps::transmutation2(nx70, "TxDrop")
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

        NxBallsService::closeWithAsking(uuid)
    end

    # --------------------------------------------------
    # nx16s

    # TxDrops::ns16(nx70)
    def self.ns16(nx70)
        uuid = nx70["uuid"]
        {
            "uuid"     => uuid,
            "NS198"    => "NS16:TxDrop",
            "announce" => "(drop) #{nx70["description"]} (#{nx70["atom"]["type"]})",
            "commands" => ["..", "done", "''", ">> (transmute)"],
            "TxDrop"   => nx70
        }
    end

    # TxDrops::ns16s()
    def self.ns16s()
        focus = DomainsX::focusOrNull()
        TxDrops::mikus()
            .select{|item| focus.nil? or (miku["domainx"] == focus) }
            .sort{|i1, i2| i1["unixtime"] <=> i2["unixtime"] }
            .map{|item| TxDrops::ns16(item) }
    end

    # --------------------------------------------------

    # TxDrops::nx19s()
    def self.nx19s()
        TxDrops::mikus().map{|item|
            {
                "uuid"     => item["uuid"],
                "announce" => TxDrops::toStringForNS19(item),
                "lambda"   => lambda { TxDrops::run(item) }
            }
        }
    end
end
