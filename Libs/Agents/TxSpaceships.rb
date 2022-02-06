j# encoding: UTF-8

class TxSpaceships

    # TxSpaceships::items()
    def self.items()
        LibrarianObjects::getObjectsByMikuType("TxSpaceship")
    end

    # TxSpaceships::destroy(uuid)
    def self.destroy(uuid)
        LibrarianObjects::destroy(uuid)
    end

    # --------------------------------------------------
    # Makers

    # TxSpaceships::interactivelyCreateNewOrNull()
    def self.interactivelyCreateNewOrNull()
        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return nil if description == ""

        atom       = Atoms5::interactivelyCreateNewAtomOrNull()
        return nil if atom.nil?

        uuid       = SecureRandom.uuid
        unixtime   = Time.new.to_i
        datetime   = Time.new.utc.iso8601
        domainx    = DomainsX::interactivelySelectDomainX()

        item = {
          "uuid"        => uuid,
          "mikuType"    => "TxSpaceship",
          "description" => description,
          "unixtime"    => unixtime,
          "datetime"    => datetime,
          "atomuuid"    => atom["uuid"],
          "domainx"     => domainx
        }
        LibrarianObjects::commit(item)
        item
    end

    # --------------------------------------------------
    # toString

    # TxSpaceships::toString(nx60)
    def self.toString(nx60)
        "[ship] #{nx60["description"]}"
    end

    # TxSpaceships::toStringForNS19(nx60)
    def self.toStringForNS19(nx60)
        "[ship] #{nx60["description"]}"
    end

    # --------------------------------------------------
    # Operations

    # TxSpaceships::complete(nx60)
    def self.complete(nx60)
        TxSpaceships::destroy(nx60["uuid"])
    end

    # TxSpaceships::run(nx60)
    def self.run(nx60)

        system("clear")

        uuid = nx60["uuid"]

        NxBallsService::issue(
            uuid, 
            TxSpaceships::toString(nx60), 
            [uuid, DomainsX::domainXToAccountNumber(nx60["domainx"])]
        )

        loop {

            system("clear")

            puts TxSpaceships::toString(nx60).green
            puts "uuid: #{uuid}".yellow
            puts "domain: #{nx60["domainx"]}".yellow

            AgentsUtils::atomLandingPresentation(nx60["atomuuid"])

            #Librarian::notes(uuid).each{|note|
            #    puts "note: #{note["text"]}"
            #}

            puts "access | <datecode> | description | atom | note | show json | destroy (gg) | exit (xx)".yellow

            command = LucilleCore::askQuestionAnswerAsString("> ")

            break if command == "exit"
            break if command == "xx"

            if (unixtime = Utils::codeToUnixtimeOrNull(command.gsub(" ", ""))) then
                DoNotShowUntil::setUnixtime(uuid, unixtime)
                break
            end

            if Interpreting::match("access", command) then
                AgentsUtils::accessAtom(nx60["atomuuid"])
                next
            end

            if Interpreting::match("description", command) then
                description = Utils::editTextSynchronously(nx60["description"]).strip
                next if description == ""
                nx60["description"] = description
                LibrarianObjects::commit(nx60)
                next
            end

            if Interpreting::match("atom", command) then
                atom = Atoms5::interactivelyCreateNewAtomOrNull()
                next if atom.nil?
                atom["uuid"] = nx60["atomuuid"]
                LibrarianObjects::commit(nx60)
                next
            end

            if Interpreting::match("note", command) then
                #text = Utils::editTextSynchronously("").strip
                #Librarian::addNote(nx60["uuid"], SecureRandom.uuid, Time.new.to_i, text)
                #next
            end

            if Interpreting::match("show json", command) then
                puts JSON.pretty_generate(nx60)
                LucilleCore::pressEnterToContinue()
                break
            end

            if command == "destroy" then
                if LucilleCore::askQuestionAnswerAsBoolean("destroy '#{TxSpaceships::toString(nx60)}' ? ", true) then
                    TxSpaceships::complete(nx60)
                    break
                end
                next
            end

            if command == "gg" then
                if LucilleCore::askQuestionAnswerAsBoolean("destroy '#{TxSpaceships::toString(nx60)}' ? ", true) then
                    TxSpaceships::complete(nx60)
                    break
                end
                next
            end
        }

        NxBallsService::closeWithAsking(uuid)
    end

    # --------------------------------------------------
    # nx16s

    # TxSpaceships::toStringForNS16(nx60, rt)
    def self.toStringForNS16(nx60, rt)
        "[ship] (#{"%4.2f" % rt}) #{nx60["description"]}"
    end

    # TxSpaceships::ns16(nx60)
    def self.ns16(nx60)
        uuid = nx60["uuid"]
        rt = BankExtended::stdRecoveredDailyTimeInHours(uuid)
        if rt > 1 then
            ItemStoreOps::delistForDefault(uuid)
        end
        {
            "uuid"     => uuid,
            "NS198"    => "NS16:TxSpaceship",
            "announce" => TxSpaceships::toStringForNS16(nx60, rt).gsub("(0.00)", "      "),
            "commands" => ["..", "''", ">> (transmute)"],
            "TxSpaceship"     => nx60,
            "rt"       => rt
        }
    end

    # TxSpaceships::ns16s()
    def self.ns16s()
        TxSpaceships::items()
            .sort{|i1, i2| i1["unixtime"] <=> i2["unixtime"] }
            .map{|item| TxSpaceships::ns16(item) }
    end

    # TxSpaceships::ns16sForDominant()
    def self.ns16sForDominant()
        focus = DomainsX::focusOrNull()
        TxSpaceships::items()
            .sort{|i1, i2| i1["unixtime"] <=> i2["unixtime"] }
            .select{|item| focus.nil? or (item["domainx"] == focus) }
            .map{|item| TxSpaceships::ns16(item) }
    end

    # --------------------------------------------------

    # TxSpaceships::nx19s()
    def self.nx19s()
        TxSpaceships::items().map{|item|
            {
                "uuid"     => item["uuid"],
                "announce" => TxSpaceships::toStringForNS19(item),
                "lambda"   => lambda { TxSpaceships::run(item) }
            }
        }
    end
end
