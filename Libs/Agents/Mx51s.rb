# encoding: UTF-8

class Mx51s

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

    # Mx51s::destroy(uuid)
    def self.destroy(uuid)
        filepath = "/Users/pascal/Galaxy/DataBank/Catalyst/Mx51s/#{Digest::SHA1.hexdigest(uuid)[0, 10]}.json"
        return if !File.exists?(filepath)
        FileUtils.rm(filepath)
    end

    # --------------------------------------------------
    # Ordinals

    # Mx51s::nextOrdinal()
    def self.nextOrdinal()
        biggest = ([0] + Mx51s::items().map{|mx51| mx51["ordinal"] }).max
        (biggest + 1).floor
    end

    # Mx51s::ordinalBetweenN1thAndN2th(n1, n2)
    def self.ordinalBetweenN1thAndN2th(n1, n2)
        mx51s = Mx51s::items()
        if mx51s.size < n1+2 then
            return Mx51s::nextOrdinal()
        end
        ordinals = mx51s.map{|mx51| mx51["ordinal"] }.sort.drop(n1).take(n2-n1)
        ordinals.min + rand*(ordinals.max-ordinals.min)
    end

    # Mx51s::interactivelyDecideNewOrdinal()
    def self.interactivelyDecideNewOrdinal()
        Mx51s::items()
            .first(50)
            .each{|mx51| 
                puts "- #{Mx51s::toStringWithOrdinal(mx51)}"
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
        mx51 = {
            "uuid"        => uuid,
            "unixtime"    => Time.new.to_i,
            "ordinal"     => ordinal,
            "description" => description,
            "atom"        => atom
        }
        Mx51s::commit(mx51)
        mx51
    end

    # Mx51s::issueItemUsingInboxLocation(location)
    def self.issueItemUsingInboxLocation(location)
        uuid = SecureRandom.uuid
        item = {
            "uuid"        => uuid,
            "unixtime"    => Time.new.to_i,
            "ordinal"     => Mx51s::interactivelyDecideNewOrdinal(),
            "description" => File.basename(location),
            "atom"        => CoreData5::issueAionPointAtomUsingLocation(location),
        }
        Mx51s::commit(item)
        item
    end

    # --------------------------------------------------
    # toString

    # Mx51s::toString(mx51)
    def self.toString(mx51)
        "[work] #{mx51["description"]} (#{mx51["atom"]["type"]})"
    end

    # Mx51s::toStringWithOrdinal(mx51)
    def self.toStringWithOrdinal(mx51)
        "[work] (ord: #{mx51["ordinal"]}) #{mx51["description"]} (#{mx51["atom"]["type"]})"
    end

    # Mx51s::toStringForNS19(mx51)
    def self.toStringForNS19(mx51)
        "[work] #{mx51["description"]}"
    end

    # Mx51s::toStringForNS16(mx51, rt)
    def self.toStringForNS16(mx51, rt)
        "[work] (#{"%4.2f" % rt}) #{mx51["description"]} (#{mx51["atom"]["type"]})"
    end

    # --------------------------------------------------
    # Operations

    # Mx51s::accessContent(mx51)
    def self.accessContent(mx51)
        updated = CoreData5::accessWithOptionToEdit(mx51["atom"])
        if updated then
            mx51["atom"] = updated
            Mx51s::commit(mx51)
        end
    end

    # Mx51s::run(mx51)
    def self.run(mx51)

        system("clear")

        uuid = mx51["uuid"]

        NxBallsService::issue(uuid, mx51["description"], [uuid, TwentyTwo::workAccount()])

        loop {

            system("clear")

            puts "#{Mx51s::toString(mx51)}#{NxBallsService::runningStringOrEmptyString(" (", uuid, ")")}".green
            puts "uuid: #{uuid}".yellow
            puts "ordinal: #{mx51["ordinal"]}".yellow
            puts "DoNotDisplayUntil: #{DoNotShowUntil::getDateTimeOrNull(mx51["uuid"])}".yellow
            puts "RT: #{BankExtended::stdRecoveredDailyTimeInHours(uuid)}".yellow

            if text = CoreData5::atomPayloadToTextOrNull(mx51["atom"]) then
                puts text
            end

            note = StructuredTodoTexts::getNoteOrNull(mx51["uuid"])
            if note then
                puts "note:\n#{note}".green
            end

            puts "access | note | <datecode> | description | atom | ordinal | rotate | >> (transmute) | show json | destroy (gg) | exit (xx)".yellow

            command = LucilleCore::askQuestionAnswerAsString("> ")

            break if command == "exit"
            break if command == "xx"

            if (unixtime = Utils::codeToUnixtimeOrNull(command.gsub(" ", ""))) then
                DoNotShowUntil::setUnixtime(uuid, unixtime)
                break
            end

            if Interpreting::match("access", command) then
                Mx51s::accessContent(mx51)
                next
            end

            if command == "note" then
                note = Utils::editTextSynchronously(StructuredTodoTexts::getNoteOrNull(mx51["uuid"]) || "")
                StructuredTodoTexts::setNote(uuid, note)
                next
            end

            if Interpreting::match("description", command) then
                description = Utils::editTextSynchronously(mx51["description"]).strip
                next if description == ""
                mx51["description"] = description
                Mx51s::commit(mx51)
                next
            end

            if Interpreting::match("atom", command) then
                mx51["atom"] = CoreData5::interactivelyCreateNewAtomOrNull()
                Mx51s::commit(mx51)
                next
            end

            if Interpreting::match("ordinal", command) then
                ordinal = Mx51s::interactivelyDecideNewOrdinal()
                mx51["ordinal"] = ordinal
                Mx51s::commit(mx51)
                next
            end

            if Interpreting::match("rotate", command) then
                mx51["ordinal"] = Mx51s::nextOrdinal()
                Mx51s::commit(mx51)
                break
            end

            if Interpreting::match(">>", command) then
                CommandsOps::transmutation({
                    "type" => "mx51-work-item-transmutation",
                    "mx51" => mx51
                })
                break
            end

            if Interpreting::match("show json", command) then
                puts JSON.pretty_generate(mx51)
                LucilleCore::pressEnterToContinue()
                break
            end

            if command == "destroy" then
                if LucilleCore::askQuestionAnswerAsBoolean("destroy '#{Mx51s::toString(mx51)}' ? ", true) then
                    Mx51s::destroy(mx51["uuid"])
                    break
                end
                next
            end

            if command == "gg" then
                if LucilleCore::askQuestionAnswerAsBoolean("destroy '#{Mx51s::toString(mx51)}' ? ", true) then
                    Mx51s::destroy(mx51["uuid"])
                    break
                end
                next
            end
        }

        NxBallsService::closeWithAsking(uuid)
    end

    # --------------------------------------------------
    # nx16s

    # Mx51s::ns16OrNull(mx51)
    def self.ns16OrNull(mx51)
        uuid = mx51["uuid"]
        return nil if !DoNotShowUntil::isVisible(uuid)
        rt = BankExtended::stdRecoveredDailyTimeInHours(uuid)
        ns16 = {
            "uuid"     => uuid,
            "NS198"    => "ns16:Mx51",
            "announce" => Mx51s::toStringForNS16(mx51, rt).gsub("(0.00)", "      "),
            "commands" => ["..", "done", ">> (transmute)"],
            "ordinal"  => mx51["ordinal"],
            "Mx51"     => mx51,
            "rt"       => rt
        }
        ns16
    end

    # Mx51s::ns16s()
    def self.ns16s()
        ns16s = Mx51s::items()
                    .map{|item| Mx51s::ns16OrNull(item) }
                    .compact

        p1 = ns16s
                .first(6)
                .sort{|x1, x2|
                    (x1["rt"] > 0 ? x1["rt"] : 0.25)  <=> (x2["rt"] > 0 ? x2["rt"] : 0.25)
                }
        p2 = ns16s.drop(6)
        p1 + p2
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
