j# encoding: UTF-8

class TxDrops

    # TxDrops::mikus()
    def self.mikus()
        LibrarianObjects::getObjectsByMikuType("TxDrop")
    end

    # TxDrops::destroy(uuid)
    def self.destroy(uuid)
        LibrarianObjects::destroy(uuid)
    end

    # --------------------------------------------------
    # Makers

    # TxDrops::interactivelyCreateNewOrNull()
    def self.interactivelyCreateNewOrNull()
        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return nil if description == ""

        atom       = Atoms5::interactivelyCreateNewAtomOrNull()
        return nil if atom.nil?

        LibrarianObjects::commit(atom)

        uuid       = SecureRandom.uuid
        unixtime   = Time.new.to_i
        datetime   = Time.new.utc.iso8601
        domainx    = DomainsX::interactivelySelectDomainX()

        item = {
          "uuid"        => uuid,
          "mikuType"    => "TxDrop",
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

    # TxDrops::toString(nx70)
    def self.toString(nx70)
        "[drop] #{nx70["description"]}#{AgentsUtils::atomTypeForToStrings(" ", nx70["atomuuid"])}"
    end

    # TxDrops::toStringForNS19(nx70)
    def self.toStringForNS19(nx70)
        "[drop] #{nx70["description"]}"
    end

    # --------------------------------------------------
    # Operations

    # TxDrops::complete(nx70)
    def self.complete(nx70)
        TxDrops::destroy(nx70["uuid"])
    end

    # TxDrops::run(nx70)
    def self.run(nx70)

        system("clear")

        uuid = nx70["uuid"]

        NxBallsService::issue(
            uuid, 
            TxDrops::toString(nx70), 
            [uuid]
        )

        loop {

            system("clear")

            puts TxDrops::toString(nx70).green
            puts "uuid: #{uuid}".yellow
            puts "domainx: #{nx70["domainx"]}".yellow

            AgentsUtils::atomLandingPresentation(nx70["atomuuid"])

            #Librarian::notes(uuid).each{|note|
            #    puts "note: #{note["text"]}"
            #}

            puts "access | <datecode> | description | atom | note | show json | transmute | destroy (gg) | exit (xx)".yellow

            command = LucilleCore::askQuestionAnswerAsString("> ")

            break if command == "exit"
            break if command == "xx"

            if (unixtime = Utils::codeToUnixtimeOrNull(command.gsub(" ", ""))) then
                DoNotShowUntil::setUnixtime(uuid, unixtime)
                break
            end

            if Interpreting::match("access", command) then
                AgentsUtils::accessAtom(nx70["atomuuid"])
                next
            end

            if Interpreting::match("description", command) then
                description = Utils::editTextSynchronously(nx70["description"]).strip
                next if description == ""
                nx70["description"] = description
                LibrarianObjects::commit(nx70)
                next
            end

            if Interpreting::match("atom", command) then
                atom = Atoms5::interactivelyCreateNewAtomOrNull()
                next if atom.nil?
                atom["uuid"] = nx70["atomuuid"]
                LibrarianObjects::commit(atom)
                next
            end

            if Interpreting::match("note", command) then
                #text = Utils::editTextSynchronously("").strip
                #Librarian::addNote(nx70["uuid"], SecureRandom.uuid, Time.new.to_i, text)
                #next
            end

            if Interpreting::match("transmute", command) then
                CommandsOps::transmutation2(nx70, "TxDrop")
                break
            end

            if Interpreting::match("show json", command) then
                puts JSON.pretty_generate(nx70)
                LucilleCore::pressEnterToContinue()
                break
            end

            if command == "destroy" then
                if LucilleCore::askQuestionAnswerAsBoolean("destroy '#{TxDrops::toString(nx70)}' ? ", true) then
                    TxDrops::complete(nx70)
                    break
                end
                next
            end

            if command == "gg" then
                if LucilleCore::askQuestionAnswerAsBoolean("destroy '#{TxDrops::toString(nx70)}' ? ", true) then
                    TxDrops::complete(nx70)
                    break
                end
                next
            end
        }

        NxBallsService::closeWithAsking(uuid)
    end

    # --------------------------------------------------
    # nx16s

    # TxDrops::ns16(nx70)
    def self.ns16(nx70)
        uuid = nx70["uuid"]
        {
            "uuid"     => uuid,
            "NS198"    => "NS16:TxDrop",
            "announce" => "(drop) #{nx70["description"]}#{AgentsUtils::atomTypeForToStrings(" ", nx70["atomuuid"])}",
            "commands" => ["..", "done", "''", ">> (transmute)"],
            "TxDrop"   => nx70
        }
    end

    # TxDrops::ns16s()
    def self.ns16s()
        focus = DomainsX::focus()
        TxDrops::mikus()
            .select{|item| focus.nil? or (item["domainx"] == focus) }
            .sort{|i1, i2| i1["unixtime"] <=> i2["unixtime"] }
            .map{|item| TxDrops::ns16(item) }
    end

    # --------------------------------------------------

    # TxDrops::nx19s()
    def self.nx19s()
        TxDrops::mikus().map{|item|
            {
                "uuid"     => item["uuid"],
                "announce" => TxDrops::toStringForNS19(item),
                "lambda"   => lambda { TxDrops::run(item) }
            }
        }
    end
end
