# encoding: UTF-8

class Mx49s

    # Mx49s::items()
    def self.items()
        LucilleCore::locationsAtFolder("/Users/pascal/Galaxy/DataBank/Catalyst/Mx49s")
            .select{|filepath| File.basename(filepath)[-5, 5] == ".json" }
            .map{|filepath| JSON.parse(IO.read(filepath)) }
    end

    # Mx49s::commit(mx49)
    def self.commit(mx49)
        filepath = "/Users/pascal/Galaxy/DataBank/Catalyst/Mx49s/#{Digest::SHA1.hexdigest(mx49["uuid"])[0, 10]}.json"
        File.open(filepath, "w"){|f| f.puts(JSON.pretty_generate(mx49)) }
    end

    # Mx49s::destroy(uuid)
    def self.destroy(uuid)
        filepath = "/Users/pascal/Galaxy/DataBank/Catalyst/Mx49s/#{Digest::SHA1.hexdigest(uuid)[0, 10]}.json"
        return if !File.exists?(filepath)
        FileUtils.rm(filepath)
    end

    # --------------------------------------------------
    # Makers

    # Mx49s::interactivelyCreateNewOrNull()
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
            "atom"        => atom
        }
        Mx49s::commit(mx49)
        mx49
    end

    # Mx49s::interactivelyCreateNewTodayOrNull()
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
        Mx49s::commit(mx49)
        mx49
    end

    # --------------------------------------------------
    # toString

    # Mx49s::toString(mx49)
    def self.toString(mx49)
        "[mx49] #{mx49["description"]} (#{mx49["atom"]["type"]})"
    end

    # Mx49s::toStringForNS19(mx49)
    def self.toStringForNS19(mx49)
        "[mx49] #{mx49["description"]}"
    end

    # --------------------------------------------------
    # Operations

    # Mx49s::accessContent(mx49)
    def self.accessContent(mx49)
        updated = CoreData5::accessWithOptionToEdit(mx49["atom"])
        if updated then
            mx49["atom"] = updated
            Mx49s::commit(mx49)
        end
    end

    # Mx49s::run(mx49)
    def self.run(mx49)

        system("clear")

        uuid = mx49["uuid"]

        NxBallsService::issue(uuid, Mx49s::toString(mx49), [uuid, "GLOBAL-4852-9FCE-C8D43B85A4AC"])

        loop {

            system("clear")

            puts Mx49s::toString(mx49).green
            puts "uuid: #{uuid}".yellow

            if text = CoreData5::atomPayloadToTextOrNull(mx49["atom"]) then
                puts text
            end

            note = StructuredTodoTexts::getNoteOrNull(mx49["uuid"])
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
                Mx49s::accessContent(mx49)
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
                Mx49s::commit(mx49)
                next
            end

            if Interpreting::match("atom", command) then
                mx49["atom"] = CoreData5::interactivelyCreateNewAtomOrNull()
                Mx49s::commit(mx49)
                next
            end

            if Interpreting::match("show json", command) then
                puts JSON.pretty_generate(mx49)
                LucilleCore::pressEnterToContinue()
                break
            end

            if command == "destroy" then
                if LucilleCore::askQuestionAnswerAsBoolean("destroy '#{Mx49s::toString(mx49)}' ? ", true) then
                    Mx49s::destroy(mx49["uuid"])
                    break
                end
                next
            end

            if command == "gg" then
                if LucilleCore::askQuestionAnswerAsBoolean("destroy '#{Mx49s::toString(mx49)}' ? ", true) then
                    Mx49s::destroy(mx49["uuid"])
                    break
                end
                next
            end
        }

        NxBallsService::closeWithAsking(uuid)
    end

    # --------------------------------------------------
    # nx16s

    # Mx49s::ns16(mx49)
    def self.ns16(mx49)
        uuid = mx49["uuid"]
        {
            "uuid"     => uuid,
            "NS198"    => "ns16:Mx49",
            "announce" => "[#{mx49["datetime"][0, 10]}] #{mx49["description"]} (#{mx49["atom"]["type"]})",
            "commands" => ["..", "done", "redate", ">> (transmute)"],
            "Mx49"     => mx49
        }
    end

    # Mx49s::ns16s()
    def self.ns16s()
        Mx49s::items()
            .select{|mx49| mx49["datetime"][0, 10] <= Utils::today() }
            .sort{|i1, i2| i1["datetime"] <=> i2["datetime"] }
            .map{|mx49| Mx49s::ns16(mx49) }
    end

    # --------------------------------------------------

    # Mx49s::nx19s()
    def self.nx19s()
        Mx49s::items().map{|item|
            {
                "uuid"     => item["uuid"],
                "announce" => Mx49s::toStringForNS19(item),
                "lambda"   => lambda { Mx49s::run(item) }
            }
        }
    end
end
