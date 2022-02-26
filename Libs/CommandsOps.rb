
class Commands

    # Commands::terminalDisplayCommand()
    def self.terminalDisplayCommand()
        "<datecode> | <n> | .. (<n>) | expose (<n>) | transmute (<n>) | start (<n>) | search | universe (set the universe of the dafault item) (<n>)  | >> (switch universe) | nyx | >nyx"
    end

    # Commands::makersCommands()
    def self.makersCommands()
        "wave | anniversary | calendaritem | float | drop | today | ondate | todo"
    end

    # Commands::diversCommands()
    def self.diversCommands()
        "waves | anniversaries | calendar | ondates | todos"
    end

    # Commands::makersAndDiversCommands()
    def self.makersAndDiversCommands()
        [
            Commands::makersCommands(),
            Commands::diversCommands()
        ].join(" | ")
    end
end

class CommandsOps

    # CommandsOps::closeAnyNxBallWithThisID(uuid)
    def self.closeAnyNxBallWithThisID(uuid)
        NxBallsService::close(uuid, true)
    end

    # CommandsOps::doubleDot(universe, ns16)
    def self.doubleDot(universe, ns16)
        if ns16["NS198"] == "NS16:Anniversary1" then
            Anniversaries::run(ns16["anniversary"])
        end

        if ns16["NS198"] == "NS16:TxCalendarItem" then
            TxCalendarItems::run(ns16["item"])
        end

        if ns16["NS198"] == "NS16:fitness1" then
            system("/Users/pascal/Galaxy/LucilleOS/Binaries/fitness doing #{ns16["fitness-domain"]}")
        end

        if ns16["NS198"] == "NS16:Inbox1" then
            Inbox::run(ns16["location"])
        end

        if ns16["NS198"] == "NS16:TxDated" then
            TxDateds::run(ns16["TxDated"])
        end

        if ns16["NS198"] == "NS16:TxDrop" then
            nx70 = ns16["TxDrop"]
            puts nx70["description"].green
            action = LucilleCore::selectEntityFromListOfEntitiesOrNull("action", ["run", "done"])
            return if action.nil?
            if action == "run" then
                TxDrops::run(nx70)
            end
            if action == "done" then
                TxDrops::destroy(nx70["uuid"])
            end
        end

        if ns16["NS198"] == "NS16:TxFloat" then
            TxFloats::run(ns16["TxFloat"])
        end

        if ns16["NS198"] == "NS16:TxTodo" then
            TxTodos::run(ns16["TxTodo"])
        end

        if ns16["NS198"] == "NS16:Wave" then
            Waves::run(ns16["wave"])
        end

        if ns16["NS198"] == "NxBallDelegate1" then
            uuid = ns16["NxBallUUID"]

            action = LucilleCore::selectEntityFromListOfEntitiesOrNull("action", ["close", "pursue", "pause"])
            if action == "close" then
                NxBallsService::close(uuid, true)
            end
            if action == "pursue" then
                NxBallsService::pursue(uuid)
            end
            if action == "pause" then
                NxBallsService::pause(uuid)
            end
        end
    end

    # CommandsOps::transmute(universe, ns16)
    def self.transmute(universe, ns16)
        if ns16["NS198"] == "NS16:Inbox1" then
            location = ns16["location"]
            CommandsOps::transmutation2(location, "inbox")
        end

        if ns16["NS198"] == "NS16:TxDated" then
            mx49 = ns16["TxDated"]
            CommandsOps::transmutation2(mx49, "TxDated")
        end

        if ns16["NS198"] == "NS16:TxDrop" then
            nx70 = ns16["TxDrop"]
            CommandsOps::transmutation2(nx70, "TxDrop")
        end
    end

    # CommandsOps::start(universe, ns16)
    def self.start(universe, ns16)
        if ns16["NS198"] == "NS16:TxTodo" then
            item = ns16["TxTodo"]
            NxBallsService::issue(item["uuid"], item["description"], [item["uuid"]])
        end
        if ns16["NS198"] == "NS16:Wave" then
            item = ns16["wave"]
            NxBallsService::issue(item["uuid"], item["description"], [item["uuid"]])
        end
    end

    # CommandsOps::done(universe, ns16)
    def self.done(universe, ns16)
        if ns16["NS198"] == "NS16:Anniversary1" then
            anniversary = ns16["anniversary"]
            puts Anniversaries::toString(anniversary).green
            anniversary["lastCelebrationDate"] = Time.new.to_s[0, 10]
            Anniversaries::commitAnniversaryToDisk(anniversary)
        end

        if ns16["NS198"] == "NS16:TxCalendarItem" then
            TxCalendarItems::destroy(ns16["item"]["uuid"])
        end

        if ns16["NS198"] == "NS16:TxDated" then
            mx49 = ns16["TxDated"]
            TxDateds::destroy(mx49["uuid"])
        end

        if ns16["NS198"] == "NS16:TxDrop" then
            nx70 = ns16["TxDrop"]
            TxDrops::destroy(nx70["uuid"])
        end

        if ns16["NS198"] == "NS16:TxTodo" then
            nx50 = ns16["TxTodo"]
            if LucilleCore::askQuestionAnswerAsBoolean("destroy '#{TxTodos::toString(nx50)}' ? ", true) then
                TxTodos::destroy(nx50["uuid"])
                CommandsOps::closeAnyNxBallWithThisID(ns16["uuid"])
            end
        end

        if ns16["NS198"] == "NS16:Wave" then
            Waves::performDone(ns16["wave"])
            CommandsOps::closeAnyNxBallWithThisID(ns16["uuid"])
        end

        if ns16["NS198"] == "NxBallDelegate1" then
            uuid = ns16["NxBallUUID"]
            NxBallsService::close(uuid, true)
        end
    end

    # CommandsOps::transmutation1(object, source, target)
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
            LibrarianObjects::commit(object)
            Multiverse::setObjectUniverse(object["uuid"], universe)
            return
        end

        if source == "TxDated" and target == "TxDrop" then
            object["mikuType"] = "TxDrop"
            LibrarianObjects::commit(object)
            Multiverse::interactivelySetObjectUniverse(object["uuid"])
            return
        end

        if source == "TxDated" and target == "TxFloat" then
            object["mikuType"] = "TxFloat"
            LibrarianObjects::commit(object)
            Multiverse::interactivelySetObjectUniverse(object["uuid"])
            return
        end

        if source == "TxDrop" and target == "TxTodo" then
            universe = Multiverse::interactivelySelectUniverse()
            ordinal = TxTodos::interactivelyDecideNewOrdinal(universe)
            object["ordinal"] = ordinal
            object["mikuType"] = "TxTodo"
            LibrarianObjects::commit(object)
            Multiverse::setObjectUniverse(object["uuid"], universe)
            return
        end

        if source == "TxFloat" and target == "TxDated" then
            universe = Multiverse::interactivelySelectUniverse()
            object["mikuType"] = "TxDated"
            object["datetime"] = Utils::interactivelySelectAUTCIso8601DateTimeOrNull()
            LibrarianObjects::commit(object)
            Multiverse::setObjectUniverse(object["uuid"], universe)
            return
        end

        if source == "TxFloat" and target == "TxTodo" then
            universe = Multiverse::interactivelySelectUniverse()
            ordinal = TxTodos::interactivelyDecideNewOrdinal(universe)
            object["ordinal"] = ordinal
            object["mikuType"] = "TxTodo"
            LibrarianObjects::commit(object)
            Multiverse::setObjectUniverse(object["uuid"], universe)
            return
        end

        puts "I do not yet know how to transmute from '#{source}' to '#{target}'"
        LucilleCore::pressEnterToContinue()
    end

    # CommandsOps::interactivelyGetTransmutationTargetOrNull()
    def self.interactivelyGetTransmutationTargetOrNull()
        options = ["TxFloat", "TxDated", "TxTodo" ]
        option = LucilleCore::selectEntityFromListOfEntitiesOrNull("target", options)
        return nil if option.nil?
        option
    end

    # CommandsOps::transmutation2(object, source)
    def self.transmutation2(object, source)
        target = CommandsOps::interactivelyGetTransmutationTargetOrNull()
        return if target.nil?
        CommandsOps::transmutation1(object, source, target)
    end

    # CommandsOps::inputParser(input, store)
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

        if Interpreting::match("expose *", input) then
            _, ordinal = Interpreting::tokenizer(input)
            return outputForCommandAndOrdinal.call("expose", ordinal, store)
        end

        if Interpreting::match(".. *", input) then
            _, ordinal = Interpreting::tokenizer(input)
            return outputForCommandAndOrdinal.call("..", ordinal, store)
        end

        if Interpreting::match("transmute *", input) then
            _, ordinal = Interpreting::tokenizer(input)
            return outputForCommandAndOrdinal.call("transmute", ordinal, store)
        end

        if Interpreting::match("start *", input) then
            _, ordinal = Interpreting::tokenizer(input)
            return outputForCommandAndOrdinal.call("start", ordinal, store)
        end

        if Interpreting::match("done *", input) then
            _, ordinal = Interpreting::tokenizer(input)
            return outputForCommandAndOrdinal.call("done", ordinal, store)
        end

        if Interpreting::match("universe *", input) then
            _, ordinal = Interpreting::tokenizer(input)
            return outputForCommandAndOrdinal.call("universe", ordinal, store)
        end

        [nil, nil]
    end

    # CommandsOps::operator5(universe, command, ns16)
    def self.operator5(universe, command, ns16)
        if command == "expose" then
            puts JSON.pretty_generate(ns16)
            LucilleCore::pressEnterToContinue()
        end
        if command == ".." then
            CommandsOps::doubleDot(universe, ns16)
        end
        if command == "transmute" then
            CommandsOps::transmute(universe, ns16)
        end
        if command == "start" then
            CommandsOps::start(universe, ns16)
        end
        if command == "done" then
            CommandsOps::done(universe, ns16)
        end
        if command == "universe" then
            if ns16["NS198"] == "NS16:TxTodo" then
                item = ns16["TxTodo"]
                Multiverse::interactivelySetObjectUniverse(item["uuid"])
                return
            end
            if ns16["NS198"] == "NS16:Wave" then
                item = ns16["wave"]
                Multiverse::interactivelySetObjectUniverse(item["uuid"])
                return
            end
            puts "I do not know how to set a universe for this object (fc593ecc-5079-46d1-a4f6-dcd9af82d0ed):"
            puts JSON.pretty_generate(ns16)
            LucilleCore::pressEnterToContinue()
        end
        if command == ">nyx" then
            
            #Nx31 {
            #    "uuid"        : uuid,
            #    "mikuType"    : "Nx31"
            #    "datetime"    : DateTime Iso 8601 UTC Zulu
            #    "unixtime"    : unixtime
            #    "description" : description
            #    "atomuuid"    : UUID of an Atom
            #}

            if ns16["NS198"] == "NS16:Inbox1" then
                location = ns16["location"]
                NyxAdapter::locationToNyx(location)
            end
        end
    end

    # CommandsOps::operator4(universe, command)
    def self.operator4(universe, command)

        if command == "top" then
            Topping::top(universe)
            return
        end

        if command == "[]" then
            Topping::applyTransformation(universe)
        end

        if command == "start" then
            description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
            return if description == ""
            NxBallsService::issue(SecureRandom.uuid, description, [])
        end

        if command == "float" then
            TxFloats::interactivelyCreateNewOrNull()
        end

        if command == "drop" then
            TxDrops::interactivelyCreateNewOrNull()
        end

        if command == "ondate" then
            item = TxDateds::interactivelyCreateNewOrNull()
            return if item.nil?
            puts JSON.pretty_generate(item)
        end

        if command == "today" then
            mx49 = TxDateds::interactivelyCreateNewTodayOrNull()
            return if mx49.nil?
            puts JSON.pretty_generate(mx49)
        end

        if command == "todo" then
            item = TxTodos::interactivelyCreateNewOrNull()
            return if item.nil?
            puts JSON.pretty_generate(item)
        end

        if command == "wave" then
            item = Waves::issueNewWaveInteractivelyOrNull()
            return if item.nil?
            puts JSON.pretty_generate(item)
        end

        if command == "anniversary" then
            item = Anniversaries::issueNewAnniversaryOrNullInteractively()
            return if item.nil?
            puts JSON.pretty_generate(item)
        end

        if command == "anniversaries" then
            Anniversaries::anniversariesDive()
        end

        if command == "waves" then
            Waves::waves()
        end

        if command == "ondates" then
            TxDateds::dive()
        end

        if command == "todos" then
            nx50s = TxTodos::items()
            if LucilleCore::askQuestionAnswerAsBoolean("limit ? ", true) then
                nx50s = nx50s.first(Utils::screenHeight()-2)
            end
            loop {
                nx50 = LucilleCore::selectEntityFromListOfEntitiesOrNull("nx50", nx50s, lambda {|nx50| TxTodos::toString(nx50) })
                return if nx50.nil?
                TxTodos::run(nx50)
            }
        end

        if command == "search" then
            Search::search()
        end

        if command == "calendaritem" then
            TxCalendarItems::interactivelyCreateNewOrNull()
        end

        if command == "calendar" then
            TxCalendarItems::dive()
        end

        if command == "nyx" then
            system("/Users/pascal/Galaxy/Software/Nyx/nyx")
        end

        if command == "commands" then
            puts [
                    "      " + Commands::terminalDisplayCommand(),
                    "      " + Commands::makersCommands(),
                    "      " + Commands::diversCommands(),
                    "      internet on | internet off | require internet"
                 ].join("\n").yellow
            LucilleCore::pressEnterToContinue()
        end

        if command == "internet on" then
            InternetStatus::setInternetOn()
        end

        if command == "internet off" then
            InternetStatus::setInternetOff()
        end

        if command == ">>" then
            Multiverse::interactivelySetFocus()
        end

        if command == ">>>" then
            UniverseAccounting::autoFocus()
        end

        if command == "exit" then
            exit
        end
    end

    # CommandsOps::operator6(universe, command, objectOpt)
    def self.operator6(universe, command, objectOpt)

        return if command.nil?

        if command == "expose" then
            ns16 = objectOpt
            puts JSON.pretty_generate(ns16)
            LucilleCore::pressEnterToContinue()
        end

        if command == ".." then
            ns16 = objectOpt
            CommandsOps::doubleDot(universe, ns16)
        end

        if command == "done" then
            ns16 = objectOpt
            CommandsOps::done(universe, ns16)
        end

        if command == "transmute" then
            ns16 = objectOpt
            CommandsOps::transmute(universe, ns16)
        end

        if command == "start" then
            ns16 = objectOpt
            CommandsOps::start(universe, ns16)
        end

        if command == "redate" then
            ns16 = objectOpt
            if ns16["NS198"] == "NS16:TxDated" then
                mx49 = ns16["TxDated"]
                datetime = (Utils::interactivelySelectAUTCIso8601DateTimeOrNull() || Time.new.utc.iso8601)
                mx49["datetime"] = datetime
                LibrarianObjects::commit(mx49)
            end 
        end

        if command == "landing" then
            ns16 = objectOpt
            if ns16["NS198"] == "NS16:Wave" and command == "landing" then
                Waves::landing(ns16["wave"])
            end
        end

        if command == "require internet" then
            ns16 = objectOpt
            InternetStatus::markIdAsRequiringInternet(ns16["uuid"])
        end

        if command == "universe" then
            ns16 = objectOpt
            if ns16["NS198"] == "NS16:TxFloat" then
                item = ns16["TxFloat"]
                Multiverse::interactivelySetObjectUniverse(item["uuid"])
                return
            end
            puts "I do not know how to set a universe for this object (1623a9d7-3ad4-465b-886d-1febbcc32036):"
            puts JSON.pretty_generate(ns16)
            LucilleCore::pressEnterToContinue()
        end
    end
end
