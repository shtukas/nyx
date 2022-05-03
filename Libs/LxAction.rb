
class LxAction

    # LxAction::action(command, object or nil)
    def self.action(command, object)

        # All objects sent to this are expected to have an mikyType attribute

        return if command.nil?

        if object and object["mikuType"].nil? then
            puts "Objects sent to LxAction::action if not null should have a mikuType attribute."
            puts "Got:"
            puts "command: #{command}"
            puts "object:"
            puts JSON.pretty_generate(object)
            puts "Aborting."
            exit
        end

        if command == ".." then

            if object["mikuType"] == "NS16:TxFyre" then
                if !NxBallsService::isRunning(object["uuid"]) then
                    LxAction::action("start", object)
                end
                LxAction::action("access", object)
                if NxBallsService::isRunning(object["uuid"]) then
                    if !LucilleCore::askQuestionAnswerAsBoolean("continue ? ") then
                        LxAction::action("stop", object)
                    end
                end
                return
            end

            if object["mikuType"] == "NS16:TxTodo" then
                if !NxBallsService::isRunning(object["uuid"]) then
                    LxAction::action("start", object)
                end
                LxAction::action("access", object)
                if NxBallsService::isRunning(object["uuid"]) then
                    if LucilleCore::askQuestionAnswerAsBoolean("continue ? ") then
                        # Nothing else to do, we return
                    else
                        LxAction::action("stop", object)
                        if LucilleCore::askQuestionAnswerAsBoolean("done/destroy ? ") then
                            item = object["TxTodo"]
                            TxTodos::destroy(item["uuid"])
                        end
                    end
                end
                return
            end

            LxAction::action("access", object)
            return
        end

        if command == "[]" then
            Topping::applyTransformation(StoredUniverse::getUniverseOrNull())
            return
        end

        if command == ">nyx" then
            ns16 = object
            if ns16["mikuType"] == "NS16:Inbox1" then
                location = ns16["location"]
                puts "(711d6220-1970-44ff-b017-cc65bd8bdaad: This has not been implemented, need re-implementation after refactoring)"
                LucilleCore::pressEnterToContinue()
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

            if object["mikuType"] == "NS16:fitness1" then
                system("/Users/pascal/Galaxy/LucilleOS/Binaries/fitness doing #{object["fitness-domain"]}")
                return
            end

            if object["mikuType"] == "NS16:Inbox1" then
                Inbox::landingInbox1(object["location"])
                return
            end

            if object["mikuType"] == "NS16:TxInbox2" then
                Inbox::landingInbox2(object["item"])
                return
            end

            if object["mikuType"] == "NS16:TxDated" then
                item = object["TxDated"]
                Nx111::accessIamData_PossibleMutationInStorage_ExportsAreTx46Compatible(item)
                return
            end

            if object["mikuType"] == "NS16:TxFyre" then
                item = object["TxFyre"]
                Nx111::accessIamData_PossibleMutationInStorage_ExportsAreTx46Compatible(item)
                return
            end

            if object["mikuType"] == "NS16:TxFloat" then
                item = object["TxFloat"]
                Nx111::accessIamData_PossibleMutationInStorage_ExportsAreTx46Compatible(item)
                return
            end

            if object["mikuType"] == "NS16:TxTodo" then
                item = object["TxTodo"]
                Nx111::accessIamData_PossibleMutationInStorage_ExportsAreTx46Compatible(item)
                return
            end

            if object["mikuType"] == "NS16:Wave" then
                Waves::access(object["wave"])
                return
            end

            if object["mikuType"] == "TxTodo" then
                Nx111::accessIamData_PossibleMutationInStorage_ExportsAreTx46Compatible(object)
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
                LxAction::action("stop", object)
            end
            if object["mikuType"] == "NxBallNS16Delegate1" then
                NxBallsService::close(object["uuid"], true)
                return
            end
            if object["mikuType"] == "NS16:Anniversary1" then
                anniversary = object["anniversary"]
                Anniversaries::done(anniversary)
                return
            end
            if object["mikuType"] == "NS16:TxDated" then
                item = object["TxDated"]
                if LucilleCore::askQuestionAnswerAsBoolean("Confirm destruction of dated '#{item["description"].green}' ? ", true) then
                    TxDateds::destroy(item["uuid"])
                end
                return
            end
            if object["mikuType"] == "NS16:TxFyre" then
                puts "You cannot done a fyre from the main listing you need to land on them to do that"
                LucilleCore::pressEnterToContinue()
                return
            end
            if object["mikuType"] == "NS16:Inbox1" then
                location = object["location"]
                LucilleCore::removeFileSystemLocation(location)
                return
            end
            if object["mikuType"] == "NS16:TxInbox2" then
                item = object["item"]
                Librarian6ObjectsLocal::destroy(item["uuid"])
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
                if LucilleCore::askQuestionAnswerAsBoolean("Confirm destruction of todo '#{item["description"].green}' ? ", true) then
                    TxTodos::destroy(item["uuid"])
                end
                return
            end
            if object["mikuType"] == "NS16:Wave" then
                item = object["wave"]
                return if !LucilleCore::askQuestionAnswerAsBoolean("confirm done-ing '#{Waves::toString(item).green} ? '", true)
                Waves::performDone(item)
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

        if command == "fyres" then
            TxFyres::dive()
            return
        end

        if command == "fsck" then
            InfinityFileSystemCheck::fsckExitAtFirstFailure()
            return
        end

        if command == "inbox" then
            
            # This function creates a TxInbox2 object that is going to be dropped into the Inbox folder. 
            # Catalyst will know how to pick them up properly and how to present them

            line = LucilleCore::askQuestionAnswerAsString("line (empty to abort): ")
            return if line == ""
            aionrootnhash = nil
            location = Librarian0Utils::interactivelySelectDesktopLocationOrNull() 
            if location then
                aionrootnhash = AionCore::commitLocationReturnHash(Librarian3ElizabethXCache.new(), location)
            end

            item = {
                "uuid"          => SecureRandom.uuid,
                "mikuType"      => "TxInbox2",
                "unixtime"      => Time.new.to_i,
                "line"          => line,
                "aionrootnhash" => aionrootnhash
            }

            puts JSON.pretty_generate(item)

            Librarian6ObjectsLocal::commit(item)

            if location then
                LucilleCore::removeFileSystemLocation(location)
            end

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

            if object["mikuType"] == "NS16:Anniversary1" then
                Anniversaries::landing(object["anniversary"])
                return
            end

            if object["mikuType"] == "NS16:fitness1" then
                system("/Users/pascal/Galaxy/LucilleOS/Binaries/fitness doing #{object["fitness-domain"]}")
                return
            end

            if object["mikuType"] == "NS16:Inbox1" then
                Inbox::landingInbox1(object["location"])
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

            if object["mikuType"] == "NS16:Wave" then
                Waves::landing(object["wave"])
                return
            end

            if object["mikuType"] == "Nx100" then
                Nx100s::landing(object)
                return
            end

            if object["mikuType"] == "TxAttachment" then
                TxAttachments::landing(object)
                return
            end

            if object["mikuType"] == "TxFyre" then
                TxFyres::landing(object)
                return
            end

            if object["mikuType"] == "TxFloat" then
                TxFloats::landing(object)
                return
            end

            if object["mikuType"] == "TxTodo" then
                TxTodos::landing(object)
                return
            end

            if object["mikuType"] == "Wave" then
                Waves::landing(object)
                return
            end
        end

        if command == "librarian" then
            LibrarianCLI::main()
            return
        end

        if command == "nyx" then
            Nyx::program()
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

        if command == "pause" then
            ns16 = object
            NxBallsService::pause(ns16["uuid"])
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
                Librarian6ObjectsLocal::commit(mx49)
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
            NxBallsService::issue(uuid, description, [])
            return
        end

        if command == "search" then
            Search::classicInterface()
            return
        end

        if command == "start" then
            ns16 = object
            NxBallsService::issue(ns16["uuid"], ns16["announce"], [ns16["uuid"]])
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

        if command == "rstream" then
            TxTodos::rstream()
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
            StoredUniverse::interactivelySetUniverse()
            return
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