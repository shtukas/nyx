j# encoding: UTF-8

class TxSpaceships

    # TxSpaceships::items()
    def self.items()
        Librarian::classifierToMikus("CatalystTxSpaceship")
    end

    # TxSpaceships::destroy(uuid)
    def self.destroy(uuid)
        Librarian::destroy(uuid)
    end

    # --------------------------------------------------
    # Makers

    # TxSpaceships::interactivelyCreateNewOrNull()
    def self.interactivelyCreateNewOrNull()
        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return nil if description == ""
        atom = CoreData5::interactivelyCreateNewAtomOrNull()
        domainx = DomainsX::interactivelySelectDomainX()
        uuid           = SecureRandom.uuid
        atom           = CoreData5::interactivelyCreateNewAtomOrNull()
        domainx        = DomainsX::interactivelySelectDomainX()
        unixtime       = Time.new.to_i
        datetime       = Time.new.utc.iso8601
        classification = "CatalystTxSpaceship"
        extras = {
            "domainx" => domainx
        }
        Librarian::spawnNewMikuFileOrError(uuid, description, unixtime, datetime, classification, atom, extras)
        Librarian::getMikuOrNull(uuid)
    end

    # --------------------------------------------------
    # toString

    # TxSpaceships::toString(nx60)
    def self.toString(nx60)
        "[ship] #{nx60["description"]} (#{nx60["atom"]["type"]})"
    end

    # TxSpaceships::toStringForNS19(nx60)
    def self.toStringForNS19(nx60)
        "[ship] #{nx60["description"]}"
    end

    # --------------------------------------------------
    # Operations

    # TxSpaceships::complete(nx60)
    def self.complete(nx60)
        TxSpaceships::destroy(nx60["uuid"])
    end

    # TxSpaceships::accessContent(nx60)
    def self.accessContent(nx60)
        atom = CoreData5::accessWithOptionToEdit(nx60["atom"])
        if atom then
            Librarian::updateMikuAtom(nx60["uuid"], atom)
        end
        Librarian::getMikuOrNull(nx60["uuid"])
    end

    # TxSpaceships::run(nx60)
    def self.run(nx60)

        system("clear")

        uuid = nx60["uuid"]

        NxBallsService::issue(
            uuid, 
            TxSpaceships::toString(nx60), 
            [uuid, DomainsX::domainXToAccountNumber(nx60["extras"]["domainx"])]
        )

        loop {

            system("clear")

            puts TxSpaceships::toString(nx60).green
            puts "uuid: #{uuid}".yellow

            if text = CoreData5::atomPayloadToTextOrNull(nx60["atom"]) then
                puts text
            end

            note = StructuredTodoTexts::getNoteOrNull(nx60["uuid"])
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
                TxSpaceships::accessContent(nx60)
                next
            end

            if command == "note" then
                note = Utils::editTextSynchronously(StructuredTodoTexts::getNoteOrNull(nx60["uuid"]) || "")
                StructuredTodoTexts::setNote(uuid, note)
                next
            end

            if Interpreting::match("description", command) then
                description = Utils::editTextSynchronously(nx60["description"]).strip
                next if description == ""
                nx60 = Librarian::updateMikuDescription(nx60["uuid"], description) 
                next
            end

            if Interpreting::match("atom", command) then
                atom = CoreData5::interactivelyCreateNewAtomOrNull()
                next if atom.nil?
                nx60 = Librarian::updateMikuAtom(nx60["uuid"], atom)
                next
            end

            if Interpreting::match("show json", command) then
                puts JSON.pretty_generate(nx60)
                LucilleCore::pressEnterToContinue()
                break
            end

            if command == "destroy" then
                if LucilleCore::askQuestionAnswerAsBoolean("destroy '#{TxSpaceships::toString(nx60)}' ? ", true) then
                    TxSpaceships::complete(nx60)
                    break
                end
                next
            end

            if command == "gg" then
                if LucilleCore::askQuestionAnswerAsBoolean("destroy '#{TxSpaceships::toString(nx60)}' ? ", true) then
                    TxSpaceships::complete(nx60)
                    break
                end
                next
            end
        }

        NxBallsService::closeWithAsking(uuid)
    end

    # --------------------------------------------------
    # nx16s

    # TxSpaceships::toStringForNS16(nx60, rt)
    def self.toStringForNS16(nx60, rt)
        "[ship] (#{"%4.2f" % rt}) #{nx60["description"]} (#{nx60["atom"]["type"]})"
    end

    # TxSpaceships::ns16(nx60)
    def self.ns16(nx60)
        uuid = nx60["uuid"]
        rt = BankExtended::stdRecoveredDailyTimeInHours(uuid)
        if rt > 1 then
            ItemStoreOps::delistForDefault(uuid)
        end
        {
            "uuid"     => uuid,
            "NS198"    => "NS16:TxSpaceship",
            "announce" => TxSpaceships::toStringForNS16(nx60, rt).gsub("(0.00)", "      "),
            "commands" => ["..", "''", ">> (transmute)"],
            "TxSpaceship"     => nx60,
            "rt"       => rt
        }
    end

    # TxSpaceships::ns16s()
    def self.ns16s()
        TxSpaceships::items()
            .sort{|i1, i2| i1["unixtime"] <=> i2["unixtime"] }
            .map{|item| TxSpaceships::ns16(item) }
    end

    # TxSpaceships::ns16sForDominant()
    def self.ns16sForDominant()
        focus = DomainsX::focusOrNull()
        TxSpaceships::items()
            .sort{|i1, i2| i1["unixtime"] <=> i2["unixtime"] }
            .select{|item| focus.nil? or (item["domainx"] == focus) }
            .map{|item| TxSpaceships::ns16(item) }
            .sort{|i1, i2| i1["rt"] <=> i2["rt"] }
    end

    # --------------------------------------------------

    # TxSpaceships::nx19s()
    def self.nx19s()
        TxSpaceships::items().map{|item|
            {
                "uuid"     => item["uuid"],
                "announce" => TxSpaceships::toStringForNS19(item),
                "lambda"   => lambda { TxSpaceships::run(item) }
            }
        }
    end
end
