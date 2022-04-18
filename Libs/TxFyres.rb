j# encoding: UTF-8

class TxFyres

    # TxFyres::mikus()
    def self.mikus()
        Librarian6Objects::getObjectsByMikuType("TxFyre")
    end

    # TxFyres::destroy(uuid)
    def self.destroy(uuid)
        Librarian6Objects::destroy(uuid)
    end

    # --------------------------------------------------
    # Makers

    # TxFyres::interactivelyCreateNewOrNull()
    def self.interactivelyCreateNewOrNull()
        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return nil if description == ""

        atom       = Librarian5Atoms::interactivelyIssueNewAtomOrNull()
        return nil if atom.nil?

        uuid       = SecureRandom.uuid
        unixtime   = Time.new.to_i
        datetime   = Time.new.utc.iso8601

        item = {
          "uuid"        => uuid,
          "mikuType"    => "TxFyre",
          "description" => description,
          "unixtime"    => unixtime,
          "datetime"    => datetime,
          "atomuuid"    => atom["uuid"]
        }
        Librarian6Objects::commit(item)
        item
    end

    # --------------------------------------------------
    # toString

    # TxFyres::toString(nx70)
    def self.toString(nx70)
        "(fyre) #{nx70["description"]}#{Librarian5Atoms::atomTypeForToStrings(" ", nx70["atomuuid"])}"
    end

    # TxFyres::toStringForNS16(nx70, rt)
    def self.toStringForNS16(nx70, rt)
        "(fyre) (#{"%4.2f" % rt}) #{nx70["description"]}#{Librarian5Atoms::atomTypeForToStrings(" ", nx70["atomuuid"])}"
    end

    # TxFyres::toStringForNS19(nx70)
    def self.toStringForNS19(nx70)
        "(fyre) #{nx70["description"]}"
    end

    # --------------------------------------------------
    # Operations

    # TxFyres::complete(nx70)
    def self.complete(nx70)
        TxFyres::destroy(nx70["uuid"])
    end

    # TxFyres::landing(item)
    def self.landing(item)

        loop {

            system("clear")

            uuid = item["uuid"]

            store = ItemStore.new()

            puts TxFyres::toString(item).green
            puts "uuid: #{uuid}".yellow
            puts "RT: #{BankExtended::stdRecoveredDailyTimeInHours(uuid)}".yellow

            TxAttachments::itemsForOwner(uuid).each{|attachment|
                indx = store.register(attachment, false)
                puts "[#{indx.to_s.ljust(3)}] #{TxAttachments::toString(attachment)}" 
            }

            Librarian5Atoms::atomLandingPresentation(item["atomuuid"])

            puts "access | <datecode> | description | atom | attachment | show json | universe | transmute | destroy (gg) | exit (xx)".yellow

            command = LucilleCore::askQuestionAnswerAsString("> ")

            break if command == "exit"
            break if command == "xx"

            if (indx = Interpreting::readAsIntegerOrNull(command)) then
                entity = store.get(indx)
                next if entity.nil?
                LxAction::action("landing", entity)
            end

            if (unixtime = Utils::codeToUnixtimeOrNull(command.gsub(" ", ""))) then
                DoNotShowUntil::setUnixtime(uuid, unixtime)
                break
            end

            if Interpreting::match("access", command) then
                Librarian5Atoms::accessAtom(item["atomuuid"])
                next
            end

            if Interpreting::match("description", command) then
                description = Utils::editTextSynchronously(item["description"]).strip
                next if description == ""
                item["description"] = description
                Librarian6Objects::commit(item)
                next
            end

            if Interpreting::match("atom", command) then
                atom = Librarian5Atoms::interactivelyIssueNewAtomOrNull()
                next if atom.nil?
                item["atomuuid"] = atom["uuid"]
                Librarian6Objects::commit(item)
                next
            end

            if Interpreting::match("attachment", command) then
                TxAttachments::interactivelyCreateNewOrNullForOwner(item["uuid"])
                next
            end

            if Interpreting::match("transmute", command) then
                Transmutation::transmutation2(item, "TxFyre")
                break
            end

            if Interpreting::match("universe", command) then
                ObjectUniverseMapping::interactivelySetObjectUniverseMapping(item["uuid"])
                next
            end

            if Interpreting::match("show json", command) then
                puts JSON.pretty_generate(item)
                LucilleCore::pressEnterToContinue()
                break
            end

            if command == "destroy" then
                if LucilleCore::askQuestionAnswerAsBoolean("destroy '#{TxFyres::toString(item)}' ? ", true) then
                    TxFyres::complete(item)
                    break
                end
                next
            end

            if command == "gg" then
                if LucilleCore::askQuestionAnswerAsBoolean("destroy '#{TxFyres::toString(item)}' ? ", true) then
                    TxFyres::complete(item)
                    break
                end
                next
            end
        }
    end

    # --------------------------------------------------
    # nx16s

    # TxFyres::ns16(nx70)
    def self.ns16(nx70)
        uuid = nx70["uuid"]
        rt = BankExtended::stdRecoveredDailyTimeInHours(uuid)
        announce = TxFyres::toStringForNS16(nx70, rt)
        if rt < 1 then
            announce = announce.red
        end
        {
            "uuid"     => uuid,
            "mikuType" => "NS16:TxFyre",
            "announce" => announce,
            "TxFyre"   => nx70,
            "rt"       => rt
        }
    end

    # TxFyres::ns16s(universe)
    def self.ns16s(universe)
        TxFyres::mikus()
            .select{|item| 
                objuniverse = ObjectUniverseMapping::getObjectUniverseMappingOrNull(item["uuid"])
                universe.nil? or objuniverse.nil? or (objuniverse == universe)
            }
            .map{|item| TxFyres::ns16(item) }
            .sort{|x1, x2| x1["rt"] <=> x2["rt"]}
    end

    # --------------------------------------------------

    # TxFyres::nx20s()
    def self.nx20s()
        TxFyres::mikus().map{|item|
            {
                "announce" => TxFyres::toStringForNS19(item),
                "unixtime" => item["unixtime"],
                "payload"  => item
            }
        }
    end
end
