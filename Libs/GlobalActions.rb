
class GlobalActions

    # GlobalActions::action(command, object)
    def self.action(command, object)

        # All objects sent to this are expected to have an mikyType attribute

        return if command.nil?

        if command == ".." then
            if !NxBallsService::isRunning(object["uuid"]) then
                GlobalActions::action("start", object)
                if LucilleCore::askQuestionAnswerAsBoolean("access '#{object["announce"]}' ? ", true) then
                    GlobalActions::action("access", object)
                    if object["mikuType"] == "NS16:fitness1" then
                        GlobalActions::action("stop", object)
                    end
                end
                return
            end

            GlobalActions::action("access", object)

            # We do not perform "stop" on a wave
            # NxBall Management will have been done by access itself.
            if object["mikuType"] == "NS16:Wave" then
                return
            end
            if LucilleCore::askQuestionAnswerAsBoolean("stop '#{object["announce"]}' ? ") then
                GlobalActions::action("stop", object)
            end
            return
        end

        if command == "[]" then
            Topping::applyTransformation(StoredUniverse::getUniverseOrNull())
            return
        end

        if command == ">>" then
            if NxBallsService::somethingIsRunning() then
                puts "You cannot switch universe while something is running"
                LucilleCore::pressEnterToContinue()
                return
            end
            StoredUniverse::interactivelySetUniverseOrUnsetUniverse()
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
                return
            end
        end

        if command == ">todo" then
            ns16 = object
            if ns16["mikuType"] == "NS16:Inbox1" then
                location = ns16["location"]
                TxTodos::interactivelyIssueItemUsingInboxLocation2(location)
                LucilleCore::removeFileSystemLocation(location)
                return
            end
        end

        if command == "access" then

            if object["mikuType"] == "NS16:Anniversary1" then
                Anniversaries::access(object["anniversary"])
                return
            end

            if object["mikuType"] == "NS16:TxCalendarItem" then
                AgentsUtils::accessAtom(object["item"]["atomuuid"])
                return
            end

            if object["mikuType"] == "NS16:fitness1" then
                system("/Users/pascal/Galaxy/LucilleOS/Binaries/fitness doing #{object["fitness-domain"]}")
                return
            end

            if object["mikuType"] == "NS16:Inbox1" then
                Inbox::landing(object["location"])
                return
            end

            if object["mikuType"] == "NS16:TxDated" then
                dated = object["TxDated"]
                AgentsUtils::accessAtom(dated["atomuuid"])
                return
            end

            if object["mikuType"] == "NS16:TxFyre" then
                nx70 = object["TxFyre"]
                AgentsUtils::accessAtom(nx70["atomuuid"])
                return
            end

            if object["mikuType"] == "NS16:TxFloat" then
                AgentsUtils::accessAtom(object["TxFloat"]["atomuuid"])
                return
            end

            if object["mikuType"] == "NS16:TxTodo" then
                AgentsUtils::accessAtom(object["TxTodo"]["atomuuid"])
                return
            end

            if object["mikuType"] == "NS16:Wave" then
                code = Waves::landing(object["wave"])
                # "ebdc6546-8879" # Continue
                # "8a2aeb48-780d" # Close NxBall
                if code == "ebdc6546-8879" then
                    return
                end
                if code == "8a2aeb48-780d" then
                    NxBallsService::close(object["uuid"], true)
                    return 
                end
                return
            end
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

        if command == "calendar" then
            TxCalendarItems::dive()
            return
        end

        if command == "calendaritem" then
            TxCalendarItems::interactivelyCreateNewOrNull()
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

        if command == "done" then

            # If the object was running, then we stop it
            if NxBallsService::isRunning(object["uuid"]) then
                GlobalActions::action("stop", object)
            end

            if object["mikuType"] == "NxBallNS16Delegate1" then
                NxBallsService::close(object["uuid"], true)
                return
            end
            if object["mikuType"] == "NS16:TxDated" then
                item = object["TxDated"]
                if LucilleCore::askQuestionAnswerAsBoolean("Confirm destruction of dated '#{item["description"]}' ? ") then
                    TxDateds::destroy(item["uuid"])
                end
                return
            end
            if object["mikuType"] == "NS16:TxFyre" then
                item = object["TxFyre"]
                if LucilleCore::askQuestionAnswerAsBoolean("Confirm destruction of dated '#{item["description"]}' ? ") then
                    TxFyres::destroy(item["uuid"])
                end
                return
            end
            if object["mikuType"] == "NS16:TxTodo" then
                item = object["TxTodo"]
                if NxBallsService::isRunning(item["uuid"]) then
                    action = LucilleCore::selectEntityFromListOfEntitiesOrNull("action", ["stop running NxBall", "destroy item"])
                    return if action.nil?
                    if action == "stop running NxBall" then
                        NxBallsService::close(item["uuid"], true)
                        return
                    end
                    if action == "destroy item" then
                        # We go through the next section
                    end
                end
                if LucilleCore::askQuestionAnswerAsBoolean("Confirm destruction of dated '#{item["description"]}' ? ") then
                    TxTodos::destroy(item["uuid"])
                end
                return
            end
            if object["mikuType"] == "NS16:Wave" then
                wave = object["wave"]
                Waves::performDone(wave)
                return
            end
        end

        if command == "fyre" then
            TxFyres::interactivelyCreateNewOrNull()
            return
        end

        if command == "expose" then
            puts JSON.pretty_generate(object)
            LucilleCore::pressEnterToContinue()
            return
        end

        if command == "exit" then
            exit
        end

        if command == "float" then
            TxFloats::interactivelyCreateNewOrNull()
            return
        end

        if command == "fsck" then
            Librarian15Fsck::fsck()
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

        if command == "landing" then
            ns16 = object

            if object["mikuType"] == "NS16:Anniversary1" then
                Anniversaries::landing(object["anniversary"])
                return
            end

            if object["mikuType"] == "NS16:TxCalendarItem" then
                TxCalendarItems::ns16(object["item"])
                return
            end

            if object["mikuType"] == "NS16:fitness1" then
                system("/Users/pascal/Galaxy/LucilleOS/Binaries/fitness doing #{object["fitness-domain"]}")
                return
            end

            if object["mikuType"] == "NS16:Inbox1" then
                Inbox::landing(object["location"])
                return
            end

            if object["mikuType"] == "NS16:TxDated" then
                mx49 = object["TxDated"]
                TxDateds::landing(mx49)
                return
            end

            if object["mikuType"] == "NS16:TxFyre" then
                nx70 = object["TxFyre"]
                TxFyres::landing(nx70)
                return
            end

            if object["mikuType"] == "NS16:TxFloat" then
                TxFloats::landing(object["TxFloat"])
                return
            end

            if object["mikuType"] == "NS16:TxTodo" then
                TxTodos::landing(object["TxTodo"])
                return
            end

            if ns16["mikuType"] == "NS16:Wave" then
                Waves::landing(ns16["wave"])
                return
            end
        end

        if command == "mode" then
            if NxBallsService::somethingIsRunning() then
                puts "You cannot run mode while something is running"
                LucilleCore::pressEnterToContinue()
                return
            end
            UniverseDrivingModes::interactivelySetMode()
            return
        end

        if command == "nyx" then
            system("/Users/pascal/Galaxy/Software/Catalyst/nyx")
            return
        end

        if command == "ondate" then
            item = TxDateds::interactivelyCreateNewOrNull()
            return if item.nil?
            puts JSON.pretty_generate(item)
            return
        end

        if command == "ondates" then
            TxDateds::dive()
            return
        end

        if command == "pursue" then
            ns16 = object
            NxBallsService::pursue(ns16["uuid"])
            return
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

        if command == "start something" then
            uuid = SecureRandom.uuid
            description = LucilleCore::askQuestionAnswerAsString("description: ")
            universe = Multiverse::interactivelySelectUniverse()
            accounts = [UniverseAccounting::universeToAccountNumberOrNull(universe)].compact
            NxBallsService::issue(uuid, description, accounts)
            return
        end

        if command == "search" then
            Search::search()
            return
        end

        if command == "start" then
            ns16 = object
            universeAccountNumber = UniverseAccounting::universeToAccountNumberOrNull(ObjectUniverseMapping::getObjectUniverseMappingOrNull(ns16["uuid"]))
            NxBallsService::issue(ns16["uuid"], ns16["announce"], [ns16["uuid"], universeAccountNumber].compact)
            return
        end

        if command == "stop" then
            ns16 = object
            NxBallsService::close(ns16["uuid"], true)
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

        if command == "todos" then
            nx50s = TxTodos::items()
            if LucilleCore::askQuestionAnswerAsBoolean("limit ? ", true) then
                nx50s = nx50s.first(Utils::screenHeight()-2)
            end
            loop {
                nx50 = LucilleCore::selectEntityFromListOfEntitiesOrNull("nx50", nx50s, lambda {|nx50| TxTodos::toString(nx50) })
                return if nx50.nil?
                TxTodos::landing(nx50)
            }
            return
        end

        if command == "top" then
            Topping::top(StoredUniverse::getUniverseOrNull())
            return
        end

        if command == "transmute" then
            ns16 = object
            if ns16["mikuType"] == "NS16:Inbox1" then
                location = ns16["location"]
                Transmutation::transmutation2(location, "inbox")
                return
            end

            if ns16["mikuType"] == "NS16:TxDated" then
                mx49 = ns16["TxDated"]
                Transmutation::transmutation2(mx49, "TxDated")
                return
            end

            if ns16["mikuType"] == "NS16:TxFyre" then
                nx70 = ns16["TxFyre"]
                Transmutation::transmutation2(nx70, "TxFyre")
                return
            end

            if ns16["mikuType"] == "NS16:TxTodo" then
                nx70 = ns16["TxTodo"]
                Transmutation::transmutation2(nx70, "TxTodo")
                return
            end
        end

        if command == "universe" then
            ns16 = object
            if ns16["mikuType"] == "NS16:TxFyre" then
                item = ns16["TxFyre"]
                ObjectUniverseMapping::interactivelySetObjectUniverseMapping(item["uuid"])
                return
            end
            if ns16["mikuType"] == "NS16:TxFloat" then
                item = ns16["TxFloat"]
                ObjectUniverseMapping::interactivelySetObjectUniverseMapping(item["uuid"])
                return
            end
            if ns16["mikuType"] == "NS16:Wave" then
                item = ns16["wave"]
                ObjectUniverseMapping::interactivelySetObjectUniverseMapping(item["uuid"])
                return
            end
            if ns16["mikuType"] == "NS16:TxTodo" then
                item = ns16["TxTodo"]
                ObjectUniverseMapping::interactivelySetObjectUniverseMapping(item["uuid"])
                return
            end
        end

        if command == "wave" then
            item = Waves::issueNewWaveInteractivelyOrNull()
            return if item.nil?
            puts JSON.pretty_generate(item)
            return
        end

        if command == "waves" then
            Waves::waves()
            return
        end

        puts "I do not know how to do action (command: #{command}, object: #{JSON.pretty_generate(object)})"
        LucilleCore::pressEnterToContinue()
    end
end