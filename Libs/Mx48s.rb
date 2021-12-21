# encoding: UTF-8

class Mx48s

    # Mx48s::items()
    def self.items()
        LucilleCore::locationsAtFolder("/Users/pascal/Galaxy/DataBank/Catalyst/Mx48s")
            .select{|filepath| File.basename(filepath)[-5, 5] == ".json" }
            .map{|filepath| JSON.parse(IO.read(filepath)) }
    end

    # Mx48s::commit(mx48)
    def self.commit(mx48)
        filepath = "/Users/pascal/Galaxy/DataBank/Catalyst/Mx48s/#{Digest::SHA1.hexdigest(mx48["uuid"])[0, 10]}.json"
        File.open(filepath, "w"){|f| f.puts(JSON.pretty_generate(mx48)) }
    end

    # Mx48s::destroy(mx48)
    def self.destroy(mx48)
        filepath = "/Users/pascal/Galaxy/DataBank/Catalyst/Mx48s/#{Digest::SHA1.hexdigest(mx48["uuid"])[0, 10]}.json"
        return if !File.exists?(filepath)
        FileUtils.rm(filepath)
    end

    # --------------------------------------------------
    # Makers

    # Mx48s::interactivelyCreateNewOrNull()
    def self.interactivelyCreateNewOrNull()
        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return nil if description == ""
        uuid = SecureRandom.uuid
        atom = CoreData5::interactivelyCreateNewAtomOrNull()
        mx48 = {
            "uuid"        => uuid,
            "unixtime"    => Time.new.to_i,
            "description" => description,
            "atom"        => atom
        }
        Mx48s::commit(mx48)
        mx48
    end

    # --------------------------------------------------
    # toString

    # Mx48s::toString(mx48)
    def self.toString(mx48)
        "[mx48] #{mx48["description"]} (#{mx48["atom"]["type"]})"
    end

    # Mx48s::toStringForNS19(mx48)
    def self.toStringForNS19(mx48)
        "[mx48] #{mx48["description"]}"
    end

    # --------------------------------------------------
    # Operations

    # Mx48s::complete(mx48)
    def self.complete(mx48)
        Mx48s::destroy(mx48)
    end

    # Mx48s::accessContent(mx48)
    def self.accessContent(mx48)
        updated = CoreData5::accessWithOptionToEdit(mx48["atom"])
        if updated then
            mx48["atom"] = updated
            Mx48s::commit(mx48)
        end
    end

    # Mx48s::run(mx48)
    def self.run(mx48)

        system("clear")

        uuid = mx48["uuid"]

        didItOnce1 = false

        loop {

            system("clear")

            puts "#{Mx48s::toString(mx48)}#{NxBallsService::runningStringOrEmptyString(" (", uuid, ")")}".green
            puts "uuid: #{uuid}".yellow

            if text = CoreData5::atomPayloadToTextOrNull(mx48["atom"]) then
                puts text
            end

            note = StructuredTodoTexts::getNoteOrNull(mx48["uuid"])
            if note then
                puts "note:\n#{note}".green
            end
            if mx48["atom"]["type"] != "description-only" and !didItOnce1 and LucilleCore::askQuestionAnswerAsBoolean("> access ? ", true) then
                Mx48s::accessContent(mx48)
            end
            didItOnce1 = true

            puts "access | note | <datecode> | description | atom | show json | destroy (gg) | exit (xx)".yellow

            command = LucilleCore::askQuestionAnswerAsString("> ")

            break if command == "exit"
            break if command == "xx"

            if (unixtime = Utils::codeToUnixtimeOrNull(command.gsub(" ", ""))) then
                DoNotShowUntil::setUnixtime(uuid, unixtime)
                break
            end

            if Interpreting::match("access", command) then
                Mx48s::accessContent(mx48)
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
                Mx48s::commit(mx48)
                next
            end

            if Interpreting::match("atom", command) then
                mx48["atom"] = CoreData5::interactivelyCreateNewAtomOrNull()
                Mx48s::commit(mx48)
                next
            end

            if Interpreting::match("show json", command) then
                puts JSON.pretty_generate(mx48)
                LucilleCore::pressEnterToContinue()
                break
            end

            if command == "destroy" then
                if LucilleCore::askQuestionAnswerAsBoolean("destroy '#{Mx48s::toString(mx48)}' ? ", true) then
                    Mx48s::complete(mx48)
                    break
                end
                next
            end

            if command == "gg" then
                if LucilleCore::askQuestionAnswerAsBoolean("destroy '#{Mx48s::toString(mx48)}' ? ", true) then
                    Mx48s::complete(mx48)
                    break
                end
                next
            end
        }

        NxBallsService::closeWithAsking(uuid)
    end

    # --------------------------------------------------
    # nx16s

    # Mx48s::ns16OrNull(mx48)
    def self.ns16OrNull(mx48)
        uuid = mx48["uuid"]
        {
            "uuid"     => uuid,
            "NS198"    => "ns16:Mx48",
            "announce" => Mx48s::toString(mx48),
            "commands" => [],
            "Mx48"     => mx48
        }
    end

    # Mx48s::ns16s()
    def self.ns16s()
        Mx48s::items()
            .sort{|i1, i2| i1["unixtime"] <=> i2["unixtime"] }
            .map{|item| Mx48s::ns16OrNull(item) }
    end

    # --------------------------------------------------

    # Mx48s::nx19s()
    def self.nx19s()
        Mx48s::items().map{|item|
            {
                "uuid"     => item["uuid"],
                "announce" => Mx48s::toStringForNS19(item),
                "lambda"   => lambda { Mx48s::run(item) }
            }
        }
    end
end
