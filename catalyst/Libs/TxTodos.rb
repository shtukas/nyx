# encoding: UTF-8

class TxTodos

    # TxTodos::items()
    def self.items()
        LocalObjectsStore::getObjectsByMikuType("TxTodo")
    end

    # TxTodos::itemsForUniverse(universe)
    def self.itemsForUniverse(universe)
        LocalObjectsStore::getObjectsByMikuTypeAndUniverse("TxTodo", universe)
    end

    # TxTodos::destroy(uuid)
    def self.destroy(uuid)
        LocalObjectsStore::logicaldelete(uuid)
    end

    # --------------------------------------------------

    # TxTodos::itemsForNS16s(universe)
    def self.itemsForNS16s(universe)
        LocalObjectsStore::getObjectsByMikuTypeAndUniverseByOrdinalLimit("TxTodo", universe, 100)
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
          "ordinal"     => ordinal,
          "universe"    => universe
        }
        LocalObjectsStore::commit(item)
        item
    end

    # TxTodos::issuePile(location)
    def self.issuePile(location)
        uuid        = SecureRandom.uuid
        description = File.basename(location)
        unixtime    = Time.new.to_i
        datetime    = Time.new.utc.iso8601

        rootnhash   = AionCore::commitLocationReturnHash(EnergyGridElizabeth.new(), location)
        nx111 = {
            "uuid"      => SecureRandom.uuid,
            "type"      => "aion-point",
            "rootnhash" => rootnhash
        }

        universe    = "backlog"
        ordinal     = TxTodos::getNewGenesisOrdinal(universe)

        item = {
          "uuid"        => uuid,
          "mikuType"    => "TxTodo",
          "description" => description,
          "unixtime"    => unixtime,
          "datetime"    => datetime,
          "iam"         => nx111,
          "ordinal"     => ordinal,
          "universe"    => universe
        }
        LocalObjectsStore::commit(item)
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
        "(todo) #{item["description"]} (#{item["iam"]["type"]})"
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

            puts "#{TxTodos::toString(item)}#{NxBallsService::activityStringOrEmptyString(" (", uuid, ")")}".green
            puts "uuid: #{uuid}".yellow
            puts "iam: #{item["iam"]}".yellow
            puts "universe: #{item["universe"]}".yellow
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

            if (unixtime = DidactUtils::codeToUnixtimeOrNull(command.gsub(" ", ""))) then
                DoNotShowUntil::setUnixtime(uuid, unixtime)
                break
            end

            if Interpreting::match("access", command) then
                EditionDesk::accessItem(item)
                next
            end

            if Interpreting::match("start", command) then
                if !NxBallsService::isRunning(item["uuid"]) then
                    NxBallsService::issue(item["uuid"], item["description"], [item["uuid"]])
                end
                next
            end

            if Interpreting::match("description", command) then
                description = DidactUtils::editTextSynchronously(item["description"]).strip
                next if description == ""
                item["description"] = description
                LocalObjectsStore::commit(item)
                next
            end

            if Interpreting::match("iam", command) then
                nx111 = Nx111::interactivelyCreateNewIamValueOrNull(Nx111::iamTypesForManualMakingOfCatalystItems())
                next if nx111.nil?
                puts JSON.pretty_generate(nx111)
                if LucilleCore::askQuestionAnswerAsBoolean("confirm change ? ") then
                    item["iam"] = nx111
                    LocalObjectsStore::commit(item)
                end
            end

            if Interpreting::match("attachment", command) then
                ox = TxAttachments::interactivelyIssueNewOrNullForOwner(item["uuid"])
                puts JSON.pretty_generate(ox)
                next
            end

            if Interpreting::match("universe", command) then
                item["universe"] = Multiverse::interactivelySelectUniverse()
                LocalObjectsStore::commit(item)
                break
            end

            if Interpreting::match("ordinal", command) then
                universe = Multiverse::interactivelySelectUniverse()
                ordinal = TxTodos::interactivelyDecideNewOrdinal(universe)
                item["ordinal"] = ordinal
                item["universe"] = Multiverse::interactivelySelectUniverse()
                LocalObjectsStore::commit(item)
                next
            end

            if Interpreting::match("rotate", command) then
                universe = Multiverse::interactivelySelectUniverse()
                ordinal = TxTodos::nextOrdinal(universe)
                item["ordinal"] = ordinal
                item["universe"] = Multiverse::interactivelySelectUniverse()
                LocalObjectsStore::commit(item)
                break
            end

            if Interpreting::match("transmute", command) then
                Transmutation::transmutation2(item, "TxTodo")
                break
            end

            if Interpreting::match("show json", command) then
                puts JSON.pretty_generate(item)
                LucilleCore::pressEnterToContinue()
                next
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
        items = TxTodos::itemsForUniverse("backlog").first(2000)

        # -----------------------------------------------------------------
        # Some gratuituous optimization
        # (comment group: 3e6f8340-1d1e-400d-8209-5cec545c0e80)
        if InfinityDriveUtils::driveIsPlugged() then
            items.each {|item|
                next if XCache::flagIsTrue("605ef9cb-9586-4537-97e9-f25daed3bca2:#{JSON.generate(item)}")
                puts "Caching: #{item["description"]}"
                if item["iam"]["type"] == "aion-point" then
                    # We do this to essentially download the blob from infinity to local cache
                    LibrarianObjectsFileSystemCheck2::fsckExitAtFirstFailureLibrarianMikuObject(item, EnergyGridElizabeth.new())
                end
                if item["iam"]["type"] == "Dx8Unit" then
                    unitId = item["iam"]["unitId"]
                    location = Dx8UnitsUtils::dx8UnitFolder(unitId)
                    rootnhash = AionCore::commitLocationReturnHash(EnergyGridElizabeth.new(), location)
                    XCache::set("dbe424a9-a360-4f66-9ad1-d16b2475c069:#{unitId}", rootnhash)
                end
                XCache::setFlagTrue("605ef9cb-9586-4537-97e9-f25daed3bca2:#{JSON.generate(item)}")
            }
        end
        # -----------------------------------------------------------------

        items
            .first(1000)
            .shuffle
            .each{|item|
                puts item["description"].green
                LxAction::action("start", item)
                LxAction::action("access", item)
                startTime = Time.new.to_i
                loop {
                    break if ( Time.new.to_i - startTime ) > 3600 # We run for an entire hour
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
                        item = LocalObjectsStore::getObjectByUUIDOrNull(item["uuid"])
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
            "announce" => TxTodos::toStringForNS16(nx50, rt),
            "ordinal"  => nx50["ordinal"],
            "TxTodo"   => nx50,
            "rt"       => rt
        }
    end

    # TxTodos::ns16s(universe)
    def self.ns16s(universe)
        TxTodos::itemsForNS16s(universe)
            .map{|item| TxTodos::ns16(item) }
            .select{|ns16| DoNotShowUntil::isVisible(ns16["uuid"]) }
            .select{|ns16| InternetStatus::ns16ShouldShow(ns16["uuid"]) }
    end

    # --------------------------------------------------

    # TxTodos::nx20s()
    def self.nx20s()
        LocalObjectsStore::getObjectsByMikuType("TxTodo")
            .map{|item|
                {
                    "announce" => TxTodos::toStringForNS19(item),
                    "unixtime" => item["unixtime"],
                    "payload"  => item
                }
            }
    end
end
