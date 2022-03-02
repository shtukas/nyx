
class GlobalActions

    # GlobalActions::action(command, object)
    def self.action(command, object)

        # All objects sent to this are expected to have an mikyType attribute

        return if command.nil?

        if command == "access" then

            if object["mikuType"] == "NS16:Anniversary1" then
                Anniversaries::access(object["anniversary"])
                return
            end

            if object["mikuType"] == "NS16:TxCalendarItem" then
                TxCalendarItems::access(object["item"])
                return
            end

            if object["mikuType"] == "NS16:fitness1" then
                system("/Users/pascal/Galaxy/LucilleOS/Binaries/fitness doing #{object["fitness-domain"]}")
                return
            end

            if object["mikuType"] == "NS16:Inbox1" then
                Inbox::access(object["location"])
                return
            end

            if object["mikuType"] == "NS16:TxDated" then
                dated = object["TxDated"]
                TxDateds::access(dated)
                return
            end

            if object["mikuType"] == "NS16:TxDrop" then
                nx70 = object["TxDrop"]
                puts nx70["description"].green
                action = LucilleCore::selectEntityFromListOfEntitiesOrNull("action", ["run", "done"])
                return if action.nil?
                if action == "run" then
                    TxDrops::access(nx70)
                end
                if action == "done" then
                    TxDrops::destroy(nx70["uuid"])
                end
                return
            end

            if object["mikuType"] == "NS16:TxFloat" then
                TxFloats::access(object["TxFloat"])
                return
            end

            if object["mikuType"] == "NS16:TxTodo" then
                TxTodos::access(object["TxTodo"])
                return
            end

            if object["mikuType"] == "NS16:Wave" then
                Waves::access(object["wave"])
                return
            end

            if object["mikuType"] == "NxBallDelegate1" then
                uuid = object["NxBallUUID"]

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
                return
            end
        end

        if command == ".." then
            # Double Dot typically peforms start and access
            GlobalActions::action("start", object)
            GlobalActions::action("access", object)
            return
        end

        if command == "expose" then
            puts JSON.pretty_generate(object)
            LucilleCore::pressEnterToContinue()
            return
        end

        if command == "landing" then
            ns16 = object
            if ns16["mikuType"] == "NS16:Wave" and command == "landing" then
                Waves::landing(ns16["wave"])
                return
            end
        end

        if command == "redate" then
            ns16 = object
            if ns16["mikuType"] == "NS16:TxDated" then
                mx49 = ns16["TxDated"]
                datetime = (Utils::interactivelySelectAUTCIso8601DateTimeOrNull() || Time.new.utc.iso8601)
                mx49["datetime"] = datetime
                Librarian6Objects::commit(mx49)
                return
            end
        end

        if command == "require internet" then
            ns16 = object
            InternetStatus::markIdAsRequiringInternet(ns16["uuid"])
            return
        end

        if command == "start" then
            ns16 = object
            data = {
                "uuid"          => ns16["uuid"],
                "ns16"          => ns16,
                "startUnixtime" => Time.new.to_f
            }

            # We starts the ns16 by adding it to the set.
            BTreeSets::set(nil, "2d51b69f-ece7-4d85-b27e-39770c470401", data["uuid"], data)
            return
        end

        if command == "stop" then
            ns16 = object
            data = BTreeSets::getOrNull(nil, "2d51b69f-ece7-4d85-b27e-39770c470401", ns16["uuid"])
            return if data.nil?

            timespan = Time.new.to_f - data["startUnixtime"]

            # Now adding the timespan to the element uuid
            # In this code we assume that the uuid to receive the time is the ns16 uuid, because the ns16 uuid is often the item uuid
            # TODO: NS16s should provide a set of uuids to send the time to, one of which should be the universe account number 
            Bank::put(ns16["uuid"], timespan)

            # For the moment we send all the time to backlog
            Bank::put(UniverseAccounting::universeToAccountNumber("backlog"), timespan)

            BTreeSets::destroy(nil, "2d51b69f-ece7-4d85-b27e-39770c470401", ns16["uuid"])
            return
        end

        if command == "transmute" then
            ns16 = object
            if ns16["mikuType"] == "NS16:Inbox1" then
                location = ns16["location"]
                TerminalUtils::transmutation2(location, "inbox")
                return
            end

            if ns16["mikuType"] == "NS16:TxDated" then
                mx49 = ns16["TxDated"]
                TerminalUtils::transmutation2(mx49, "TxDated")
                return
            end

            if ns16["mikuType"] == "NS16:TxDrop" then
                nx70 = ns16["TxDrop"]
                TerminalUtils::transmutation2(nx70, "TxDrop")
                return
            end
        end

        if command == "universe" then
            ns16 = object
            if ns16["mikuType"] == "NS16:TxFloat" then
                item = ns16["TxFloat"]
                Multiverse::interactivelySetObjectUniverse(item["uuid"])
                return
            end
        end

        if command == "top" then
            universe = StoredUniverse::getUniverse()
            Topping::top(universe)
            return
        end

        if command == "[]" then
            universe = StoredUniverse::getUniverse()
            Topping::applyTransformation(universe)
            return
        end

        if command == "float" then
            TxFloats::interactivelyCreateNewOrNull()
            return
        end

        if command == "drop" then
            TxDrops::interactivelyCreateNewOrNull()
            return
        end

        if command == "ondate" then
            item = TxDateds::interactivelyCreateNewOrNull()
            return if item.nil?
            puts JSON.pretty_generate(item)
            return
        end

        if command == "today" then
            mx49 = TxDateds::interactivelyCreateNewTodayOrNull()
            return if mx49.nil?
            puts JSON.pretty_generate(mx49)
            return
        end

        if command == "todo" then
            item = TxTodos::interactivelyCreateNewOrNull()
            return if item.nil?
            puts JSON.pretty_generate(item)
            return
        end

        if command == "wave" then
            item = Waves::issueNewWaveInteractivelyOrNull()
            return if item.nil?
            puts JSON.pretty_generate(item)
            return
        end

        if command == "anniversary" then
            item = Anniversaries::issueNewAnniversaryOrNullInteractively()
            return if item.nil?
            puts JSON.pretty_generate(item)
            return
        end

        if command == "anniversaries" then
            Anniversaries::anniversariesDive()
            return
        end

        if command == "waves" then
            Waves::waves()
            return
        end

        if command == "ondates" then
            TxDateds::dive()
            return
        end

        if command == "todos" then
            nx50s = TxTodos::items()
            if LucilleCore::askQuestionAnswerAsBoolean("limit ? ", true) then
                nx50s = nx50s.first(Utils::screenHeight()-2)
            end
            loop {
                nx50 = LucilleCore::selectEntityFromListOfEntitiesOrNull("nx50", nx50s, lambda {|nx50| TxTodos::toString(nx50) })
                return if nx50.nil?
                TxTodos::access(nx50)
            }
            return
        end

        if command == "search" then
            Search::search()
            return
        end

        if command == "calendaritem" then
            TxCalendarItems::interactivelyCreateNewOrNull()
            return
        end

        if command == "calendar" then
            TxCalendarItems::dive()
            return
        end

        if command == "nyx" then
            system("/Users/pascal/Galaxy/Software/Nyx/nyx")
            return
        end

        if command == "commands" then
            puts [
                    "      " + Commands::terminalDisplayCommand(),
                    "      " + Commands::makersCommands(),
                    "      " + Commands::diversCommands(),
                    "      internet on | internet off | require internet",
                    "      universe (set the universe of the dafault item) (<n>)  | >> (switch universe)"
                 ].join("\n").yellow
            LucilleCore::pressEnterToContinue()
            return
        end

        if command == "internet on" then
            InternetStatus::setInternetOn()
            return
        end

        if command == "internet off" then
            InternetStatus::setInternetOff()
            return
        end

        if command == ">>" then
            StoredUniverse::interactivelySetUniverse()
            return
        end

        if command == ">nyx" then
            ns16 = object
            #Nx31 {
            #    "uuid"        : uuid,
            #    "mikuType"    : "Nx31"
            #    "datetime"    : DateTime Iso 8601 UTC Zulu
            #    "unixtime"    : unixtime
            #    "description" : description
            #    "atomuuid"    : UUID of an Atom
            #}

            if ns16["mikuType"] == "NS16:Inbox1" then
                location = ns16["location"]
                NyxAdapter::locationToNyx(location)
            end
        end

        if command == "exit" then
            exit
        end

        puts "I do not know how to do action (command: #{command}, object: #{JSON.pretty_generate(object)})"
        LucilleCore::pressEnterToContinue()
    end
end