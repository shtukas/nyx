j# encoding: UTF-8

class TxFloats

    # TxFloats::items()
    def self.items()
        LucilleCore::locationsAtFolder("/Users/pascal/Galaxy/DataBank/Catalyst/TxFloats")
            .select{|filepath| File.basename(filepath)[-5, 5] == ".json" }
            .map{|filepath| JSON.parse(IO.read(filepath)) }
    end

    # TxFloats::commit(mx48)
    def self.commit(mx48)
        filepath = "/Users/pascal/Galaxy/DataBank/Catalyst/TxFloats/#{Digest::SHA1.hexdigest(mx48["uuid"])[0, 10]}.json"
        File.open(filepath, "w"){|f| f.puts(JSON.pretty_generate(mx48)) }
    end

    # TxFloats::destroy(uuid)
    def self.destroy(uuid)
        filepath = "/Users/pascal/Galaxy/DataBank/Catalyst/TxFloats/#{Digest::SHA1.hexdigest(uuid)[0, 10]}.json"
        return if !File.exists?(filepath)
        FileUtils.rm(filepath)
    end

    # --------------------------------------------------
    # Makers

    # TxFloats::interactivelyCreateNewOrNull()
    def self.interactivelyCreateNewOrNull()
        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return nil if description == ""
        uuid = SecureRandom.uuid
        atom = CoreData5::interactivelyCreateNewAtomOrNull()
        mx48 = {
            "uuid"        => uuid,
            "unixtime"    => Time.new.to_i,
            "description" => description,
            "atom"        => atom,
            "domainx"     => DomainsX::interactivelySelectDomainX()
        }
        TxFloats::commit(mx48)
        mx48
    end

    # --------------------------------------------------
    # toString

    # TxFloats::toString(mx48)
    def self.toString(mx48)
        "[mx48] #{mx48["description"]} (#{mx48["atom"]["type"]})"
    end

    # TxFloats::toStringForNS19(mx48)
    def self.toStringForNS19(mx48)
        "[mx48] #{mx48["description"]}"
    end

    # --------------------------------------------------
    # Operations

    # TxFloats::complete(mx48)
    def self.complete(mx48)
        TxFloats::destroy(mx48["uuid"])
    end

    # TxFloats::accessContent(mx48)
    def self.accessContent(mx48)
        updated = CoreData5::accessWithOptionToEdit(mx48["atom"])
        if updated then
            mx48["atom"] = updated
            TxFloats::commit(mx48)
        end
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

            if text = CoreData5::atomPayloadToTextOrNull(mx48["atom"]) then
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
                TxFloats::accessContent(mx48)
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
                mx48["description"] = description
                TxFloats::commit(mx48)
                next
            end

            if Interpreting::match("atom", command) then
                mx48["atom"] = CoreData5::interactivelyCreateNewAtomOrNull()
                TxFloats::commit(mx48)
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
