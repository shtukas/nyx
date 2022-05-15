# encoding: UTF-8

class TxTodos

    # TxTodos::items()
    def self.items()
        Librarian6ObjectsLocal::getObjectsByMikuType("TxTodo")
    end

    # TxTodos::itemsForUniverse(universe)
    def self.itemsForUniverse(universe)
        TxTodos::items()
            .select{|item| 
                objuniverse = ObjectUniverseMapping::getObjectUniverseMappingOrNull(item["uuid"])
                universe.nil? or objuniverse.nil? or (objuniverse == universe)
            }
    end

    # TxTodos::destroy(uuid)
    def self.destroy(uuid)
        Librarian6ObjectsLocal::destroy(uuid)
    end

    # --------------------------------------------------

    # TxTodos::itemsForNS16sMaintenance()
    def self.itemsForNS16sMaintenance()
        Multiverse::universes()
            .each{|universe|
                items = TxTodos::itemsForUniverse(universe).first(100)
                XCache::set("13016616-9244-443e-86b5-24bbaea2b5b1:#{universe}", JSON.generate(items))
            }
    end

    # TxTodos::itemsForNS16s(universe)
    def self.itemsForNS16s(universe)
        items = XCache::getOrNull("13016616-9244-443e-86b5-24bbaea2b5b1:#{universe}")
        if items.nil? then
            return []
        end
        JSON.parse(items)
            .map{|item| Librarian6ObjectsLocal::getObjectByUUIDOrNull(item["uuid"]) }
            .compact
    end

    # --------------------------------------------------
    # Ordinals

    # TxTodos::nextOrdinal(universe)
    def self.nextOrdinal(universe)
        biggest = ([0] + TxTodos::itemsForUniverse(universe).map{|nx50| nx50["ordinal"] }).max
        (biggest + 1).floor
    end

    # TxTodos::interactivelyDecideNewOrdinal(universe)
    def self.interactivelyDecideNewOrdinal(universe)
        action = LucilleCore::selectEntityFromListOfEntitiesOrNull("action", ["genesis injection (default)", "fine selection near the top", "next"])
        if action == "genesis injection (default)" or action.nil? then
            return TxTodos::getNewGenesisOrdinal(universe)
        end
        if action == "fine selection near the top" then
            TxTodos::itemsForUniverse(universe).first(50)
                .each{|nx50| 
                    puts "- #{TxTodos::toStringWithOrdinal(nx50)}"
                }
            return LucilleCore::askQuestionAnswerAsString("> ordinal ? : ").to_f
        end
        if action == "next" then
            return TxTodos::nextOrdinal(universe)
        end
        raise "5fe95417-192b-4256-a021-447ba02be4aa"
    end

    # TxTodos::getNewGenesisOrdinal(universe)
    def self.getNewGenesisOrdinal(universe)
        items = TxTodos::itemsForUniverse(universe)
        while items.any?{|item| !item["genesis"] } do
            items.shift
        end
        # items doesn't have new items
        if items.size == 0 then
            return 1
        end
        if items.size == 1 then
            return (item["ordinal"] + 1).floor
        end
        # items has at least two elements
        ( items[0]["ordinal"]+items[1]["ordinal"] ).to_f/2
    end

    # --------------------------------------------------
    # Makers

    # TxTodos::interactivelyCreateNewOrNull(description = nil)
    def self.interactivelyCreateNewOrNull(description = nil)
        if description.nil? or description == "" then
            description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
            return nil if description == ""
        else
            puts "description: #{description}"
        end

        nx111 = Nx111::interactivelyCreateNewIamValueOrNull(Nx111::iamTypesForManualMakingOfCatalystItems())
        return nil if nx111.nil?

        uuid       = SecureRandom.uuid
        unixtime   = Time.new.to_i
        datetime   = Time.new.utc.iso8601
        universe   = Multiverse::interactivelySelectUniverse()
        ordinal    = TxTodos::interactivelyDecideNewOrdinal(universe)

        item = {
          "uuid"        => uuid,
          "mikuType"    => "TxTodo",
          "description" => description,
          "unixtime"    => unixtime,
          "datetime"    => datetime,
          "iam"         => nx111,
          "ordinal"     => ordinal
        }
        Librarian6ObjectsLocal::commit(item)
        ObjectUniverseMapping::setObjectUniverseMapping(uuid, universe)
        item
    end

    # TxTodos::interactivelyIssueItemUsingInboxLocation2(location)
    def self.interactivelyIssueItemUsingInboxLocation2(location)
        uuid        = SecureRandom.uuid
        description = Inbox::interactivelyDecideBestDescriptionForLocation(location)
        unixtime    = Time.new.to_i
        datetime    = Time.new.utc.iso8601

        rootnhash   = AionCore::commitLocationReturnHash(InfinityElizabeth_XCacheAndInfinityBufferOut_ThenDriveLookupWithLocalXCaching.new(), location)
        nx111 = {
            "uuid"      => SecureRandom.uuid,
            "type"      => "aion-point",
            "rootnhash" => rootnhash
        }

        universe    = Multiverse::interactivelySelectUniverse()
        ordinal     = TxTodos::interactivelyDecideNewOrdinal(universe)

        item = {
          "uuid"        => uuid,
          "mikuType"    => "TxTodo",
          "description" => description,
          "unixtime"    => unixtime,
          "datetime"    => datetime,
          "iam"         => nx111,
          "ordinal"     => ordinal
        }
        Librarian6ObjectsLocal::commit(item)
        ObjectUniverseMapping::setObjectUniverseMapping(uuid, universe)
        item
    end

    # --------------------------------------------------
    # toString

    # TxTodos::toString(item)
    def self.toString(item)
        "(todo) #{item["description"]} (#{item["iam"]["type"]})"
    end

    # TxTodos::toStringWithOrdinal(item)
    def self.toStringWithOrdinal(item)
        "(todo) (ord: #{item["ordinal"]}) #{item["description"]} (#{item["iam"]["type"]})"
    end

    # TxTodos::toStringForNS16(item, rt)
    def self.toStringForNS16(item, rt)
        "(todo) (#{"%4.2f" % rt}) #{item["description"]} (#{item["iam"]["type"]})"
    end

    # TxTodos::toStringForNS19(item)
    def self.toStringForNS19(item)
        "(todo) #{item["description"]}"
    end

    # --------------------------------------------------
    # Operations

    # TxTodos::landing(item)
    def self.landing(item)

        loop {

            system("clear")

            Sx01Snapshots::printSnapshotDeploymentStatusIfRelevant()

            uuid = item["uuid"]

            store = ItemStore.new()

            puts "#{TxTodos::toString(item)}#{NxBallsService::activityStringOrEmptyString(" (", uuid, ")")}".green
            puts "uuid: #{uuid}".yellow
            puts "iam: #{item["iam"]}".yellow
            puts "universe: #{ObjectUniverseMapping::getObjectUniverseMappingOrNull(uuid)}".yellow
            puts "ordinal: #{item["ordinal"]}".yellow

            puts "DoNotDisplayUntil: #{DoNotShowUntil::getDateTimeOrNull(item["uuid"])}".yellow
            puts "rt: #{BankExtended::stdRecoveredDailyTimeInHours(uuid)}".yellow

            TxAttachments::itemsForOwner(uuid).each{|attachment|
                indx = store.register(attachment, false)
                puts "[#{indx.to_s.ljust(3)}] #{TxAttachments::toString(attachment)}" 
            }

            puts "access | start | <datecode> | description | iam | ordinal | rotate | transmute | attachment | universe | show json | >nyx | destroy (gg) | exit (xx)".yellow

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
                TxAttachments::interactivelyCreateNewOrNullForOwner(item["uuid"])
                next
            end

            if Interpreting::match("universe", command) then
                ObjectUniverseMapping::interactivelySetObjectUniverseMapping(item["uuid"])
                break
            end

            if Interpreting::match("ordinal", command) then
                universe = Multiverse::interactivelySelectUniverse()
                ordinal = TxTodos::interactivelyDecideNewOrdinal(universe)
                item["ordinal"] = ordinal
                Librarian6ObjectsLocal::commit(item)
                ObjectUniverseMapping::setObjectUniverseMapping(item["uuid"], universe)
                next
            end

            if Interpreting::match("rotate", command) then
                universe = Multiverse::interactivelySelectUniverse()
                ordinal = TxTodos::nextOrdinal(universe)
                item["ordinal"] = ordinal
                Librarian6ObjectsLocal::commit(item)
                ObjectUniverseMapping::setObjectUniverseMapping(item["uuid"], universe)
                break
            end

            if Interpreting::match("transmute", command) then
                Transmutation::transmutation2(item, "TxTodo")
                break
            end

            if Interpreting::match("show json", command) then
                puts JSON.pretty_generate(item)
                LucilleCore::pressEnterToContinue()
                break
            end

            if command == "destroy" or command == "gg" then
                if LucilleCore::askQuestionAnswerAsBoolean("destroy '#{TxTodos::toString(item)}' ? ", true) then
                    NxBallsService::close(item["uuid"], true)
                    TxTodos::destroy(item["uuid"])
                    break
                end
                next
            end

            if command == ">nyx" then
                i2 = Transmutation::interactivelyNx50ToNyx(item)
                LxAction::action("landing", i2)
                break
            end
        }
    end

    # TxTodos::rstream()
    def self.rstream()
        TxTodos::itemsForUniverse("backlog").shuffle.each{|item|
            puts item["description"].green
            LxAction::action("start", item)
            LxAction::action("access", item)
            loop {
                command = LucilleCore::askQuestionAnswerAsString("next (default), done, landing (and back), exit, run (and exit rstream): ")
                if command == "" then
                    LxAction::action("stop", item)
                    break
                end
                if command == "next" then
                    LxAction::action("stop", item)
                    break
                end
                if command == "done" then
                    LxAction::action("stop", item)
                    TxTodos::destroy(item["uuid"])
                    break
                end
                if command == "landing" then
                    LxAction::action("landing", item)
                    item = Librarian6ObjectsLocal::getObjectByUUIDOrNull(item["uuid"])
                    if item["mikuType"] != "TxTodo" then
                        break
                    end
                    next
                end
                if command == "exit" then
                    LxAction::action("stop", item)
                    return
                end
                if command == "run" then
                    return
                end
            }
        }
    end

    # --------------------------------------------------
    # nx16s

    # TxTodos::ns16(nx50)
    def self.ns16(nx50)
        uuid = nx50["uuid"]
        rt = BankExtended::stdRecoveredDailyTimeInHours(uuid)
        {
            "uuid"     => uuid,
            "mikuType" => "NS16:TxTodo",
            "announce" => TxTodos::toStringForNS16(nx50, rt).gsub("(0.00)", "      "),
            "height"   => Heights::height1("beca7cc9", uuid),
            "ordinal"  => nx50["ordinal"],
            "TxTodo"   => nx50,
            "rt"       => rt
        }
    end

    # TxTodos::section2(universe)
    def self.section2(universe)
        TxTodos::itemsForNS16s(universe)
            .sort{|i1, i2| i1["ordinal"] <=> i2["ordinal"] }
            .map{|item| TxTodos::ns16(item) }
            .select{|item| DoNotShowUntil::isVisible(item["uuid"]) }
            .select{|ns16| InternetStatus::ns16ShouldShow(ns16["uuid"]) }
            .select{|item| item["rt"] > 1 }
    end

    # TxTodos::section3(universe)
    def self.section3(universe)
        ns16s = TxTodos::itemsForNS16s(universe)
                    .sort{|i1, i2| i1["ordinal"] <=> i2["ordinal"] }
                    .map{|item| TxTodos::ns16(item) }
                    .select{|item| DoNotShowUntil::isVisible(item["uuid"]) }
                    .select{|ns16| InternetStatus::ns16ShouldShow(ns16["uuid"]) }
                    .select{|item| item["rt"] < 1 or NxBallsService::isRunning(item["uuid"]) }

        Heights::markSequenceOfNS16sWithDecreasingHeights("beca7cc9", ns16s)
    end

    # --------------------------------------------------

    # TxTodos::nx20s()
    def self.nx20s()
        Librarian6ObjectsLocal::getObjectsByMikuType("TxTodo")
            .map{|item|
                {
                    "announce" => TxTodos::toStringForNS19(item),
                    "unixtime" => item["unixtime"],
                    "payload"  => item
                }
            }
    end
end

Thread.new {
    sleep 60 # 1 min
    loop {
        TxTodos::itemsForNS16sMaintenance()
        sleep 600 # 10 mins
    }
}
