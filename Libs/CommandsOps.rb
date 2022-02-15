
class Commands

    # Commands::terminalDisplayCommand()
    def self.terminalDisplayCommand()
        ".. | <datecode> | delay | expose | <n> | start | search | nyx"
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

    # CommandsOps::operator1(object, command)
    def self.operator1(object, command)

        return if object.nil?

        # puts "CommandsOps, object: #{object}, command: #{command}"

        if object["NS198"] == "NS16:Anniversary1" and command == ".." then
            Anniversaries::run(object["anniversary"])
        end

        if object["NS198"] == "NS16:Anniversary1" and command == "done" then
            anniversary = object["anniversary"]
            puts Anniversaries::toString(anniversary).green
            anniversary["lastCelebrationDate"] = Time.new.to_s[0, 10]
            Anniversaries::commitAnniversaryToDisk(anniversary)
        end

        if object["NS198"] == "NS16:TxCalendarItem" and command == ".." then
            TxCalendarItems::run(object["item"])
        end

        if object["NS198"] == "NS16:TxCalendarItem" and command == "done" then
            puts "`done` on NS16:TxCalendarItem has not been implemented yet"
        end

        if object["NS198"] == "NS16:fitness1" and command == ".." then
            system("/Users/pascal/Galaxy/LucilleOS/Binaries/fitness doing #{object["fitness-domain"]}")
        end

        if object["NS198"] == "NS16:Inbox1" and command == ".." then
            Inbox::run(object["location"])
        end

        if object["NS198"] == "NS16:Inbox1" and command == ">>" then
            location = object["location"]
            CommandsOps::transmutation2(location, "inbox")
        end

        if object["NS198"] == "NS16:TxDated" and command == ".." then
            TxDateds::run(object["TxDated"])
        end

        if object["NS198"] == "NS16:TxDated" and command == "done" then
            mx49 = object["TxDated"]
            TxDateds::destroy(mx49["uuid"])
        end

        if object["NS198"] == "NS16:TxDated" and command == "redate" then
            mx49 = object["TxDated"]
            datetime = (Utils::interactivelySelectAUTCIso8601DateTimeOrNull() || Time.new.utc.iso8601)
            mx49["datetime"] = datetime
            LibrarianObjects::commit(mx49)
        end

        if object["NS198"] == "NS16:TxDated" and command == ">>" then
            mx49 = object["TxDated"]
            CommandsOps::transmutation2(mx49, "TxDated")
        end

        if object["NS198"] == "NS16:TxDrop" and command == ".." then
            nx70 = object["TxDrop"]
            action = LucilleCore::selectEntityFromListOfEntitiesOrNull("action", ["run", "done"])
            return if action.nil?
            if action == "run" then
                TxDrops::run(nx70)
            end
            if action == "done" then
                TxDrops::destroy(nx70["uuid"])
            end
        end

        if object["NS198"] == "NS16:TxDrop" and command == "done" then
            nx70 = object["TxDrop"]
            TxDrops::destroy(nx70["uuid"])
        end

        if object["NS198"] == "NS16:TxDrop" and command == ">>" then
            nx70 = object["TxDrop"]
            CommandsOps::transmutation2(nx70, "TxDrop")
        end

        if object["NS198"] == "NS16:TxFloat" and command == ".." then
            TxFloats::run(object["TxFloat"])
        end

        if object["NS198"] == "NS16:TxTodo" and command == ".." then
            TxTodos::run(object["TxTodo"])
        end

        if object["NS198"] == "NS16:TxTodo" and command == "done" then
            nx50 = object["TxTodo"]
            if LucilleCore::askQuestionAnswerAsBoolean("destroy '#{TxTodos::toString(nx50)}' ? ", true) then
                TxTodos::destroy(nx50["uuid"])
                CommandsOps::closeAnyNxBallWithThisID(object["uuid"])
            end
        end

        if object["NS198"] == "NS16:Wave" and command == ".." then
            Waves::run(object["wave"])
        end

        if object["NS198"] == "NS16:Wave" and command == "landing" then
            Waves::landing(object["wave"])
        end

        if object["NS198"] == "NS16:Wave" and command == "done" then
            Waves::performDone(object["wave"])
            CommandsOps::closeAnyNxBallWithThisID(object["uuid"])
        end

        if object["NS198"] == "NxBallDelegate1" and command == ".." then
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
        end

        if object["NS198"] == "NxBallDelegate1" and command == "done" then
            uuid = object["NxBallUUID"]
            NxBallsService::close(uuid, true)
        end

        if Interpreting::match("require internet", command) then
            InternetStatus::markIdAsRequiringInternet(object["uuid"])
        end
    end

    # CommandsOps::operator4(command)
    def self.operator4(command)

        if command == "[]" then
            Topping::applyTransformation()
        end

        if command == "top" then
            Topping::top()
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

        if Interpreting::match("ondate", command) then
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

        if Interpreting::match("wave", command) then
            item = Waves::issueNewWaveInteractivelyOrNull()
            return if item.nil?
            puts JSON.pretty_generate(item)
        end

        if Interpreting::match("anniversary", command) then
            item = Anniversaries::issueNewAnniversaryOrNullInteractively()
            return if item.nil?
            puts JSON.pretty_generate(item)
        end

        if Interpreting::match("anniversaries", command) then
            Anniversaries::anniversariesDive()
        end

        if Interpreting::match("waves", command) then
            Waves::waves()
        end

        if Interpreting::match("ondates", command) then
            TxDateds::dive()
        end

        if Interpreting::match("todos", command) then
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

        if Interpreting::match("search", command) then
            Search::search()
        end

        if Interpreting::match("calendaritem", command) then
            TxCalendarItems::interactivelyCreateNewOrNull()
        end

        if Interpreting::match("calendar", command) then
            TxCalendarItems::dive()
        end

        if Interpreting::match("nyx", command) then
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

        if Interpreting::match("internet on", command) then
            InternetStatus::setInternetOn()
        end

        if Interpreting::match("internet off", command) then
            InternetStatus::setInternetOff()
        end

        if Interpreting::match("rotate", command) then
            PersonalAssistant::rotate()
        end

        if Interpreting::match("exit", command) then
            exit
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
            domainx = TxTodos::interactivelySelectDomainX()
            ordinal = TxTodos::interactivelyDecideNewOrdinal(domainx)
            object["ordinal"] = ordinal
            object["domainx"] = domainx
            object["mikuType"] = "TxTodo"
            LibrarianObjects::commit(object)
            return
        end

        if source == "TxDated" and target == "TxDrop" then
            object["mikuType"] = "TxDrop"
            LibrarianObjects::commit(object)
            return
        end

        if source == "TxDrop" and target == "TxTodo" then
            domainx = TxTodos::interactivelySelectDomainX()
            ordinal = TxTodos::interactivelyDecideNewOrdinal(domainx)
            object["ordinal"] = ordinal
            object["domainx"] = domainx
            object["mikuType"] = "TxTodo"
            LibrarianObjects::commit(object)
            return
        end

        if source == "TxFloat" and target == "TxTodo" then
            domainx = TxTodos::interactivelySelectDomainX()
            ordinal = TxTodos::interactivelyDecideNewOrdinal(domainx)
            object["ordinal"] = ordinal
            object["domainx"] = domainx
            object["mikuType"] = "TxTodo"
            LibrarianObjects::commit(object)
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
end
