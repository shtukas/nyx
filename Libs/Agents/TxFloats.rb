j# encoding: UTF-8

class TxFloats

    # TxFloats::items()
    def self.items()
        LibrarianObjects::getObjectsByMikuType("TxFloat")
    end

    # TxFloats::destroy(uuid)
    def self.destroy(uuid)
        LibrarianObjects::destroy(uuid)
    end

    # --------------------------------------------------
    # Makers

    # TxFloats::interactivelyCreateNewOrNull()
    def self.interactivelyCreateNewOrNull()
        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return nil if description == ""

        atom       = CoreData5::interactivelyCreateNewAtomOrNull()
        return nil if atom.nil?

        LibrarianObjects::commit(atom)

        uuid     = SecureRandom.uuid
        unixtime = Time.new.to_i
        datetime = Time.new.utc.iso8601

        item = {
          "uuid"        => uuid,
          "mikuType"    => "TxFloat",
          "description" => description,
          "unixtime"    => unixtime,
          "datetime"    => datetime,
          "atomuuid"    => atom["uuid"]
        }
        LibrarianObjects::commit(item)
        item
    end

    # --------------------------------------------------
    # toString

    # TxFloats::toString(mx48)
    def self.toString(mx48)
        "[floa] #{mx48["description"]}#{AgentsUtils::atomTypeForToStrings(" ", mx48["atomuuid"])}"
    end

    # TxFloats::toStringForNS19(mx48)
    def self.toStringForNS19(mx48)
        "[floa] #{mx48["description"]}"
    end

    # --------------------------------------------------
    # Operations

    # TxFloats::complete(mx48)
    def self.complete(mx48)
        TxFloats::destroy(mx48["uuid"])
    end

    # TxFloats::run(mx48)
    def self.run(mx48)

        system("clear")

        uuid = mx48["uuid"]

        NxBallsService::issue(
            uuid, 
            TxFloats::toString(mx48), 
            [uuid]
        )

        loop {

            system("clear")

            puts TxFloats::toString(mx48).green
            puts "uuid: #{uuid}".yellow

            AgentsUtils::atomLandingPresentation(mx48["atomuuid"])

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
                AgentsUtils::accessAtom(mx48["atomuuid"])
                next
            end

            if Interpreting::match("description", command) then
                description = Utils::editTextSynchronously(mx48["description"]).strip
                next if description == ""
                mx48["description"] = description
                LibrarianObjects::commit(mx48)
                next
            end

            if Interpreting::match("atom", command) then
                atom = CoreData5::interactivelyCreateNewAtomOrNull()
                next if atom.nil?
                atom["uuid"] = mx48["atomuuid"]
                LibrarianObjects::commit(atom)
                next
            end

            if Interpreting::match("note", command) then
                #text = Utils::editTextSynchronously("").strip
                #Librarian::addNote(mx48["uuid"], SecureRandom.uuid, Time.new.to_i, text)
                #next
            end

            if Interpreting::match("show json", command) then
                puts JSON.pretty_generate(mx48)
                LucilleCore::pressEnterToContinue()
                break
            end

            if command == "destroy" then
                if LucilleCore::askQuestionAnswerAsBoolean("destroy '#{TxFloats::toString(mx48)}' ? ", true) then
                    TxFloats::complete(mx48)
                    break
                end
                next
            end

            if command == "gg" then
                if LucilleCore::askQuestionAnswerAsBoolean("destroy '#{TxFloats::toString(mx48)}' ? ", true) then
                    TxFloats::complete(mx48)
                    break
                end
                next
            end
        }

        NxBallsService::closeWithAsking(uuid)
    end

    # --------------------------------------------------
    # nx16s

    # TxFloats::ns16(mx48)
    def self.ns16(mx48)
        uuid = mx48["uuid"]
        {
            "uuid"     => uuid,
            "NS198"    => "NS16:TxFloat",
            "announce" => "#{mx48["description"]}#{AgentsUtils::atomTypeForToStrings(" ", mx48["atomuuid"])}",
            "commands" => [],
            "TxFloat"     => mx48
        }
    end

    # TxFloats::ns16s(focus)
    def self.ns16s(focus)
        TxFloats::items()
            .sort{|i1, i2| i1["unixtime"] <=> i2["unixtime"] }
            .map{|item| TxFloats::ns16(item) }
    end

    # --------------------------------------------------

    # TxFloats::nx19s()
    def self.nx19s()
        TxFloats::items().map{|item|
            {
                "uuid"     => item["uuid"],
                "announce" => TxFloats::toStringForNS19(item),
                "lambda"   => lambda { TxFloats::run(item) }
            }
        }
    end
end
