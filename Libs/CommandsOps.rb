
class Commands

    # Commands::terminalDisplayCommand()
    def self.terminalDisplayCommand()
        ".. | <n> | <datecode> | expose"
    end

    # Commands::makersCommands()
    def self.makersCommands()
        "wave | anniversary | float | spaceship | drop | today | ondate | todo"
    end

    # Commands::diversCommands()
    def self.diversCommands()
        "calendar | waves | anniversaries | ondates | todos | focus eva/work/null  | search | nyx"
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

        if object["NS198"] == "NS16:Calendar1" and command == ".." then
            Calendar::run(object["item"])
        end

        if object["NS198"] == "NS16:Calendar1" and command == "done" then
            Calendar::moveToArchives(object["item"])
        end

        if object["NS198"] == "NS16:CatalystTxt" and command == ".." then
            line = object["line"]
            action = LucilleCore::selectEntityFromListOfEntitiesOrNull("action", ["start", "done"])
            return if action.nil?
            if action == "start" then
                account = DomainsX::selectAccount()
                NxBallsService::issue(SecureRandom.uuid, line, [account])
            end
            if action == "done" then
                CatalystTxt::rewriteCatalystTxtFileWithoutThisLine(line)
            end
        end

        if object["NS198"] == "NS16:CatalystTxt" and command == "done" then
            Utils::copyFileToBinTimeline("/Users/pascal/Desktop/Catalyst.txt")
            CatalystTxt::rewriteCatalystTxtFileWithoutThisLine(object["line"])
        end

        if object["NS198"] == "NS16:CatalystTxt" and command == "''" then
            line = object["line"]
            ItemStoreOps::delistForDefault(CatalystTxt::lineToUuid(line))
        end

        if object["NS198"] == "NS16:Fitness1" and command == ".." then
            system("/Users/pascal/Galaxy/LucilleOS/Binaries/fitness doing #{object["fitness-domain"]}")
        end

        if object["NS198"] == "NS16:Inbox1" and command == ".." then
            Inbox::run(object["location"])
        end

        if object["NS198"] == "NS16:Inbox1" and command == ">>" then
            location = object["location"]
            CommandsOps::transmutation2(location, "inbox")
        end

        if object["NS198"] == "NS16:TxFloat" and command == ".." then
            TxFloats::run(object["TxFloat"])
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
            mx49["datetime"] = (Utils::interactivelySelectAUTCIso8601DateTimeOrNull() || Time.new.utc.iso8601)
            TxDateds::commit(mx49)
        end

        if object["NS198"] == "NS16:TxDated" and command == ">>" then
            mx49 = object["TxDated"]
            CommandsOps::transmutation2(mx49, "TxDated")
        end

        if object["NS198"] == "NS16:TxDated" and command == "''" then
            mx49 = object["TxDated"]
            ItemStoreOps::delistForDefault(mx49["uuid"])
        end

        if object["NS198"] == "NS16:Mx51" and command == ".." then
            Mx51s::run(object["Mx51"])
        end

        if object["NS198"] == "NS16:Mx51" and command == "done" then
            mx51 = object["Mx51"]
            if LucilleCore::askQuestionAnswerAsBoolean("destroy '#{Mx51s::toString(mx51)}' ? ", true) then
                Mx51s::destroy(mx51["uuid"])
                CommandsOps::closeAnyNxBallWithThisID(object["uuid"])
            end
        end

        if object["NS198"] == "NS16:Mx51" and command == ">>" then
            mx51 = object["Mx51"]
            CommandsOps::transmutation2(mx51, "Mx51")
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

        if object["NS198"] == "NS16:Nx50" and command == ".." then
            Nx50s::run(object["Nx50"])
        end

        if object["NS198"] == "NS16:Nx50" and command == "done" then
            nx50 = object["Nx50"]
            if LucilleCore::askQuestionAnswerAsBoolean("destroy '#{Nx50s::toString(nx50)}' ? ", true) then
                Nx50s::destroy(nx50["uuid"])
                CommandsOps::closeAnyNxBallWithThisID(object["uuid"])
            end
        end

        if object["NS198"] == "NS16:Nx60" and command == ".." then
            nx60 = object["Nx60"]
            Nx60s::run(nx60)
        end

        if object["NS198"] == "NS16:Nx60" and command == "''" then
            nx60 = object["Nx60"]
            ItemStoreOps::delistForDefault(nx60["uuid"])
        end

        if object["NS198"] == "NS16:Nx60" and command == ">>" then
            nx60 = object["Nx60"]
            CommandsOps::transmutation2(nx60, "Nx60")
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

        if object["NS198"] == "NS16:TxDrop" and command == "''" then
            nx70 = object["TxDrop"]
            ItemStoreOps::delistForDefault(nx70["uuid"])
        end

        if object["NS198"] == "NS16:TxDrop" and command == ">>" then
            nx70 = object["TxDrop"]
            CommandsOps::transmutation2(nx70, "TxDrop")
        end

        if object["NS198"] == "NS16:Wave1" and command == ".." then
            Waves::run(object["wave"])
        end

        if object["NS198"] == "NS16:Wave1" and command == "landing" then
            Waves::landing(object["wave"])
        end

        if object["NS198"] == "NS16:Wave1" and command == "done" then
            Waves::performDone(object["wave"])
            CommandsOps::closeAnyNxBallWithThisID(object["uuid"])
        end

        if Interpreting::match("require internet", command) then
            InternetStatus::markIdAsRequiringInternet(object["uuid"])
        end
    end

    # CommandsOps::operator4(command)
    def self.operator4(command)

        if command == "start" then
            description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
            return if description == ""
            account = DomainsX::selectAccount()
            NxBallsService::issue(SecureRandom.uuid, description, [account])
        end

        if command == "float" then
            TxFloats::interactivelyCreateNewOrNull()
        end

        if command == "spaceship" then
            Nx60s::interactivelyCreateNewOrNull()
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
            type = LucilleCore::selectEntityFromListOfEntitiesOrNull("type", ["Nx50", "Nx51 (work item)"])
            if type == "Nx50" then
                item = Nx50s::interactivelyCreateNewOrNull()
                return if item.nil?
                puts JSON.pretty_generate(item)
            end
            if type == "Nx51 (work item)" then
                item = Mx51s::interactivelyCreateNewOrNull()
                return if item.nil?
                puts JSON.pretty_generate(item)
            end
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

        if Interpreting::match("calendar", command) then
            Calendar::main()
        end

        if Interpreting::match("waves", command) then
            Waves::waves()
        end

        if Interpreting::match("todos", command) then
            type = LucilleCore::selectEntityFromListOfEntitiesOrNull("type", ["Nx50s", "Nx51s (work items)"])
            if type == "Nx50s" then
                nx50s = Nx50s::nx50s()
                if LucilleCore::askQuestionAnswerAsBoolean("limit ? ", true) then
                    nx50s = nx50s.first(Utils::screenHeight()-2)
                end
                loop {
                    nx50 = LucilleCore::selectEntityFromListOfEntitiesOrNull("nx50", nx50s, lambda {|nx50| Nx50s::toString(nx50) })
                    return if nx50.nil?
                    Nx50s::run(nx50)
                }
            end
            if type == "Nx51s (work items)" then
                mx51s = Mx51s::items()
                if LucilleCore::askQuestionAnswerAsBoolean("limit ? ", true) then
                    mx51s = mx51s.first(Utils::screenHeight()-2)
                end
                loop {
                    mx51 = LucilleCore::selectEntityFromListOfEntitiesOrNull("mx51", mx51s, lambda {|mx51| Mx51s::toString(mx51) })
                    return if mx51.nil?
                    Mx51s::run(mx51)
                }
            end

        end

        if Interpreting::match("search", command) then
            Search::search()
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

        if Interpreting::match("focus eva", command) then
            KeyValueStore::set(nil, "c68fc8de-81fd-4e76-b995-e171d0374661:#{Utils::today()}", "eva")
        end

        if Interpreting::match("focus work", command) then
            KeyValueStore::set(nil, "c68fc8de-81fd-4e76-b995-e171d0374661:#{Utils::today()}", "work")
        end

        if Interpreting::match("focus null", command) then
            KeyValueStore::destroy(nil, "c68fc8de-81fd-4e76-b995-e171d0374661:#{Utils::today()}")
        end

        if Interpreting::match("exit", command) then
            exit
        end
    end

    # CommandsOps::transmutation1(object, source, target)
    # source: "TxDated" (dated) | "Nx50" | "Mx51" | "TxFloat" (float) | "inbox"
    # target: "TxDated" (dated) | "Nx50" | "Mx51" | "TxFloat" (float)
    def self.transmutation1(object, source, target)

        if source == "inbox" and target == "Nx50" then
            location = object
            description = Inbox::interactivelyDecideBestDescriptionForLocation(location)
            ordinal = Nx50s::interactivelyDecideNewOrdinal()
            atom = CoreData5::issueAionPointAtomUsingLocation(location)
            nx50 = {
                "uuid"        => SecureRandom.uuid,
                "unixtime"    => Time.new.to_i,
                "ordinal"     => ordinal,
                "description" => description,
                "atom"        => atom
            }
            Nx50s::commit(nx50)
            LucilleCore::removeFileSystemLocation(location)
            return
        end

        if source == "inbox" and target == "Mx51" then
            location = object
            description = Inbox::interactivelyDecideBestDescriptionForLocation(location)
            ordinal = Mx51s::interactivelyDecideNewOrdinal()
            atom = CoreData5::issueAionPointAtomUsingLocation(location)
            mx51 = {
                "uuid"        => SecureRandom.uuid,
                "unixtime"    => Time.new.to_i,
                "ordinal"     => ordinal,
                "description" => description,
                "atom"        => atom
            }
            Mx51s::commit(mx51)
            LucilleCore::removeFileSystemLocation(location)
            return
        end

        if source == "TxDated" and target == "Nx50" then
            mx49 = object
            ordinal = Nx50s::interactivelyDecideNewOrdinal()
            nx50 = {
                "uuid"        => SecureRandom.uuid,
                "unixtime"    => Time.new.to_i,
                "ordinal"     => ordinal,
                "description" => mx49["description"],
                "atom"        => mx49["atom"]
            }
            Nx50s::commit(nx50)
            TxDateds::destroy(mx49["uuid"])
            return
        end

        if source == "TxDated" and target == "Nx60" then
            mx49 = object
            domainx = DomainsX::interactivelySelectDomainX()
            nx60 = {
                "uuid"        => SecureRandom.uuid,
                "unixtime"    => Time.new.to_i,
                "description" => mx49["description"],
                "atom"        => mx49["atom"],
                "domainx"     => domainx
            }
            Nx60s::commit(nx60)
            TxDateds::destroy(mx49["uuid"])
            return
        end

        if source == "TxDated" and target == "TxDrop" then
            mx49 = object
            nx70 = {
                "uuid"        => SecureRandom.uuid,
                "unixtime"    => Time.new.to_i,
                "description" => mx49["description"],
                "atom"        => mx49["atom"],
                "domainx"     => mx49["domainx"]
            }
            TxDrops::commit(nx70)
            TxDateds::destroy(mx49["uuid"])
            return
        end

        if source == "Mx51" and target == "TxFloat" then
            newItem = {
                "uuid"        => SecureRandom.uuid,
                "unixtime"    => Time.new.to_i,
                "description" => object["description"],
                "atom"        => object["atom"],
                "domainx"     => "work"
            }
            TxFloats::commit(newItem)
            Mx51s::destroy(object["uuid"])
            return
        end

        if source == "Nx60" and target == "TxFloat" then
            nx60 = object
            mx48 = {
                "uuid"        => SecureRandom.uuid,
                "unixtime"    => Time.new.to_i,
                "description" => nx60["description"],
                "atom"        => nx60["atom"],
                "domainx"     => nx60["domainx"]
            }
            TxFloats::commit(mx48)
            Nx60s::destroy(nx60["uuid"])
            return
        end

        if source == "Nx60" and target == "TxDated" then
            nx60 = object
            datetime = Utils::interactivelySelectAUTCIso8601DateTimeOrNull()
            mx49 = {
                "uuid"        => SecureRandom.uuid,
                "unixtime"    => Time.new.to_i,
                "description" => nx60["description"],
                "datetime"    => datetime,
                "atom"        => nx60["atom"],
                "domainx"     => nx60["domainx"]
            }
            TxDateds::commit(mx49)
            Nx60s::destroy(nx60["uuid"])
            return
        end

        if source == "TxDrop" and target == "Mx51" then
            ordinal = Mx51s::interactivelyDecideNewOrdinal()
            mx51 = {
                "uuid"        => SecureRandom.uuid,
                "unixtime"    => Time.new.to_i,
                "ordinal"     => ordinal,
                "description" => object["description"],
                "atom"        => object["atom"]
            }
            Mx51s::commit(mx51)
            TxDrops::destroy(object["uuid"])
            return
        end

        puts "I do not yet know how to transmute from '#{source}' to '#{target}'"
        LucilleCore::pressEnterToContinue()
    end

    # CommandsOps::interactivelyGetTransmutationTargetOrNull()
    def self.interactivelyGetTransmutationTargetOrNull()
        options = ["TxFloat", "TxDated", "Nx60", "Nx50", "Mx51", ]
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
