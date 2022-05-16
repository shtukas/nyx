j# encoding: UTF-8

class TxFyres

    # TxFyres::items()
    def self.items()
        Librarian6ObjectsLocal::getObjectsByMikuType("TxFyre")
    end

    # TxFyres::itemsForUniverse(universe)
    def self.itemsForUniverse(universe)
        TxFyres::items()
            .select{|item| 
                objuniverse = ObjectUniverseMapping::getObjectUniverseMappingOrNull(item["uuid"])
                universe.nil? or objuniverse.nil? or (objuniverse == universe)
            }
    end

    # TxFyres::destroy(uuid)
    def self.destroy(uuid)
        Librarian6ObjectsLocal::destroy(uuid)
    end

    # --------------------------------------------------
    # Makers

    # TxFyres::interactivelyCreateNewOrNull()
    def self.interactivelyCreateNewOrNull()
        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return nil if description == ""

        nx111 = Nx111::interactivelyCreateNewIamValueOrNull(Nx111::iamTypesForManualMakingOfCatalystItems())
        return nil if nx111.nil?

        uuid       = SecureRandom.uuid
        unixtime   = Time.new.to_i
        datetime   = Time.new.utc.iso8601

        universe   = Multiverse::interactivelySelectUniverse()

        item = {
          "uuid"        => uuid,
          "mikuType"    => "TxFyre",
          "description" => description,
          "unixtime"    => unixtime,
          "datetime"    => datetime,
          "iam"        => nx111
        }
        Librarian6ObjectsLocal::commit(item)
        ObjectUniverseMapping::setObjectUniverseMapping(uuid, universe)
        item
    end

    # --------------------------------------------------
    # toString

    # TxFyres::toString(item)
    def self.toString(item)
        "(fyre) #{item["description"]} (#{item["iam"]["type"]})"
    end

    # TxFyres::toStringForNS16(item, rt)
    def self.toStringForNS16(item, rt)
        "(fyre) (#{"%4.2f" % rt}) #{item["description"]} (#{item["iam"]["type"]}) (#{"%4.2f" % rt} of 1 hour)"
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

            Sx01Snapshots::printSnapshotDeploymentStatusIfRelevant()

            uuid = item["uuid"]

            store = ItemStore.new()

            puts TxFyres::toString(item).green
            puts "uuid: #{uuid}".yellow
            puts "iam: #{item["iam"]}".yellow
            puts "rt: #{BankExtended::stdRecoveredDailyTimeInHours(uuid)}".yellow

            TxAttachments::itemsForOwner(uuid).each{|attachment|
                indx = store.register(attachment, false)
                puts "[#{indx.to_s.ljust(3)}] #{TxAttachments::toString(attachment)}" 
            }

            puts "access | start | <datecode> | description | iam | attachment | show json | universe | transmute | >nyx | destroy (gg) | exit (xx)".yellow

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
                EditionDesk::exportItemToDeskIfNotAlreadyExportedAndAccess(item)
                next
            end

            if Interpreting::match("start", command) then
                if !NxBallsService::isRunning(item["uuid"]) then
                    NxBallsService::issue(item["uuid"], item["description"], [item["uuid"]])
                end
                next
            end

            if Interpreting::match("description", command) then
                description = Utils::editTextSynchronously(item["description"]).strip
                next if description == ""
                item["description"] = description
                Librarian6ObjectsLocal::commit(item)
                next
            end

            if Interpreting::match("iam", command) then
                nx111 = Nx111::interactivelyCreateNewIamValueOrNull(Nx111::iamTypesForManualMakingOfCatalystItems())
                next if nx111.nil?
                puts JSON.pretty_generate(nx111)
                if LucilleCore::askQuestionAnswerAsBoolean("confirm change ? ") then
                    item["iam"] = nx111
                    Librarian6ObjectsLocal::commit(item)
                end
            end

            if Interpreting::match("attachment", command) then
                ox = TxAttachments::interactivelyIssueNewOrNullForOwner(item["uuid"])
                puts JSON.pretty_generate(ox)
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

            if Interpreting::match(">nyx", command) then
                ix = {
                    "uuid"        => SecureRandom.uuid,
                    "mikuType"    => "Nx100",
                    "unixtime"    => item["unixtime"],
                    "datetime"    => item["datetime"],
                    "description" => item["description"],
                    "iam"        => item["iam"],
                    "flavour"     => Nx102Flavor::interactivelyCreateNewFlavour()
                }
                Librarian6ObjectsLocal::commit(ix)
                LxAction::action("landing", ix)

                TxFyres::complete(item)
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

    # TxFyres::dive()
    def self.dive()
        loop {
            system("clear")
            items = TxFyres::items().sort{|i1, i2| i1["datetime"] <=> i2["datetime"] }
            item = LucilleCore::selectEntityFromListOfEntitiesOrNull("fyre", items, lambda{|item| TxFyres::toString(item) })
            break if item.nil?
            TxFyres::landing(item)
        }
    end

    # --------------------------------------------------
    # nx16s

    # TxFyres::section3Filter(item)
    def self.section3Filter(item)
        return false if XCache::flagIsTrue("905b-09a30622d2b9:FyreIsDoneForToday:#{item["uuid"]}")
        BankExtended::stdRecoveredDailyTimeInHours(item["uuid"]) < 1 or NxBallsService::isRunning(item["uuid"])
    end

    # TxFyres::section2(universe)
    def self.section2(universe)
        TxFyres::itemsForUniverse(universe)
            .map{|item|
                uuid = item["uuid"]
                rt = BankExtended::stdRecoveredDailyTimeInHours(uuid)
                announce = TxFyres::toStringForNS16(item, rt).gsub("(0.00)", "      ")
                {
                    "uuid"     => uuid,
                    "mikuType" => "NS16:TxFyre",
                    "announce" => announce,
                    "TxFyre"   => item,
                    "rt"       => rt,
                    "unixtime" => item["unixtime"]
                }
            }
    end

    # TxFyres::section3(universe)
    def self.section3(universe)
        TxFyres::itemsForUniverse(universe)
            .select{|item| TxFyres::section3Filter(item) }
            .map{|item| 
                uuid = item["uuid"]
                rt = BankExtended::stdRecoveredDailyTimeInHours(uuid)
                announce = TxFyres::toStringForNS16(item, rt).gsub("(0.00)", "      ")
                {
                    "uuid"     => uuid,
                    "mikuType" => "NS16:TxFyre",
                    "announce" => announce,
                    "TxFyre"   => item,
                    "rt"       => rt
                }
            }
            .sort{|i1, i2| i1["rt"] <=> i2["rt"] }
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
