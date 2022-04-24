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
    # Fyre Styles

    # TxFyres::makeDefaultFyreStyle()
    def self.makeDefaultFyreStyle()
        {
            "style"       => "daily-time-commitment",
            "timeInHours" => 1
        }
    end

    # TxFyres::interactivelyMakeNewFyreStyle()
    def self.interactivelyMakeNewFyreStyle()
        styles = [
            "one-daily-impact",
            "daily-time-commitment (default)"
        ]
        style = LucilleCore::selectEntityFromListOfEntitiesOrNull("Fyre style", styles)
        if style.nil? then
            return TxFyres::makeDefaultFyreStyle()
        end
        if style == "one-daily-impact" then
            return {
                "style" => "one-daily-impact"
            }
        end
        if style == "daily-time-commitment (default)" then
            hours = LucilleCore::askQuestionAnswerAsString("Commitment in hours (defaults to 1 hour): ").to_f
            if hours == 0 then
                hours = 1
            end
            return {
                "style"       => "daily-time-commitment",
                "timeInHours" => hours
            }
        end
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

        universe   = Multiverse::interactivelySelectUniverse()

        style      = TxFyres::interactivelyMakeNewFyreStyle()

        item = {
          "uuid"        => uuid,
          "mikuType"    => "TxFyre",
          "description" => description,
          "unixtime"    => unixtime,
          "datetime"    => datetime,
          "iam"         => iAmValue,
          "style"       => style
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

        style       = TxFyres::interactivelyMakeNewFyreStyle()

        item = {
          "uuid"        => uuid,
          "mikuType"    => "TxFyre",
          "description" => description,
          "unixtime"    => unixtime,
          "datetime"    => datetime,
          "iam"         => iAmValue,
          "style"       => style
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
        if item["style"]["style"] == "one-daily-impact" then
            return "(fyre) (once) #{item["description"]} (#{item["iam"][0]})"
        end
        if item["style"]["style"] == "daily-time-commitment" then
            return "(fyre) (#{"%4.2f" % rt}) #{item["description"]} (#{item["iam"][0]})"
        end
        raise "(error: 73e0676d-9893-4f2a-86e4-dc90420bd14f)"
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
            puts "style: #{item["style"]}".yellow
            puts "rt: #{BankExtended::stdRecoveredDailyTimeInHours(uuid)}".yellow

            TxAttachments::itemsForOwner(uuid).each{|attachment|
                indx = store.register(attachment, false)
                puts "[#{indx.to_s.ljust(3)}] #{TxAttachments::toString(attachment)}" 
            }

            puts "access | <datecode> | description | iam | style | attachment | show json | universe | transmute | destroy (gg) | exit (xx)".yellow

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
                Nx111::accessIamData_PossibleMutationInStorage_ExportsAreTx46Compatible(item)
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

            if Interpreting::match("style", command) then
                item["style"] = TxFyres::interactivelyMakeNewFyreStyle()
                Librarian6Objects::commit(item)
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
        announce = TxFyres::toStringForNS16(nx70, rt).gsub("(0.00)", "      ")
        {
            "uuid"     => uuid,
            "mikuType" => "NS16:TxFyre",
            "announce" => announce,
            "TxFyre"   => nx70,
            "rt"       => rt
        }
    end

    # TxFyres::section2(universe)
    def self.section2(universe)
        TxFyres::items()
            .select{|item| 
                objuniverse = ObjectUniverseMapping::getObjectUniverseMappingOrNull(item["uuid"])
                universe.nil? or objuniverse.nil? or (objuniverse == universe)
            }
            .map{|item| TxFyres::ns16(item) }
            .sort{|x1, x2| x1["rt"] <=> x2["rt"]}
    end

    # TxFyres::ns16s(universe)
    def self.ns16s(universe)
        styleFilter = lambda {|item|

            return item if NxBallsService::isRunning(item["uuid"])

            # return the item is the item is cleared to be shown in section3, otherwise return null
            if item["style"]["style"] == "one-daily-impact" then
                if Bank::valueAtDate(item["uuid"], Utils::today()) > 0 then
                    return nil
                else
                    return item
                end
            end
            if item["style"]["style"] == "daily-time-commitment" then
                rt = BankExtended::stdRecoveredDailyTimeInHours(item["uuid"])
                if rt < item["style"]["timeInHours"] then
                    return item
                else
                    return nil
                end
            end
        }

        TxFyres::items()
            .select{|item| 
                objuniverse = ObjectUniverseMapping::getObjectUniverseMappingOrNull(item["uuid"])
                universe.nil? or objuniverse.nil? or (objuniverse == universe)
            }
            .map{|item| styleFilter.call(item) }
            .compact
            .map{|item| TxFyres::ns16(item) }
            .select{|item| item["rt"] < 1}
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
