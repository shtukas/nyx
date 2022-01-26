j# encoding: UTF-8

class Nx60s

    # Nx60s::items()
    def self.items()
        LucilleCore::locationsAtFolder("/Users/pascal/Galaxy/DataBank/Catalyst/Nx60s")
            .select{|filepath| File.basename(filepath)[-5, 5] == ".json" }
            .map{|filepath| JSON.parse(IO.read(filepath)) }
    end

    # Nx60s::commit(nx60)
    def self.commit(nx60)
        filepath = "/Users/pascal/Galaxy/DataBank/Catalyst/Nx60s/#{Digest::SHA1.hexdigest(nx60["uuid"])[0, 10]}.json"
        File.open(filepath, "w"){|f| f.puts(JSON.pretty_generate(nx60)) }
    end

    # Nx60s::destroy(uuid)
    def self.destroy(uuid)
        filepath = "/Users/pascal/Galaxy/DataBank/Catalyst/Nx60s/#{Digest::SHA1.hexdigest(uuid)[0, 10]}.json"
        return if !File.exists?(filepath)
        FileUtils.rm(filepath)
    end

    # --------------------------------------------------
    # Makers

    # Nx60s::interactivelyCreateNewOrNull()
    def self.interactivelyCreateNewOrNull()
        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return nil if description == ""
        uuid = SecureRandom.uuid
        atom = CoreData5::interactivelyCreateNewAtomOrNull()
        nx60 = {
            "uuid"        => uuid,
            "unixtime"    => Time.new.to_i,
            "description" => description,
            "atom"        => atom,
            "domainx"     => DomainsX::interactivelySelectDomainX()
        }
        Nx60s::commit(nx60)
        nx60
    end

    # --------------------------------------------------
    # toString

    # Nx60s::toString(nx60)
    def self.toString(nx60)
        "[nx60] #{nx60["description"]} (#{nx60["atom"]["type"]})"
    end

    # Nx60s::toStringForNS19(nx60)
    def self.toStringForNS19(nx60)
        "[nx60] #{nx60["description"]}"
    end

    # --------------------------------------------------
    # Operations

    # Nx60s::complete(nx60)
    def self.complete(nx60)
        Nx60s::destroy(nx60["uuid"])
    end

    # Nx60s::accessContent(nx60)
    def self.accessContent(nx60)
        updated = CoreData5::accessWithOptionToEdit(nx60["atom"])
        if updated then
            nx60["atom"] = updated
            Nx60s::commit(nx60)
        end
    end

    # Nx60s::run(nx60)
    def self.run(nx60)

        system("clear")

        uuid = nx60["uuid"]

        NxBallsService::issue(
            uuid, 
            Nx60s::toString(nx60), 
            [uuid, DomainsX::domainXToAccountNumber(nx60["domainx"])]
        )

        loop {

            system("clear")

            puts Nx60s::toString(nx60).green
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
                Nx60s::accessContent(nx60)
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
                nx60["description"] = description
                Nx60s::commit(nx60)
                next
            end

            if Interpreting::match("atom", command) then
                nx60["atom"] = CoreData5::interactivelyCreateNewAtomOrNull()
                Nx60s::commit(nx60)
                next
            end

            if Interpreting::match("show json", command) then
                puts JSON.pretty_generate(nx60)
                LucilleCore::pressEnterToContinue()
                break
            end

            if command == "destroy" then
                if LucilleCore::askQuestionAnswerAsBoolean("destroy '#{Nx60s::toString(nx60)}' ? ", true) then
                    Nx60s::complete(nx60)
                    break
                end
                next
            end

            if command == "gg" then
                if LucilleCore::askQuestionAnswerAsBoolean("destroy '#{Nx60s::toString(nx60)}' ? ", true) then
                    Nx60s::complete(nx60)
                    break
                end
                next
            end
        }

        NxBallsService::closeWithAsking(uuid)
    end

    # --------------------------------------------------
    # nx16s

    # Nx60s::toStringForNS16(nx60, rt)
    def self.toStringForNS16(nx60, rt)
        "[ship] (#{"%4.2f" % rt}) #{nx60["description"]} (#{nx60["atom"]["type"]})"
    end

    # Nx60s::ns16(nx60)
    def self.ns16(nx60)
        uuid = nx60["uuid"]
        rt = BankExtended::stdRecoveredDailyTimeInHours(uuid)
        {
            "uuid"     => uuid,
            "NS198"    => "NS16:Nx60",
            "announce" => Nx60s::toStringForNS16(nx60, rt).gsub("(0.00)", "      "),
            "commands" => ["..", "''"],
            "Nx60"     => nx60
        }
    end

    # Nx60s::ns16s()
    def self.ns16s()
        Nx60s::items()
            .sort{|i1, i2| i1["unixtime"] <=> i2["unixtime"] }
            .map{|item| Nx60s::ns16(item) }
    end

    # Nx60s::ns16sForDominant()
    def self.ns16sForDominant()
        dominant = DomainsX::dominant()
        Nx60s::items()
            .sort{|i1, i2| i1["unixtime"] <=> i2["unixtime"] }
            .select{|item| item["domainx"] == dominant }
            .map{|item| Nx60s::ns16(item) }
    end

    # --------------------------------------------------

    # Nx60s::nx19s()
    def self.nx19s()
        Nx60s::items().map{|item|
            {
                "uuid"     => item["uuid"],
                "announce" => Nx60s::toStringForNS19(item),
                "lambda"   => lambda { Nx60s::run(item) }
            }
        }
    end
end
