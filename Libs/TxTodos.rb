# encoding: UTF-8

class RStreamProgressMonitor
    def initialize()
        @data = JSON.parse(XCache::getOrDefaultValue("18705e17-41a7-4c7b-986b-a6a9292e8bb4", "[]"))
    end
    def anotherOne()
        @data << Time.new.to_i
        XCache::set("18705e17-41a7-4c7b-986b-a6a9292e8bb4", JSON.generate(@data))
    end
    def getCount()
        @data.size
    end
end

$RStreamProgressMonitor = RStreamProgressMonitor.new()

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
    # Ordinals

    # TxTodos::nextOrdinal(universe)
    def self.nextOrdinal(universe)
        biggest = ([0] + TxTodos::itemsForUniverse(universe).map{|nx50| nx50["ordinal"] }).max
        (biggest + 1).floor
    end

    # TxTodos::interactivelyDecideNewOrdinal(universe)
    def self.interactivelyDecideNewOrdinal(universe)
        action = LucilleCore::selectEntityFromListOfEntitiesOrNull("action", ["fine selection in the top 10", "next"])
        if action == "fine selection in the top 10" then
            TxTodos::itemsForUniverse(universe).first(10)
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

    # --------------------------------------------------
    # toString

    # TxTodos::toString(item)
    def self.toString(item)
        "(todo) #{item["description"]} (#{I1as::toStringShort(item["i1as"])}) (#{item["universe"]})"
    end

    # TxTodos::toStringWithOrdinal(item)
    def self.toStringWithOrdinal(item)
        "(todo) (ord: #{item["ordinal"]}) #{item["description"]} (#{I1as::toStringShort(item["i1as"])})"
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

            puts "i1as:"
            item["i1as"].each{|nx111|
                puts "    #{Nx111::toString(nx111)}"
            } 

            puts "universe: #{item["universe"]}".yellow
            puts "ordinal: #{item["ordinal"]}".yellow

            puts "DoNotDisplayUntil: #{DoNotShowUntil::getDateTimeOrNull(item["uuid"])}".yellow
            puts "rt: #{BankExtended::stdRecoveredDailyTimeInHours(uuid)}".yellow

            notes = Ax1Text::itemsForOwner(uuid)
            if notes.size > 0 then
                puts "notes:"
                notes.each{|note|
                    indx = store.register(note, false)
                    puts "    [#{indx.to_s.ljust(3)}] #{Ax1Text::toString(note)}" 
                }
            end

            puts "access | start | <datecode> | description | iam | ordinal | rotate | transmute | note | universe | show json | >nyx | destroy".yellow

            command = LucilleCore::askQuestionAnswerAsString("> ")

            break if command == ""

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
                    NxBallsService::issue(item["uuid"], item["description"], [item["uuid"], item["universe"]])
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

            if command == "destroy" then
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
        uuid = "1ee2805a-f8ee-4a73-a92a-c76d9d45359a" # uuid of the TxTodos::rstreamToken()

        if !NxBallsService::isRunning(uuid) then
            NxBallsService::issue(uuid, "(rstream)" , [uuid]) # rstream itself doesn't publish time to bank accounts.
        end

        runItem = lambda {|item| # return should_stop_rstream
            LxAction::action("start", item)
            LxAction::action("access", item)
            returnvalue = nil
            loop {
                command = LucilleCore::askQuestionAnswerAsString("(> #{item["description"].green}) done, detach (running), (keep and) next, replace, universe, >nyx: ")
                next if command.nil?
                if command == "done" then
                    LxAction::action("stop", item)
                    TxTodos::destroy(item["uuid"])
                    $RStreamProgressMonitor.anotherOne()
                    return false
                end
                if command == "detach" then
                    # We need to ensure that this thing has a low enough ordinal to be able to show up in the regular listing
                    item["ordinal"] = 0
                    Librarian::commit(item)
                    return true
                end
                if command == "next" then
                    LxAction::action("stop", item)
                    return false
                end
                if command == "replace" then
                    TxTodos::interactivelyCreateNewOrNull()
                    LxAction::action("stop", item)
                    TxTodos::destroy(item["uuid"])
                    return false
                end
                if command == "universe" then
                    item["universe"] = Multiverse::interactivelySelectUniverse()
                    Librarian::commit(item)
                    LxAction::action("stop", item)
                    return false
                end
                if command == ">nyx" then
                    LxAction::action("stop", item)
                    item["mikuType"] = "Nx100"
                    item["flavour"] = Nx102Flavor::interactivelyCreateNewFlavour()
                    Librarian::commit(item)
                    Nx100s::landing(item)
                    $RStreamProgressMonitor.anotherOne()
                    return false
                end
            }
        }

        processItem = lambda {|item| # return should_stop_rstream
            loop {
                command = LucilleCore::askQuestionAnswerAsString("(> #{item["description"].green}) run (start and access, default), landing (and back), done, universe, next, exit (rstream): ")
                if command == "" or command == "run" then
                    return runItem.call(item) # should_stop_rstream
                end
                if command == "landing" then
                    LxAction::action("landing", item)
                    item = Librarian::getObjectByUUIDOrNull(item["uuid"])
                    if item.nil? then
                        return false
                    end
                    if item["mikuType"] != "TxTodo" then
                        return false
                    end
                    # Otherwise we restart the loop
                end
                if command == "done" then
                    TxTodos::destroy(item["uuid"])
                    $RStreamProgressMonitor.anotherOne()
                    return false
                end
                if command == "universe" then
                    item["universe"] = Multiverse::interactivelySelectUniverse()
                    Librarian::commit(item)
                    return false
                end
                if command == "next" then
                    return false
                end
                if command == "exit" then
                    return true
                end
            }
        }

        (lambda{
            TxTodos::itemsForUniverse("standard")
                .first(1000)
                .shuffle
                .take(20)
                .each{|item|
                    should_stop_rstream = processItem.call(item)
                    if should_stop_rstream then
                        return
                    end
                }
        }).call()
        
        NxBallsService::close(uuid, true)
    end

    # --------------------------------------------------
    # nx16s

    # TxTodos::ns16(item)
    def self.ns16(item)
        uuid = item["uuid"]
        rt = BankExtended::stdRecoveredDailyTimeInHours(uuid)
        {
            "uuid"     => uuid,
            "mikuType" => "NS16:TxTodo",
            "universe" => item["universe"],
            "announce" => TxTodos::toString(item),
            "ordinal"  => item["ordinal"],
            "TxTodo"   => item,
            "rt"       => rt
        }
    end

    # TxTodos::rstreamToken()
    def self.rstreamToken()
        uuid = "1ee2805a-f8ee-4a73-a92a-c76d9d45359a" # uuid also used in TxTodos
        {
            "uuid"     => uuid,
            "mikuType" => "ADE4F121",
            "announce" => "(rstream) (#{$RStreamProgressMonitor.getCount()} last 7 days) (rt: #{BankExtended::stdRecoveredDailyTimeInHours(uuid).round(2)})",
            "lambda"   => lambda { TxTodos::rstream() },
            "rt"       => BankExtended::stdRecoveredDailyTimeInHours(uuid)
        }
    end

    # TxTodos::ns16s(universe)
    def self.ns16s(universe)
        Librarian::getObjectsByMikuTypeAndPossiblyNullUniverseLimit("TxTodo", universe, 100)
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
