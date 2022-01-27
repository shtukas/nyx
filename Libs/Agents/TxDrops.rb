j# encoding: UTF-8

class TxDrops

    # TxDrops::items()
    def self.items()
        LucilleCore::locationsAtFolder("/Users/pascal/Galaxy/DataBank/Catalyst/TxDrops")
            .select{|filepath| File.basename(filepath)[-5, 5] == ".json" }
            .map{|filepath| JSON.parse(IO.read(filepath)) }
    end

    # TxDrops::commit(nx70)
    def self.commit(nx70)
        filepath = "/Users/pascal/Galaxy/DataBank/Catalyst/TxDrops/#{Digest::SHA1.hexdigest(nx70["uuid"])[0, 10]}.json"
        File.open(filepath, "w"){|f| f.puts(JSON.pretty_generate(nx70)) }
    end

    # TxDrops::destroy(uuid)
    def self.destroy(uuid)
        filepath = "/Users/pascal/Galaxy/DataBank/Catalyst/TxDrops/#{Digest::SHA1.hexdigest(uuid)[0, 10]}.json"
        return if !File.exists?(filepath)
        FileUtils.rm(filepath)
    end

    # --------------------------------------------------
    # Makers

    # TxDrops::interactivelyCreateNewOrNull()
    def self.interactivelyCreateNewOrNull()
        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return nil if description == ""
        uuid = SecureRandom.uuid
        atom = CoreData5::interactivelyCreateNewAtomOrNull()
        nx70 = {
            "uuid"        => uuid,
            "unixtime"    => Time.new.to_i,
            "description" => description,
            "atom"        => atom,
            "domainx"     => DomainsX::interactivelySelectDomainX()
        }
        TxDrops::commit(nx70)
        nx70
    end

    # --------------------------------------------------
    # toString

    # TxDrops::toString(nx70)
    def self.toString(nx70)
        "[nx70] #{nx70["description"]} (#{nx70["atom"]["type"]})"
    end

    # TxDrops::toStringForNS19(nx70)
    def self.toStringForNS19(nx70)
        "[nx70] #{nx70["description"]}"
    end

    # --------------------------------------------------
    # Operations

    # TxDrops::complete(nx70)
    def self.complete(nx70)
        TxDrops::destroy(nx70["uuid"])
    end

    # TxDrops::accessContent(nx70)
    def self.accessContent(nx70)
        updated = CoreData5::accessWithOptionToEdit(nx70["atom"])
        if updated then
            nx70["atom"] = updated
            TxDrops::commit(nx70)
        end
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

            if text = CoreData5::atomPayloadToTextOrNull(nx70["atom"]) then
                puts text
            end

            note = StructuredTodoTexts::getNoteOrNull(nx70["uuid"])
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
                TxDrops::accessContent(nx70)
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
                TxDrops::commit(nx70)
                next
            end

            if Interpreting::match("atom", command) then
                nx70["atom"] = CoreData5::interactivelyCreateNewAtomOrNull()
                TxDrops::commit(nx70)
                next
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
            "commands" => ["..", "''", ">> (transmute)"],
            "TxDrop"     => nx70
        }
    end

    # TxDrops::ns16s()
    def self.ns16s()
        TxDrops::items()
            .sort{|i1, i2| i1["unixtime"] <=> i2["unixtime"] }
            .map{|item| TxDrops::ns16(item) }
    end

    # --------------------------------------------------

    # TxDrops::nx19s()
    def self.nx19s()
        TxDrops::items().map{|item|
            {
                "uuid"     => item["uuid"],
                "announce" => TxDrops::toStringForNS19(item),
                "lambda"   => lambda { TxDrops::run(item) }
            }
        }
    end
end
