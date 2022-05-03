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

    # TxTodos::ordinalBetweenN1thAndN2th(universe, n1, n2)
    def self.ordinalBetweenN1thAndN2th(universe, n1, n2)
        nx50s = TxTodos::itemsForUniverse(universe).first(n2)
        if nx50s.size < n1+2 then
            return TxTodos::nextOrdinal(universe)
        end
        ordinals = nx50s.map{|nx50| nx50["ordinal"] }.sort.drop(n1).take(n2-n1)
        ordinals.min + rand*(ordinals.max-ordinals.min)
    end

    # TxTodos::interactivelyDecideNewOrdinal(universe)
    def self.interactivelyDecideNewOrdinal(universe)
        action = LucilleCore::selectEntityFromListOfEntitiesOrNull("action", ["fine selection near the top", "random within [10-20] (default)", "next"])
        if action == "fine selection near the top" then
            TxTodos::itemsForUniverse(universe).first(50)
                .each{|nx50| 
                    puts "- #{TxTodos::toStringWithOrdinal(nx50)}"
                }
            return LucilleCore::askQuestionAnswerAsString("> ordinal ? : ").to_f
        end
        if action == "random within [10-20] (default)" or action.nil? then
            return TxTodos::ordinalBetweenN1thAndN2th(universe, 10, 20)
        end
        if action == "next" then
            return TxTodos::nextOrdinal(universe)
        end
        raise "5fe95417-192b-4256-a021-447ba02be4aa"
    end

    # --------------------------------------------------
    # Makers

    # TxTodos::interactivelyCreateNewOrNull()
    def self.interactivelyCreateNewOrNull()
        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return nil if description == ""

        iAmValue = Nx111::interactivelyCreateNewIamValueOrNull(Nx111::iamTypesForManualMakingOfCatalystItems())
        return nil if iAmValue.nil?

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
          "iam"         => iAmValue,
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

        rootnhash   = AionCore::commitLocationReturnHash(InfinityElizabeth_DriveWithLocalXCache.new(), location)
        iAmValue    = ["aion-point", rootnhash]

        universe    = Multiverse::interactivelySelectUniverse()
        ordinal     = TxTodos::interactivelyDecideNewOrdinal(universe)

        item = {
          "uuid"        => uuid,
          "mikuType"    => "TxTodo",
          "description" => description,
          "unixtime"    => unixtime,
          "datetime"    => datetime,
          "iam"         => iAmValue,
          "ordinal"     => ordinal
        }
        Librarian6ObjectsLocal::commit(item)
        ObjectUniverseMapping::setObjectUniverseMapping(uuid, universe)
        item
    end

    # TxTodos::issueViennaURL(url)
    def self.issueViennaURL(url)
        uuid        = SecureRandom.uuid
        description = url
        unixtime    = Time.new.to_i
        datetime    = Time.new.utc.iso8601

        ordinal     = TxTodos::ordinalBetweenN1thAndN2th("backlog", 20, 30)

        item = {
          "uuid"        => uuid,
          "mikuType"    => "TxTodo",
          "description" => description,
          "unixtime"    => unixtime,
          "datetime"    => datetime,
          "iam"         => ["url", url],
          "ordinal"     => ordinal
        }
        Librarian6ObjectsLocal::commit(item)
        ObjectUniverseMapping::setObjectUniverseMapping(uuid, "backlog")
        item
    end

    # --------------------------------------------------
    # toString

    # TxTodos::toString(item)
    def self.toString(item)
        "(todo) #{item["description"]} (#{item["iam"][0]})"
    end

    # TxTodos::toStringWithOrdinal(item)
    def self.toStringWithOrdinal(item)
        "(todo) (ord: #{item["ordinal"]}) #{item["description"]} (#{item["iam"][0]})"
    end

    # TxTodos::toStringForNS16(item, rt)
    def self.toStringForNS16(item, rt)
        "(todo) (#{"%4.2f" % rt}) #{item["description"]} (#{item["iam"][0]})"
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

            uuid = item["uuid"]

            store = ItemStore.new()

            puts "#{TxTodos::toString(item)}#{NxBallsService::runningStringOrEmptyString(" (", uuid, ")")}".green
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
                Nx111::accessIamData_PossibleMutationInStorage_ExportsAreTx46Compatible(item)
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
                iAmValue = Nx111::interactivelyCreateNewIamValueOrNull(Nx111::iamTypesForManualMakingOfCatalystItems())
                next if iAmValue.nil?
                puts JSON.pretty_generate(iAmValue)
                if LucilleCore::askQuestionAnswerAsBoolean("confirm change ? ") then
                    item["iam"] = iAmValue
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

    # TxTodos::ns16s(universe)
    def self.ns16s(universe)
        ns16s = TxTodos::itemsForNS16s(universe)
            .select{|item| 
                objuniverse = ObjectUniverseMapping::getObjectUniverseMappingOrNull(item["uuid"])
                universe.nil? or objuniverse.nil? or (objuniverse == universe)
            }
            .sort{|i1, i2| i1["ordinal"] <=> i2["ordinal"] }
            .map{|item| TxTodos::ns16(item) }
            .select{|item| DoNotShowUntil::isVisible(item["uuid"]) }
            .select{|ns16| InternetStatus::ns16ShouldShow(ns16["uuid"]) }

        ns16s1 = ns16s.take(5)
        ns16s2 = ns16s.drop(5)

        ns16s1 = ns16s1
            .select{|item| item["rt"] < 1 or NxBallsService::isRunning(item["uuid"]) }

        ns16s1 + ns16s2
    end

    # --------------------------------------------------

    # TxTodos::nx20s()
    def self.nx20s()
        Librarian6ObjectsLocal::getObjectsByMikuType("TxTodo").map{|item|
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
