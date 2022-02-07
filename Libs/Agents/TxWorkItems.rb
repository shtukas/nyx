# encoding: UTF-8

class TxWorkItems

    # TxWorkItems::items()
    def self.items()
        LibrarianObjects::getObjectsByMikuType("TxWorkItem")
    end

    # TxWorkItems::destroy(uuid)
    def self.destroy(uuid)
        LibrarianObjects::destroy(uuid)
    end

    # --------------------------------------------------
    # Ordinals

    # TxWorkItems::nextOrdinal()
    def self.nextOrdinal()
        biggest = ([0] + TxWorkItems::items().map{|mx51| mx51["ordinal"] }).max
        (biggest + 1).floor
    end

    # TxWorkItems::ordinalBetweenN1thAndN2th(n1, n2)
    def self.ordinalBetweenN1thAndN2th(n1, n2)
        mx51s = TxWorkItems::items()
        if mx51s.size < n1+2 then
            return TxWorkItems::nextOrdinal()
        end
        ordinals = mx51s.map{|mx51| mx51["ordinal"] }.sort.drop(n1).take(n2-n1)
        ordinals.min + rand*(ordinals.max-ordinals.min)
    end

    # TxWorkItems::interactivelyDecideNewOrdinal()
    def self.interactivelyDecideNewOrdinal()
        TxWorkItems::items()
            .sort{|i1, i2| i1["ordinal"] <=> i2["ordinal"] }
            .first(50)
            .each{|mx51| 
                puts "- #{TxWorkItems::toStringWithOrdinal(mx51)}"
            }
        ordinal = LucilleCore::askQuestionAnswerAsString("> ordinal ? : ")
        if ordinal == "" then
            return TxWorkItems::nextOrdinal()
        end
        ordinal.to_f
    end

    # --------------------------------------------------
    # Makers

    # TxWorkItems::interactivelyCreateNewOrNull()
    def self.interactivelyCreateNewOrNull()
        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return nil if description == ""

        atom = Atoms5::interactivelyCreateNewAtomOrNull()
        return nil if atom.nil?

        LibrarianObjects::commit(atom)

        uuid       = SecureRandom.uuid
        unixtime   = Time.new.to_i
        datetime   = Time.new.utc.iso8601
        ordinal    = TxWorkItems::interactivelyDecideNewOrdinal()
        item = {
          "uuid"        => uuid,
          "mikuType"    => "TxWorkItem",
          "description" => description,
          "unixtime"    => unixtime,
          "datetime"    => datetime,
          "atomuuid"    => atom["uuid"],
          "ordinal"     => ordinal
        }
        LibrarianObjects::commit(item)
        item
    end

    # TxWorkItems::issueItemUsingInboxLocation(location)
    def self.issueItemUsingInboxLocation(location)
        uuid        = SecureRandom.uuid
        description = Inbox::interactivelyDecideBestDescriptionForLocation(location)
        unixtime    = Time.new.to_i
        datetime    = Time.new.utc.iso8601
        atom        = Atoms5::issueAionPointAtomUsingLocation(location)
        LibrarianObjects::commit(atom)
        ordinal     = TxWorkItems::interactivelyDecideNewOrdinal()
        item = {
          "uuid"        => uuid,
          "mikuType"    => "TxWorkItem",
          "description" => description,
          "unixtime"    => unixtime,
          "datetime"    => datetime,
          "atomuuid"    => atom["uuid"],
          "ordinal"     => ordinal
        }
        LibrarianObjects::commit(item)
        item
    end

    # --------------------------------------------------
    # toString

    # TxWorkItems::toString(mx51)
    def self.toString(mx51)
        "[work] #{mx51["description"]}#{AgentsUtils::atomTypeForToStrings(" ", mx51["atomuuid"])}"
    end

    # TxWorkItems::toStringWithOrdinal(mx51)
    def self.toStringWithOrdinal(mx51)
        "[work] (ord: #{mx51["ordinal"]}) #{mx51["description"]}#{AgentsUtils::atomTypeForToStrings(" ", mx51["atomuuid"])}"
    end

    # TxWorkItems::toStringForNS19(mx51)
    def self.toStringForNS19(mx51)
        "[work] #{mx51["description"]}"
    end

    # TxWorkItems::toStringForNS16(mx51, rt)
    def self.toStringForNS16(mx51, rt)
        "[work] (#{"%4.2f" % rt}) #{mx51["description"]}#{AgentsUtils::atomTypeForToStrings(" ", mx51["atomuuid"])}"
    end

    # --------------------------------------------------
    # Operations

    # TxWorkItems::run(mx51)
    def self.run(mx51)

        system("clear")

        uuid = mx51["uuid"]

        NxBallsService::issue(uuid, mx51["description"], [uuid])

        loop {

            system("clear")

            puts "#{TxWorkItems::toString(mx51)}#{NxBallsService::runningStringOrEmptyString(" (", uuid, ")")}".green
            puts "uuid: #{uuid}".yellow
            puts "ordinal: #{mx51["ordinal"]}".yellow
            puts "DoNotDisplayUntil: #{DoNotShowUntil::getDateTimeOrNull(mx51["uuid"])}".yellow
            puts "RT: #{BankExtended::stdRecoveredDailyTimeInHours(uuid)}".yellow

            AgentsUtils::atomLandingPresentation(mx51["atomuuid"])

            #Librarian::notes(uuid).each{|note|
            #    puts "note: #{note["text"]}"
            #}

            puts "access | <datecode> | description | atom | ordinal | rotate | >> (transmute) | note | show json | destroy (gg) | exit (xx)".yellow

            command = LucilleCore::askQuestionAnswerAsString("> ")

            break if command == "exit"
            break if command == "xx"

            if (unixtime = Utils::codeToUnixtimeOrNull(command.gsub(" ", ""))) then
                DoNotShowUntil::setUnixtime(uuid, unixtime)
                break
            end

            if Interpreting::match("access", command) then
                AgentsUtils::accessAtom(mx51["atomuuid"])
                next
            end

            if Interpreting::match("description", command) then
                description = Utils::editTextSynchronously(mx51["description"]).strip
                next if description == "" 
                mx51["description"] = description
                LibrarianObjects::commit(mx51)
                next
            end

            if Interpreting::match("atom", command) then
                atom = Atoms5::interactivelyCreateNewAtomOrNull()
                next if atom.nil?
                atom["uuid"] = mx51["atomuuid"]
                LibrarianObjects::commit(atom)
                next
            end

            if Interpreting::match("note", command) then
                #text = Utils::editTextSynchronously("").strip
                #Librarian::addNote(mx51["uuid"], SecureRandom.uuid, Time.new.to_i, text)
                next
            end

            if Interpreting::match("ordinal", command) then
                ordinal = TxWorkItems::interactivelyDecideNewOrdinal()
                mx51["ordinal"] = ordinal
                LibrarianObjects::commit(mx51)
                next
            end

            if Interpreting::match("rotate", command) then
                mx51["ordinal"] = TxWorkItems::nextOrdinal()
                LibrarianObjects::commit(mx51)
                break
            end

            if Interpreting::match(">>", command) then
                CommandsOps::transmutation2(mx51, "TxWorkItem")
                break
            end

            if Interpreting::match("show json", command) then
                puts JSON.pretty_generate(mx51)
                LucilleCore::pressEnterToContinue()
                break
            end

            if command == "destroy" then
                if LucilleCore::askQuestionAnswerAsBoolean("destroy '#{TxWorkItems::toString(mx51)}' ? ", true) then
                    TxWorkItems::destroy(mx51["uuid"])
                    break
                end
                next
            end

            if command == "gg" then
                if LucilleCore::askQuestionAnswerAsBoolean("destroy '#{TxWorkItems::toString(mx51)}' ? ", true) then
                    TxWorkItems::destroy(mx51["uuid"])
                    break
                end
                next
            end
        }

        NxBallsService::closeWithAsking(uuid)
    end

    # --------------------------------------------------
    # nx16s

    # TxWorkItems::ns16OrNull(mx51)
    def self.ns16OrNull(mx51)
        uuid = mx51["uuid"]
        return nil if !DoNotShowUntil::isVisible(uuid)
        rt = BankExtended::stdRecoveredDailyTimeInHours(uuid)
        ns16 = {
            "uuid"       => uuid,
            "NS198"      => "NS16:TxWorkItem",
            "announce"   => TxWorkItems::toStringForNS16(mx51, rt).gsub("(0.00)", "      "),
            "commands"   => ["..", "done", ">> (transmute)"],
            "ordinal"    => mx51["ordinal"],
            "TxWorkItem" => mx51,
            "rt"         => rt
        }
        ns16
    end

    # TxWorkItems::ns16s()
    def self.ns16s()
        ns16s = TxWorkItems::items()
                    .map{|item| TxWorkItems::ns16OrNull(item) }
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

    # TxWorkItems::nx19s()
    def self.nx19s()
        TxWorkItems::items().map{|item|
            {
                "uuid"     => item["uuid"],
                "announce" => TxWorkItems::toStringForNS19(item),
                "lambda"   => lambda { TxWorkItems::run(item) }
            }
        }
    end
end
