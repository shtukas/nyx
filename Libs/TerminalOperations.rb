# encoding: UTF-8

class TerminalUtils

    # TerminalUtils::removeDuplicatesOnAttribute(array, attribute)
    def self.removeDuplicatesOnAttribute(array, attribute)
        array.reduce([]){|selected, element|
            if selected.none?{|x| x[attribute] == element[attribute] } then
                selected + [element]
            else
                selected
            end
        }
    end

    # TerminalUtils::removeRedundanciesInSecondArrayRelativelyToFirstArray(array1, array2)
    def self.removeRedundanciesInSecondArrayRelativelyToFirstArray(array1, array2)
        uuids1 = array1.map{|ns16| ns16["uuid"] }
        array2.select{|ns16| !uuids1.include?(ns16["uuid"]) }
    end

    # TerminalUtils::inputParser(input, store)
    def self.inputParser(input, store) # [command or null, ns16 or null]
        # This function take an input from the prompt and 
        # attempt to retrieve a command and optionaly an object (from the store)
        # Note that the command can also be null if a command could not be extrated

        outputForCommandAndOrdinal = lambda {|command, ordinal, store|
            ordinal = ordinal.to_i
            ns16 = store.get(ordinal)
            if ns16 then
                return [command, ns16]
            else
                return [nil, nil]
            end
        }

        if Interpreting::match("[]", input) then
            return ["[]", nil]
        end

        if Interpreting::match(">>", input) then
            return [">>", nil]
        end

        if Interpreting::match("..", input) then
            return ["..", store.getDefault()]
        end

        if Interpreting::match(".. *", input) then
            _, ordinal = Interpreting::tokenizer(input)
            return outputForCommandAndOrdinal.call("..", ordinal, store)
        end

        if Interpreting::match(">todo", input) then
            return [">todo", store.getDefault()]
        end

        if Interpreting::match("access", input) then
            return ["access", store.getDefault()]
        end

        if Interpreting::match("access *", input) then
            _, ordinal = Interpreting::tokenizer(input)
            return outputForCommandAndOrdinal.call("access", ordinal, store)
        end

        if Interpreting::match("done", input) then
            return ["done", store.getDefault()]
        end

        if Interpreting::match("done *", input) then
            _, ordinal = Interpreting::tokenizer(input)
            return outputForCommandAndOrdinal.call("done", ordinal, store)
        end

        if Interpreting::match("drop", input) then
            return ["drop", nil]
        end

        if Interpreting::match("expose", input) then
            return ["expose", store.getDefault()]
        end

        if Interpreting::match("expose *", input) then
            _, ordinal = Interpreting::tokenizer(input)
            return outputForCommandAndOrdinal.call("expose", ordinal, store)
        end

        if Interpreting::match("float", input) then
            return ["float", nil]
        end

        if Interpreting::match("fsck", input) then
            return ["fsck", nil]
        end

        if Interpreting::match("nyx", input) then
            return ["nyx", nil]
        end

        if Interpreting::match("pursue", input) then
            return ["pursue", store.getDefault()]
        end

        if Interpreting::match("pursue *", input) then
            _, ordinal = Interpreting::tokenizer(input)
            return outputForCommandAndOrdinal.call("pursue", ordinal, store)
        end

        if Interpreting::match("start something", input) then
            return ["start something", nil]
        end

        if Interpreting::match("search", input) then
            return ["search", store.getDefault()]
        end

        if Interpreting::match("start", input) then
            return ["start", store.getDefault()]
        end

        if Interpreting::match("start *", input) then
            _, ordinal = Interpreting::tokenizer(input)
            return outputForCommandAndOrdinal.call("start", ordinal, store)
        end

        if Interpreting::match("stop", input) then
            return ["stop", store.getDefault()]
        end

        if Interpreting::match("stop *", input) then
            _, ordinal = Interpreting::tokenizer(input)
            return outputForCommandAndOrdinal.call("stop", ordinal, store)
        end

        if Interpreting::match("top", input) then
            return ["top", store.getDefault()]
        end

        if Interpreting::match("today", input) then
            return ["today", nil]
        end

        if Interpreting::match("todo", input) then
            return ["todo", store.getDefault()]
        end

        if Interpreting::match("transmute", input) then
            return ["transmute", store.getDefault()]
        end

        if Interpreting::match("transmute *", input) then
            _, ordinal = Interpreting::tokenizer(input)
            return outputForCommandAndOrdinal.call("transmute", ordinal, store)
        end

        if Interpreting::match("universe", input) then
            return ["universe", store.getDefault()]
        end

        if Interpreting::match("universe *", input) then
            _, ordinal = Interpreting::tokenizer(input)
            return outputForCommandAndOrdinal.call("universe", ordinal, store)
        end

        [nil, nil]
    end

    # TerminalUtils::transmutation1(object, source, target)
    # source: "TxDated" (dated) | "TxTodo" | "TxFloat" (float) | "inbox"
    # target: "TxDated" (dated) | "TxTodo" | "TxFloat" (float)
    def self.transmutation1(object, source, target)

        if source == "inbox" and target == "TxTodo" then
            location = object
            TxTodos::interactivelyIssueItemUsingInboxLocation2(location)
            LucilleCore::removeFileSystemLocation(location)
            return
        end

        if source == "TxDated" and target == "TxTodo" then
            universe = Multiverse::interactivelySelectUniverse()
            ordinal = TxTodos::interactivelyDecideNewOrdinal(universe)
            object["ordinal"] = ordinal
            object["mikuType"] = "TxTodo"
            Librarian6Objects::commit(object)
            ObjectUniverseMapping::setObjectUniverseMapping(object["uuid"], universe)
            return
        end

        if source == "TxDated" and target == "TxDrop" then
            object["mikuType"] = "TxDrop"
            Librarian6Objects::commit(object)
            ObjectUniverseMapping::interactivelySetObjectUniverseMapping(object["uuid"])
            return
        end

        if source == "TxDated" and target == "TxFloat" then
            object["mikuType"] = "TxFloat"
            Librarian6Objects::commit(object)
            ObjectUniverseMapping::interactivelySetObjectUniverseMapping(object["uuid"])
            return
        end

        if source == "TxDrop" and target == "TxTodo" then
            universe = Multiverse::interactivelySelectUniverse()
            ordinal = TxTodos::interactivelyDecideNewOrdinal(universe)
            object["ordinal"] = ordinal
            object["mikuType"] = "TxTodo"
            Librarian6Objects::commit(object)
            ObjectUniverseMapping::setObjectUniverseMapping(object["uuid"], universe)
            return
        end

        if source == "TxFloat" and target == "TxDated" then
            universe = Multiverse::interactivelySelectUniverse()
            object["mikuType"] = "TxDated"
            object["datetime"] = Utils::interactivelySelectAUTCIso8601DateTimeOrNull()
            Librarian6Objects::commit(object)
            ObjectUniverseMapping::setObjectUniverseMapping(object["uuid"], universe)
            return
        end

        if source == "TxFloat" and target == "TxTodo" then
            universe = Multiverse::interactivelySelectUniverse()
            ordinal = TxTodos::interactivelyDecideNewOrdinal(universe)
            object["ordinal"] = ordinal
            object["mikuType"] = "TxTodo"
            Librarian6Objects::commit(object)
            ObjectUniverseMapping::setObjectUniverseMapping(object["uuid"], universe)
            return
        end

        puts "I do not yet know how to transmute from '#{source}' to '#{target}'"
        LucilleCore::pressEnterToContinue()
    end

    # TerminalUtils::transmutation2(object, source)
    def self.transmutation2(object, source)
        target = TerminalUtils::interactivelyGetTransmutationTargetOrNull()
        return if target.nil?
        TerminalUtils::transmutation1(object, source, target)
    end

    # TerminalUtils::interactivelyGetTransmutationTargetOrNull()
    def self.interactivelyGetTransmutationTargetOrNull()
        options = ["TxFloat", "TxDated", "TxTodo" ]
        option = LucilleCore::selectEntityFromListOfEntitiesOrNull("target", options)
        return nil if option.nil?
        option
    end
end

class Commands

    # Commands::terminalDisplayCommand()
    def self.terminalDisplayCommand()
        "<datecode> | <n> | .. (<n>) | expose (<n>) | transmute (<n>) | start (<n>) | search | nyx | >nyx"
    end

    # Commands::makersCommands()
    def self.makersCommands()
        "wave | anniversary | calendaritem | float | drop | today | ondate | todo"
    end

    # Commands::diversCommands()
    def self.diversCommands()
        "waves | anniversaries | calendar | ondates | todos"
    end
end

class ItemStore

    def initialize() # : Integer
        @items = []
        @defaultItem = nil
    end

    def register(item, canBeDefault)
        cursor = @items.size
        @items << item
        if @defaultItem.nil? and canBeDefault then
            @defaultItem = item
        end
        @items.size-1
    end

    def latestEnteredItemIsDefault()
        return false if @defaultItem.nil?
        @items.last["uuid"] == @defaultItem["uuid"]
    end

    def prefixString()
        indx = @items.size-1
        latestEnteredItemIsDefault() ? "(-->)".green : "(#{"%3d" % indx})"
    end

    def get(indx)
        @items[indx].clone
    end

    def getDefault()
        @defaultItem.clone
    end
end

class NS16sOperator

    # NS16sOperator::section3(universe)
    def self.section3(universe)
        [
            (universe == "lucille") ? Anniversaries::ns16s() : [],
            TxCalendarItems::ns16s(),
            JSON.parse(`/Users/pascal/Galaxy/LucilleOS/Binaries/amanda-bins`),
            JSON.parse(`/Users/pascal/Galaxy/LucilleOS/Binaries/fitness ns16s`),
            TxDateds::ns16s(),
            Waves::ns16s(universe),
            (universe.nil? or universe == "lucille") ? Inbox::ns16s() : [],
            TxDrops::ns16s(universe),
            TxTodos::ns16s(universe)
        ]
            .flatten
            .select{|item| DoNotShowUntil::isVisible(item["uuid"]) }
            .select{|ns16| InternetStatus::ns16ShouldShow(ns16["uuid"]) }
    end
end

class TerminalDisplayOperator

    # TerminalDisplayOperator::ns16HasStarted(ns16)
    def self.ns16HasStarted(ns16)
        NxBallsService::isRunning(ns16["uuid"])
    end

    # TerminalDisplayOperator::standardDisplay(universe, floats, section3)
    def self.standardDisplay(universe, floats, section3)
        system("clear")

        vspaceleft = Utils::screenHeight()-3

        puts ""
        puts UniverseAccounting::getExpectationUniversesInRatioOrder()
            .map{|uni|
                expectation = UniverseAccounting::universeExpectationOrNull(uni)
                uniRatio = UniverseAccounting::universeRatioOrNull(uni)
                line = "(#{uni}: #{(100 * uniRatio).round(2)} % of #{"%.2f" % expectation} hours)"
                if uni == universe then
                    line = line.green
                end
                vspaceleft = vspaceleft - Utils::verticalSize(line)
                line
            }.join(" ")

        store = ItemStore.new()

        if !InternetStatus::internetIsActive() then
            puts ""
            puts "INTERNET IS OFF".green
            vspaceleft = vspaceleft - 2
        end

        if floats.size>0 then
            puts ""
            vspaceleft = vspaceleft - 1
        end
        floats.each{|ns16|
            store.register(ns16, false)
            line = "#{store.prefixString()} [#{Time.at(ns16["TxFloat"]["unixtime"]).to_s[0, 10]}] #{ns16["announce"]}".yellow
            puts line
            vspaceleft = vspaceleft - Utils::verticalSize(line)
        }

        running = BTreeSets::values(nil, "a69583a5-8a13-46d9-a965-86f95feb6f68")
        listingUUIDs = section3.map{|item| item["uuid"] }
        running = running.select{|nxball| !listingUUIDs.include?(nxball["uuid"]) }
        if running.size>0 then
            puts ""
            vspaceleft = vspaceleft - 1
        end
        running
                .sort{|t1, t2| t1["unixtime"] <=> t2["unixtime"] } # || 0 because we had some running while updating this
                .each{|nxball|
                    delegate = {
                        "uuid"       => nxball["uuid"],
                        "mikuType"   => "NxBallNS16Delegate1" 
                    }
                    store.register(delegate, true)
                    line = "#{store.prefixString()} #{nxball["description"]} (#{NxBallsService::runningStringOrEmptyString("", nxball["uuid"], "")})".green
                    puts line
                    vspaceleft = vspaceleft - Utils::verticalSize(line)
                }

        top = Topping::getText(universe)
        if top and top.strip.size > 0 then
            puts ""
            puts "(-->) (top)".green
            top = top.lines.first(10).join()
            puts top
            vspaceleft = vspaceleft - Utils::verticalSize(top) - 2
        end

        if section3.size>0 then
            puts ""
            vspaceleft = vspaceleft - 1
        end
        section3
            .each{|ns16|
                canBeDefault = true
                if ns16["nonListingDefaultable"] then
                    canBeDefault = false
                end
                store.register(ns16, canBeDefault)
                line = ns16["announce"]
                line = "#{store.prefixString()} #{(ObjectUniverseMapping::getObjectUniverseMappingOrNull(ns16["uuid"]) || "").ljust(7)} #{line}"
                break if (vspaceleft - Utils::verticalSize(line)) < 0
                if TerminalDisplayOperator::ns16HasStarted(ns16) then
                    line = line.green
                end
                puts line
                vspaceleft = vspaceleft - Utils::verticalSize(line)
            }

        puts ""

        input = LucilleCore::askQuestionAnswerAsString("> ")

        return if input == ""

        if (unixtime = Utils::codeToUnixtimeOrNull(input.gsub(" ", ""))) then
            if (item = store.getDefault()) then
                DoNotShowUntil::setUnixtime(item["uuid"], unixtime)
                return
            end
        end

        command, objectOpt = TerminalUtils::inputParser(input, store)
        #puts "parser: command:#{command}, objectOpt: #{objectOpt}"
        GlobalActions::action(command, objectOpt)
    end

    # TerminalDisplayOperator::standardDisplayLoop()
    def self.standardDisplayLoop()
        initialCodeTrace = Utils::codeTrace()
        loop {
            if Utils::codeTrace() != initialCodeTrace then
                puts "Code change detected"
                break
            end

            TxTodos::importNx50BacklogInbox()

            universe = StoredUniverse::getUniverseOrNull()
            floats = TxFloats::ns16s(universe)
                        .select{|item| DoNotShowUntil::isVisible(item["uuid"]) }
                        .select{|ns16| InternetStatus::ns16ShouldShow(ns16["uuid"]) }

            section3 = NS16sOperator::section3(universe)
            TerminalDisplayOperator::standardDisplay(universe, floats, section3)
        }
    end
end
