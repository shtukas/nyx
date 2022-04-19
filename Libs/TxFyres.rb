j# encoding: UTF-8

class TxFyres

    # TxFyres::items()
    def self.items()
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

        iAmValue = Nx111::interactivelyCreateNewIamValueOrNull(Nx111::iamTypesForManualMakingOfCatalystItems())
        return nil if iAmValue.nil?

        uuid       = SecureRandom.uuid
        unixtime   = Time.new.to_i
        datetime   = Time.new.utc.iso8601

        universe    = Multiverse::interactivelySelectUniverse()

        item = {
          "uuid"        => uuid,
          "mikuType"    => "TxFyre",
          "description" => description,
          "unixtime"    => unixtime,
          "datetime"    => datetime,
          "iam"         => iAmValue
        }
        Librarian6Objects::commit(item)
        ObjectUniverseMapping::setObjectUniverseMapping(uuid, universe)
        item
    end

    # TxFyres::interactivelyIssueItemUsingInboxLocation(location)
    def self.interactivelyIssueItemUsingInboxLocation(location)
        uuid        = SecureRandom.uuid
        description = Inbox::interactivelyDecideBestDescriptionForLocation(location)
        unixtime    = Time.new.to_i
        datetime    = Time.new.utc.iso8601

        rootnhash   = AionCore::commitLocationReturnHash(Librarian14ElizabethLocalStandard.new(), location)
        iAmValue    = ["aion-point", rootnhash]

        universe    = Multiverse::interactivelySelectUniverse()

        item = {
          "uuid"        => uuid,
          "mikuType"    => "TxFyre",
          "description" => description,
          "unixtime"    => unixtime,
          "datetime"    => datetime,
          "iam"         => iAmValue,
          "ordinal"     => ordinal
        }
        Librarian6Objects::commit(item)
        ObjectUniverseMapping::setObjectUniverseMapping(uuid, universe)
        item
    end

    # --------------------------------------------------
    # toString

    # TxFyres::toString(item)
    def self.toString(item)
        "(fyre) #{item["description"]} (#{item["iam"][0]})"
    end

    # TxFyres::toStringForNS16(item, rt)
    def self.toStringForNS16(item, rt)
        "(fyre) (#{"%4.2f" % rt}) #{item["description"]} (#{item["iam"][0]})"
    end

    # TxFyres::toStringForNS19(item)
    def self.toStringForNS19(item)
        "(fyre) #{item["description"]}"
    end

    # --------------------------------------------------
    # Operations

    # TxFyres::complete(item)
    def self.complete(item)
        TxFyres::destroy(item["uuid"])
    end

    # TxFyres::landing(item)
    def self.landing(item)

        loop {

            system("clear")

            uuid = item["uuid"]

            store = ItemStore.new()

            puts TxFyres::toString(item).green
            puts "uuid: #{uuid}".yellow
            puts "iam: #{item["iam"]}".yellow
            puts "RT: #{BankExtended::stdRecoveredDailyTimeInHours(uuid)}".yellow

            TxAttachments::itemsForOwner(uuid).each{|attachment|
                indx = store.register(attachment, false)
                puts "[#{indx.to_s.ljust(3)}] #{TxAttachments::toString(attachment)}" 
            }

            puts "access | <datecode> | description | iam | attachment | show json | universe | transmute | destroy (gg) | exit (xx)".yellow

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
                Nx111::accessIamCarrierPossibleStorageMutation(item)
                next
            end

            if Interpreting::match("description", command) then
                description = Utils::editTextSynchronously(item["description"]).strip
                next if description == ""
                item["description"] = description
                Librarian6Objects::commit(item)
                next
            end

            if Interpreting::match("iam", command) then
                iAmValue = Nx111::interactivelyCreateNewIamValueOrNull(Nx111::iamTypesForManualMakingOfCatalystItems())
                next if iAmValue.nil?
                puts JSON.pretty_generate(iAmValue)
                if LucilleCore::askQuestionAnswerAsBoolean("confirm change ? ") then
                    item["iam"] = iAmValue
                    Librarian6Objects::commit(item)
                end
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
        TxFyres::items()
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
        TxFyres::items().map{|item|
            {
                "announce" => TxFyres::toStringForNS19(item),
                "unixtime" => item["unixtime"],
                "payload"  => item
            }
        }
    end
end
