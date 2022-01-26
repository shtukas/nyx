j# encoding: UTF-8

class Nx70s

    # Nx70s::items()
    def self.items()
        LucilleCore::locationsAtFolder("/Users/pascal/Galaxy/DataBank/Catalyst/Nx70s")
            .select{|filepath| File.basename(filepath)[-5, 5] == ".json" }
            .map{|filepath| JSON.parse(IO.read(filepath)) }
    end

    # Nx70s::commit(nx70)
    def self.commit(nx70)
        filepath = "/Users/pascal/Galaxy/DataBank/Catalyst/Nx70s/#{Digest::SHA1.hexdigest(nx70["uuid"])[0, 10]}.json"
        File.open(filepath, "w"){|f| f.puts(JSON.pretty_generate(nx70)) }
    end

    # Nx70s::destroy(uuid)
    def self.destroy(uuid)
        filepath = "/Users/pascal/Galaxy/DataBank/Catalyst/Nx70s/#{Digest::SHA1.hexdigest(uuid)[0, 10]}.json"
        return if !File.exists?(filepath)
        FileUtils.rm(filepath)
    end

    # --------------------------------------------------
    # Makers

    # Nx70s::interactivelyCreateNewOrNull()
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
        Nx70s::commit(nx70)
        nx70
    end

    # --------------------------------------------------
    # toString

    # Nx70s::toString(nx70)
    def self.toString(nx70)
        "[nx70] #{nx70["description"]} (#{nx70["atom"]["type"]})"
    end

    # Nx70s::toStringForNS19(nx70)
    def self.toStringForNS19(nx70)
        "[nx70] #{nx70["description"]}"
    end

    # --------------------------------------------------
    # Operations

    # Nx70s::complete(nx70)
    def self.complete(nx70)
        Nx70s::destroy(nx70["uuid"])
    end

    # Nx70s::accessContent(nx70)
    def self.accessContent(nx70)
        updated = CoreData5::accessWithOptionToEdit(nx70["atom"])
        if updated then
            nx70["atom"] = updated
            Nx70s::commit(nx70)
        end
    end

    # Nx70s::run(nx70)
    def self.run(nx70)

        system("clear")

        uuid = nx70["uuid"]

        NxBallsService::issue(
            uuid, 
            Nx70s::toString(nx70), 
            [uuid, DomainsX::domainXToAccountNumber(nx70["domainx"])]
        )

        loop {

            system("clear")

            puts Nx70s::toString(nx70).green
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
                Nx70s::accessContent(nx70)
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
                Nx70s::commit(nx70)
                next
            end

            if Interpreting::match("atom", command) then
                nx70["atom"] = CoreData5::interactivelyCreateNewAtomOrNull()
                Nx70s::commit(nx70)
                next
            end

            if Interpreting::match("show json", command) then
                puts JSON.pretty_generate(nx70)
                LucilleCore::pressEnterToContinue()
                break
            end

            if command == "destroy" then
                if LucilleCore::askQuestionAnswerAsBoolean("destroy '#{Nx70s::toString(nx70)}' ? ", true) then
                    Nx70s::complete(nx70)
                    break
                end
                next
            end

            if command == "gg" then
                if LucilleCore::askQuestionAnswerAsBoolean("destroy '#{Nx70s::toString(nx70)}' ? ", true) then
                    Nx70s::complete(nx70)
                    break
                end
                next
            end
        }

        NxBallsService::closeWithAsking(uuid)
    end

    # --------------------------------------------------
    # nx16s

    # Nx70s::ns16(nx70)
    def self.ns16(nx70)
        uuid = nx70["uuid"]
        {
            "uuid"     => uuid,
            "NS198"    => "NS16:Nx70",
            "announce" => "(drop) #{nx70["description"]} (#{nx70["atom"]["type"]})",
            "commands" => ["..", "''", ">> (transmute)"],
            "Nx70"     => nx70
        }
    end

    # Nx70s::ns16s()
    def self.ns16s()
        Nx70s::items()
            .sort{|i1, i2| i1["unixtime"] <=> i2["unixtime"] }
            .map{|item| Nx70s::ns16(item) }
    end

    # --------------------------------------------------

    # Nx70s::nx19s()
    def self.nx19s()
        Nx70s::items().map{|item|
            {
                "uuid"     => item["uuid"],
                "announce" => Nx70s::toStringForNS19(item),
                "lambda"   => lambda { Nx70s::run(item) }
            }
        }
    end
end
