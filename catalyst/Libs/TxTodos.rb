# encoding: UTF-8

class TxTodos

    # TxTodos::items()
    def self.items()
        Librarian::getObjectsByMikuType("TxTodo")
    end

    # TxTodos::itemsForUniverse(universe)
    def self.itemsForUniverse(universe)
        Librarian::getObjectsByMikuTypeAndUniverse("TxTodo", universe)
    end

    # TxTodos::destroy(uuid)
    def self.destroy(uuid)
        Librarian::destroy(uuid)
    end

    # --------------------------------------------------

    # TxTodos::itemsForNS16s(universe)
    def self.itemsForNS16s(universe)
        Librarian::getObjectsByMikuTypeAndUniverseByOrdinalLimit("TxTodo", universe, 100)
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

        uuid = SecureRandom.uuid

        nx111 = Nx111::interactivelyCreateNewIamValueOrNull(Nx111::iamTypesForManualMakingOfCatalystItems(), uuid)
        return nil if nx111.nil?

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
          "i1as"        => [nx111],
          "ordinal"     => ordinal,
          "universe"    => universe
        }
        Librarian::commit(item)
        item
    end

    # TxTodos::issuePile(location)
    def self.issuePile(location)
        uuid        = SecureRandom.uuid
        description = File.basename(location)
        unixtime    = Time.new.to_i
        datetime    = Time.new.utc.iso8601

        rootnhash   = AionCore::commitLocationReturnHash(Fx12sElizabethV2.new(uuid), location)
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
          "i1as"        => [nx111],
          "ordinal"     => ordinal,
          "universe"    => universe
        }
        Librarian::commit(item)
        item
    end

    # --------------------------------------------------
    # toString

    # TxTodos::toString(item)
    def self.toString(item)
        "(todo) #{item["description"]} (#{I1as::toStringShort(item["i1as"])})"
    end

    # TxTodos::toStringWithOrdinal(item)
    def self.toStringWithOrdinal(item)
        "(todo) (ord: #{item["ordinal"]}) #{item["description"]} (#{I1as::toStringShort(item["i1as"])})"
    end

    # TxTodos::toStringForNS16(item, rt)
    def self.toStringForNS16(item, rt)
        "(todo) #{item["description"]} (#{I1as::toStringShort(item["i1as"])})"
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
            puts "i1as: #{item["i1as"]}".yellow
            puts "universe: #{item["universe"]}".yellow
            puts "ordinal: #{item["ordinal"]}".yellow

            puts "DoNotDisplayUntil: #{DoNotShowUntil::getDateTimeOrNull(item["uuid"])}".yellow
            puts "rt: #{BankExtended::stdRecoveredDailyTimeInHours(uuid)}".yellow

            Ax1Text::itemsForOwner(uuid).each{|note|
                indx = store.register(note, false)
                puts "[#{indx.to_s.ljust(3)}] #{Ax1Text::toString(note)}" 
            }

            puts "access | start | <datecode> | description | iam | ordinal | rotate | transmute | note | universe | show json | >nyx | destroy (gg) | exit (xx)".yellow

            command = LucilleCore::askQuestionAnswerAsString("> ")

            break if command == "exit"
            break if command == "xx"

            if (indx = Interpreting::readAsIntegerOrNull(command)) then
                entity = store.get(indx)
                next if entity.nil?
                LxAction::action("landing", entity)
            end

            if (unixtime = CommonUtils::codeToUnixtimeOrNull(command.gsub(" ", ""))) then
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
                description = CommonUtils::editTextSynchronously(item["description"]).strip
                next if description == ""
                item["description"] = description
                Librarian::commit(item)
                next
            end

            if Interpreting::match("iam", command) then
                item = I1as::manageI1as(item, item["i1as"])
            end

            if Interpreting::match("note", command) then
                ox = Ax1Text::interactivelyIssueNewOrNullForOwner(item["uuid"])
                puts JSON.pretty_generate(ox)
                next
            end

            if Interpreting::match("universe", command) then
                item["universe"] = Multiverse::interactivelySelectUniverse()
                Librarian::commit(item)
                break
            end

            if Interpreting::match("ordinal", command) then
                universe = Multiverse::interactivelySelectUniverse()
                ordinal = TxTodos::interactivelyDecideNewOrdinal(universe)
                item["ordinal"] = ordinal
                item["universe"] = Multiverse::interactivelySelectUniverse()
                Librarian::commit(item)
                next
            end

            if Interpreting::match("rotate", command) then
                universe = Multiverse::interactivelySelectUniverse()
                ordinal = TxTodos::nextOrdinal(universe)
                item["ordinal"] = ordinal
                item["universe"] = Multiverse::interactivelySelectUniverse()
                Librarian::commit(item)
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
        startTime = Time.new.to_i
        TxTodos::itemsForUniverse("backlog")
            .first(1000)
            .shuffle
            .each{|item|
                break if ( Time.new.to_i - startTime ) > 3600 # We run for an entire hour
                loop {
                    command = LucilleCore::askQuestionAnswerAsString("(> #{item["description"].green}) run (start and access, default), landing (and back), next, exit (rstream): ")
                    if command == "" or command == "run" then
                        LxAction::action("start", item)
                        LxAction::action("access", item)
                        command = LucilleCore::askQuestionAnswerAsString("(> #{item["description"].green}) done (default), detach, stop: ")
                        if command == "" or command == "done" then
                            LxAction::action("stop", item)
                            TxTodos::destroy(item["uuid"])
                            break
                        end
                        if command == "detach" then
                            return
                        end
                        if command == "stop" then
                            LxAction::action("stop", item)
                            break
                        end
                    end
                    if command == "landing" then
                        LxAction::action("landing", item)
                        item = Librarian::getObjectByUUIDOrNull(item["uuid"])
                        if iten.nil? then
                            break
                        end
                        if item["mikuType"] != "TxTodo" then
                            break
                        end
                        # Otherwise we restart the loop
                    end
                    if command == "next" then
                        break
                    end
                    if command == "exit" then
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
        Librarian::getObjectsByMikuType("TxTodo")
            .map{|item|
                {
                    "announce" => TxTodos::toStringForNS19(item),
                    "unixtime" => item["unixtime"],
                    "payload"  => item
                }
            }
    end
end
