# encoding: UTF-8

class TxDateds

    # TxDateds::items()
    def self.items()
        LucilleCore::locationsAtFolder("/Users/pascal/Galaxy/DataBank/Catalyst/TxDateds")
            .select{|filepath| File.basename(filepath)[-5, 5] == ".json" }
            .map{|filepath| JSON.parse(IO.read(filepath)) }
    end

    # TxDateds::commit(mx49)
    def self.commit(mx49)
        filepath = "/Users/pascal/Galaxy/DataBank/Catalyst/TxDateds/#{Digest::SHA1.hexdigest(mx49["uuid"])[0, 10]}.json"
        File.open(filepath, "w"){|f| f.puts(JSON.pretty_generate(mx49)) }
    end

    # TxDateds::destroy(uuid)
    def self.destroy(uuid)
        filepath = "/Users/pascal/Galaxy/DataBank/Catalyst/TxDateds/#{Digest::SHA1.hexdigest(uuid)[0, 10]}.json"
        return if !File.exists?(filepath)
        FileUtils.rm(filepath)
    end

    # --------------------------------------------------
    # Makers

    # TxDateds::interactivelyCreateNewOrNull()
    def self.interactivelyCreateNewOrNull()
        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return nil if description == ""
        uuid = SecureRandom.uuid
        datetime = Utils::interactivelySelectAUTCIso8601DateTimeOrNull()
        return nil if datetime.nil?
        atom = CoreData5::interactivelyCreateNewAtomOrNull()
        mx49 = {
            "uuid"        => uuid,
            "unixtime"    => Time.new.to_i,
            "description" => description,
            "datetime"    => datetime,
            "atom"        => atom,
            "domainx"     => DomainsX::interactivelySelectDomainX()
        }
        TxDateds::commit(mx49)
        mx49
    end

    # TxDateds::interactivelyCreateNewTodayOrNull()
    def self.interactivelyCreateNewTodayOrNull()
        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return nil if description == ""
        uuid = SecureRandom.uuid
        datetime = Time.new.utc.iso8601
        atom = CoreData5::interactivelyCreateNewAtomOrNull()
        mx49 = {
            "uuid"        => uuid,
            "unixtime"    => Time.new.to_i,
            "description" => description,
            "datetime"    => datetime,
            "atom"        => atom
        }
        TxDateds::commit(mx49)
        mx49
    end

    # --------------------------------------------------
    # toString

    # TxDateds::toString(mx49)
    def self.toString(mx49)
        "(ondate) [#{mx49["datetime"][0, 10]}] #{mx49["description"]} (#{mx49["atom"]["type"]})"
    end

    # TxDateds::toStringForNS19(mx49)
    def self.toStringForNS19(mx49)
        "[date] #{mx49["description"]}"
    end

    # --------------------------------------------------
    # Operations

    # TxDateds::accessContent(mx49)
    def self.accessContent(mx49)
        updated = CoreData5::accessWithOptionToEdit(mx49["atom"])
        if updated then
            mx49["atom"] = updated
            TxDateds::commit(mx49)
        end
    end

    # TxDateds::run(mx49)
    def self.run(mx49)

        system("clear")

        uuid = mx49["uuid"]

        NxBallsService::issue(
            uuid, 
            TxDateds::toString(mx49), 
            [uuid, DomainsX::domainXToAccountNumber(mx49["domainx"])]
        )

        loop {

            system("clear")

            puts TxDateds::toString(mx49).green
            puts "uuid: #{uuid}".yellow
            puts "date: #{mx49["datetime"][0, 10]}".yellow

            if text = CoreData5::atomPayloadToTextOrNull(mx49["atom"]) then
                puts text
            end

            note = StructuredTodoTexts::getNoteOrNull(mx49["uuid"])
            if note then
                puts "note:\n#{note}".green
            end

            puts "access | note | date | description | atom | show json | destroy (gg) | exit (xx)".yellow

            command = LucilleCore::askQuestionAnswerAsString("> ")

            break if command == "exit"
            break if command == "xx"

            if Interpreting::match("access", command) then
                TxDateds::accessContent(mx49)
                next
            end

            if Interpreting::match("date", command) then
                datetime = Utils::interactivelySelectAUTCIso8601DateTimeOrNull()
                mx49["datetime"] = datetime
                TxDateds::commit(mx49)
                next
            end

            if command == "note" then
                note = Utils::editTextSynchronously(StructuredTodoTexts::getNoteOrNull(mx49["uuid"]) || "")
                StructuredTodoTexts::setNote(uuid, note)
                next
            end

            if Interpreting::match("description", command) then
                description = Utils::editTextSynchronously(mx49["description"]).strip
                next if description == ""
                mx49["description"] = description
                TxDateds::commit(mx49)
                next
            end

            if Interpreting::match("atom", command) then
                mx49["atom"] = CoreData5::interactivelyCreateNewAtomOrNull()
                TxDateds::commit(mx49)
                next
            end

            if Interpreting::match("show json", command) then
                puts JSON.pretty_generate(mx49)
                LucilleCore::pressEnterToContinue()
                break
            end

            if command == "destroy" then
                if LucilleCore::askQuestionAnswerAsBoolean("destroy '#{TxDateds::toString(mx49)}' ? ", true) then
                    TxDateds::destroy(mx49["uuid"])
                    break
                end
                next
            end

            if command == "gg" then
                if LucilleCore::askQuestionAnswerAsBoolean("destroy '#{TxDateds::toString(mx49)}' ? ", true) then
                    TxDateds::destroy(mx49["uuid"])
                    break
                end
                next
            end
        }

        NxBallsService::closeWithAsking(uuid)
    end

    # TxDateds::dive()
    def self.dive()
        loop {
            items = TxDateds::items().sort{|i1, i2| i1["datetime"] <=> i2["datetime"] }
            item = LucilleCore::selectEntityFromListOfEntitiesOrNull("dated", items, lambda{|item| TxDateds::toString(item) })
            break if item.nil?
            TxDateds::run(item)
        }
    end

    # --------------------------------------------------
    # nx16s

    # TxDateds::ns16(mx49)
    def self.ns16(mx49)
        uuid = mx49["uuid"]
        {
            "uuid"     => uuid,
            "NS198"    => "NS16:TxDated",
            "announce" => "(ondate) [#{mx49["datetime"][0, 10]}] #{mx49["description"]} (#{mx49["atom"]["type"]})",
            "commands" => ["..", "done", "redate", ">> (transmute)", "''"],
            "TxDated"     => mx49
        }
    end

    # TxDateds::ns16s()
    def self.ns16s()
        focus = DomainsX::focusOrNull()
        TxDateds::items()
            .select{|item| focus.nil? or (item["domainx"] == focus) }
            .select{|mx49| mx49["datetime"][0, 10] <= Utils::today() }
            .sort{|i1, i2| i1["datetime"] <=> i2["datetime"] }
            .map{|mx49| TxDateds::ns16(mx49) }
    end

    # --------------------------------------------------

    # TxDateds::nx19s()
    def self.nx19s()
        TxDateds::items().map{|item|
            {
                "uuid"     => item["uuid"],
                "announce" => TxDateds::toStringForNS19(item),
                "lambda"   => lambda { TxDateds::run(item) }
            }
        }
    end
end
