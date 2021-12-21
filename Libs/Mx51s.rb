# encoding: UTF-8

class Mx51s

    # Mx51s::setuuid()
    def self.setuuid()
        "catalyst:70853e76-3665-4b2a-8f1e-2f899a93ac06"
    end

    # Mx51s::items()
    def self.items()
        LucilleCore::locationsAtFolder("/Users/pascal/Galaxy/DataBank/Catalyst/Mx51s")
            .select{|filepath| File.basename(filepath)[-5, 5] == ".json" }
            .map{|filepath| JSON.parse(IO.read(filepath)) }
            .sort{|i1, i2| i1["ordinal"] <=> i2["ordinal"] }
    end

    # Mx51s::commit(mx51)
    def self.commit(mx51)
        filepath = "/Users/pascal/Galaxy/DataBank/Catalyst/Mx51s/#{Digest::SHA1.hexdigest(mx51["uuid"])[0, 10]}.json"
        File.open(filepath, "w"){|f| f.puts(JSON.pretty_generate(mx51)) }
    end

    # Mx51s::destroy(mx51)
    def self.destroy(mx51)
        filepath = "/Users/pascal/Galaxy/DataBank/Catalyst/Mx51s/#{Digest::SHA1.hexdigest(mx51["uuid"])[0, 10]}.json"
        return if !File.exists?(filepath)
        FileUtils.rm(filepath)
    end

    # --------------------------------------------------
    # Ordinals

    # Mx51s::nextOrdinal()
    def self.nextOrdinal()
        biggest = ([0] + Mx51s::items().map{|nx50| nx50["ordinal"] }).max
        (biggest + 1).floor
    end

    # Mx51s::ordinalBetweenN1thAndN2th(n1, n2)
    def self.ordinalBetweenN1thAndN2th(n1, n2)
        nx50s = Mx51s::items()
        if nx50s.size < n1+2 then
            return Mx51s::nextOrdinal()
        end
        ordinals = nx50s.map{|nx50| nx50["ordinal"] }.sort.drop(n1).take(n2-n1)
        ordinals.min + rand*(ordinals.max-ordinals.min)
    end

    # Mx51s::interactivelyDecideNewOrdinal()
    def self.interactivelyDecideNewOrdinal()
        Mx51s::items()
            .first(50)
            .each{|nx50| 
                puts "- #{Mx51s::toStringWithOrdinal(nx50)}"
            }
        return LucilleCore::askQuestionAnswerAsString("> ordinal ? : ").to_f
    end

    # --------------------------------------------------
    # Makers

    # Mx51s::interactivelyCreateNewOrNull()
    def self.interactivelyCreateNewOrNull()
        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return nil if description == ""
        uuid = SecureRandom.uuid
        atom = CoreData5::interactivelyCreateNewAtomOrNull()
        ordinal = Mx51s::interactivelyDecideNewOrdinal()
        nx50 = {
            "uuid"        => uuid,
            "unixtime"    => Time.new.to_i,
            "ordinal"     => ordinal,
            "description" => description,
            "atom"        => atom
        }
        Mx51s::commit(nx50)
        nx50
    end

    # --------------------------------------------------
    # toString

    # Mx51s::toString(nx50)
    def self.toString(nx50)
        "[nx50] #{nx50["description"]} (#{nx50["atom"]["type"]})"
    end

    # Mx51s::toStringWithOrdinal(nx50)
    def self.toStringWithOrdinal(nx50)
        "[nx50] (ord: #{nx50["ordinal"]}) #{nx50["description"]} (#{nx50["atom"]["type"]})"
    end

    # Mx51s::toStringForNS19(nx50)
    def self.toStringForNS19(nx50)
        "[nx50] #{nx50["description"]}"
    end

    # Mx51s::toStringForNS16(nx50, rt)
    def self.toStringForNS16(nx50, rt)
        "[Nx50] (#{"%4.2f" % rt}) #{nx50["description"]} (#{nx50["atom"]["type"]})"
    end

    # --------------------------------------------------
    # Operations

    # Mx51s::complete(nx50)
    def self.complete(nx50)
        Mx51s::destroy(nx50)
    end

    # Mx51s::accessContent(nx50)
    def self.accessContent(nx50)
        updated = CoreData5::accessWithOptionToEdit(nx50["atom"])
        if updated then
            nx50["atom"] = updated
            Mx51s::commit(nx50)
        end
    end

    # Mx51s::run(nx50)
    def self.run(nx50)

        itemToBankAccounts = lambda{|item|
            accounts = []
            accounts << item["uuid"]
            accounts.compact
        }

        system("clear")

        uuid = nx50["uuid"]

        NxBallsService::issue(uuid, nx50["description"], itemToBankAccounts.call(nx50))

        didItOnce1 = false

        loop {

            system("clear")

            puts "#{Mx51s::toString(nx50)}#{NxBallsService::runningStringOrEmptyString(" (", uuid, ")")}".green
            puts "uuid: #{uuid}".yellow
            puts "ordinal: #{nx50["ordinal"]}".yellow
            puts "DoNotDisplayUntil: #{DoNotShowUntil::getDateTimeOrNull(nx50["uuid"])}".yellow
            puts "RT: #{BankExtended::stdRecoveredDailyTimeInHours(uuid)}".yellow

            if text = CoreData5::atomPayloadToTextOrNull(nx50["atom"]) then
                puts text
            end

            note = StructuredTodoTexts::getNoteOrNull(nx50["uuid"])
            if note then
                puts "note:\n#{note}".green
            end
            if nx50["atom"]["type"] != "description-only" and !didItOnce1 and LucilleCore::askQuestionAnswerAsBoolean("> access ? ", true) then
                Mx51s::accessContent(nx50)
            end
            didItOnce1 = true

            puts "access | note | <datecode> | description | atom | ordinal | rotate | show json | destroy (gg) | exit (xx)".yellow

            command = LucilleCore::askQuestionAnswerAsString("> ")

            break if command == "exit"
            break if command == "xx"

            if (unixtime = Utils::codeToUnixtimeOrNull(command.gsub(" ", ""))) then
                DoNotShowUntil::setUnixtime(uuid, unixtime)
                break
            end

            if Interpreting::match("access", command) then
                Mx51s::accessContent(nx50)
                next
            end

            if command == "note" then
                note = Utils::editTextSynchronously(StructuredTodoTexts::getNoteOrNull(nx50["uuid"]) || "")
                StructuredTodoTexts::setNote(uuid, note)
                next
            end

            if Interpreting::match("description", command) then
                description = Utils::editTextSynchronously(nx50["description"]).strip
                next if description == ""
                nx50["description"] = description
                Mx51s::commit(nx50)
                next
            end

            if Interpreting::match("atom", command) then
                nx50["atom"] = CoreData5::interactivelyCreateNewAtomOrNull()
                Mx51s::commit(nx50)
                next
            end

            if Interpreting::match("ordinal", command) then
                ordinal = Mx51s::interactivelyDecideNewOrdinal()
                nx50["ordinal"] = ordinal
                Mx51s::commit(nx50)
                next
            end

            if Interpreting::match("rotate", command) then
                nx50["ordinal"] = Mx51s::nextOrdinal()
                Mx51s::commit(nx50)
                break
            end

            if Interpreting::match("show json", command) then
                puts JSON.pretty_generate(nx50)
                LucilleCore::pressEnterToContinue()
                break
            end

            if command == "destroy" then
                if LucilleCore::askQuestionAnswerAsBoolean("destroy '#{Mx51s::toString(nx50)}' ? ", true) then
                    Mx51s::complete(nx50)
                    break
                end
                next
            end

            if command == "gg" then
                if LucilleCore::askQuestionAnswerAsBoolean("destroy '#{Mx51s::toString(nx50)}' ? ", true) then
                    Mx51s::complete(nx50)
                    break
                end
                next
            end
        }

        NxBallsService::closeWithAsking(uuid)
    end

    # --------------------------------------------------
    # nx16s

    # Mx51s::ns16OrNull(nx50)
    def self.ns16OrNull(nx50)
        uuid = nx50["uuid"]
        return nil if !DoNotShowUntil::isVisible(uuid)
        rt = BankExtended::stdRecoveredDailyTimeInHours(uuid)
        ns16 = {
            "uuid"     => uuid,
            "NS198"    => "ns16:Nx50",
            "announce" => Mx51s::toStringForNS16(nx50, rt),
            "commands" => ["..", "done", ">> (dispatch)"],
            "ordinal"  => nx50["ordinal"],
            "Nx50"     => nx50,
            "rt"       => rt
        }
        ns16
    end

    # Mx51s::ns16s()
    def self.ns16s()
        Mx51s::items()
            .map{|item| Mx51s::ns16OrNull(item) }
            .compact
    end

    # --------------------------------------------------

    # Mx51s::nx19s()
    def self.nx19s()
        Mx51s::items().map{|item|
            {
                "uuid"     => item["uuid"],
                "announce" => Mx51s::toStringForNS19(item),
                "lambda"   => lambda { Mx51s::run(item) }
            }
        }
    end
end
