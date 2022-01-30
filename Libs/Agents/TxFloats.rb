j# encoding: UTF-8

class TxFloats

    # TxFloats::items()
    def self.items()
        Librarian::classifierToMikus("CatalystTxFloat")
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

        uuid = SecureRandom.uuid
        atom = Atoms5::interactivelyCreateNewAtomOrNull()
        domainx = DomainsX::interactivelySelectDomainX()

        uuid           = SecureRandom.uuid

        domainx        = DomainsX::interactivelySelectDomainX()
        unixtime       = Time.new.to_i
        datetime       = Time.new.utc.iso8601
        classification = "CatalystTxFloat"
        extras = {
            "domainx" => domainx
        }
        Librarian::spawnNewMikuFileOrError(uuid, description, unixtime, datetime, classification, atom, extras)
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
            [uuid, DomainsX::domainXToAccountNumber(mx48["extras"]["domainx"])]
        )

        loop {

            system("clear")

            puts TxFloats::toString(mx48).green
            puts "uuid: #{uuid}".yellow

            if text = Atoms5::atomPayloadToTextOrNull(mx48["atom"]) then
                puts text
            end

            note = StructuredTodoTexts::getNoteOrNull(mx48["uuid"])
            if note then
                puts "note:\n#{note}".green
            end

            puts "access | note | <datecode> | description | atom | show json | destroy (gg) | exit (xx)".yellow

            command = LucilleCore::askQuestionAnswerAsString("> ")

            break if command == "exit"
            break if command == "xx"

            if (unixtime = Utils::codeToUnixtimeOrNull(command.gsub(" ", ""))) then
                DoNotShowUntil::setUnixtime(uuid, unixtime)
                break
            end

            if Interpreting::match("access", command) then
                mx48 = Librarian::accessMikuAtom(mx48)
                next
            end

            if command == "note" then
                note = Utils::editTextSynchronously(StructuredTodoTexts::getNoteOrNull(mx48["uuid"]) || "")
                StructuredTodoTexts::setNote(uuid, note)
                next
            end

            if Interpreting::match("description", command) then
                description = Utils::editTextSynchronously(mx48["description"]).strip
                next if description == ""
                mx48 = Librarian::updateMikuDescription(mx48["uuid"], description) 
                next
            end

            if Interpreting::match("atom", command) then
                atom = Atoms5::interactivelyCreateNewAtomOrNull()
                next if atom.nil?
                mx48 = Librarian::updateMikuAtom(mx48["uuid"], atom)
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
