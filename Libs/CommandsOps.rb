
class CommandsOps

    # CommandsOps::closeAnyNxBallWithThisID(uuid)
    def self.closeAnyNxBallWithThisID(uuid)
        NxBallsService::close(uuid, true)
    end

    # CommandsOps::operator1(object, command)
    def self.operator1(object, command)

        return if object.nil?

        # puts "CommandsOps, object: #{object}, command: #{command}"

        if object["NS198"] == "NxBallDelegate1" and command == ".." then
            uuid = object["uuid"]

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

        if object["NS198"] == "ns16:fitness1" and command == ".." then
            system("/Users/pascal/Galaxy/LucilleOS/Binaries/fitness doing #{object["fitness-domain"]}")
        end

        if object["NS198"] == "ns16:Mx48" and command == ".." then
            Mx48s::run(object["Mx48"])
        end

        if object["NS198"] == "ns16:wave1" and command == ".." then
            Waves::run(object["wave"])
        end

        if object["NS198"] == "ns16:wave1" and command == "landing" then
            Waves::landing(object["wave"])
        end

        if object["NS198"] == "ns16:wave1" and command == "done" then
            Waves::performDone(object["wave"])
            CommandsOps::closeAnyNxBallWithThisID(object["uuid"])
        end

        if object["NS198"] == "ns16:inbox1" and command == ".." then
            Inbox::run(object["location"])
        end

        if object["NS198"] == "ns16:inbox1" and command == ">>" then
            location = object["location"]
            CommandsOps::transmutation({
                "type"     => "inbox-transmutation",
                "location" => location
            })
        end

        if object["NS198"] == "ns16:Nx50" and command == ".." then
            Nx50s::run(object["Nx50"])
        end

        if object["NS198"] == "ns16:Mx49" and command == ".." then
            Mx49s::run(object["Mx49"])
        end

        if object["NS198"] == "ns16:Mx49" and command == "done" then
            mx49 = object["Mx49"]
            Mx49s::destroy(mx49["uuid"])
        end

        if object["NS198"] == "ns16:Mx49" and command == "redate" then
            mx49 = object["Mx49"]
            mx49["datetime"] = (Utils::interactivelySelectAUTCIso8601DateTimeOrNull() || Time.new.utc.iso8601)
            Mx49s::commit(mx49)
        end

        if object["NS198"] == "ns16:Mx49" and command == ">>" then
            mx49 = object["Mx49"]
            CommandsOps::transmutation({
                "type" => "mx49-dated-transmutation",
                "mx49" => mx49
            })
        end

        if object["NS198"] == "ns16:Nx50" and command == "done" then
            nx50 = object["Nx50"]
            if LucilleCore::askQuestionAnswerAsBoolean("destroy '#{Nx50s::toString(nx50)}' ? ", true) then
                Nx50s::destroy(nx50["uuid"])
                CommandsOps::closeAnyNxBallWithThisID(object["uuid"])
            end
        end

        if object["NS198"] == "ns16:Mx51" and command == ".." then
            Mx51s::run(object["Mx51"])
        end

        if object["NS198"] == "ns16:Mx51" and command == "done" then
            mx51 = object["Mx51"]
            if LucilleCore::askQuestionAnswerAsBoolean("destroy '#{Mx51s::toString(mx51)}' ? ", true) then
                Mx51s::destroy(mx51["uuid"])
                CommandsOps::closeAnyNxBallWithThisID(object["uuid"])
            end
        end

        if object["NS198"] == "ns16:Mx51" and command == ">>" then
            mx51 = object["Mx51"]
            CommandsOps::transmutation({
                "type" => "mx51-work-item-transmutation",
                "mx51" => mx51
            })
        end

        if object["NS198"] == "ns16:anniversary1" and command == ".." then
            Anniversaries::run(object["anniversary"])
        end

        if object["NS198"] == "ns16:anniversary1" and command == "done" then
            anniversary = object["anniversary"]
            puts Anniversaries::toString(anniversary).green
            anniversary["lastCelebrationDate"] = Time.new.to_s[0, 10]
            Anniversaries::commitAnniversaryToDisk(anniversary)
        end

        if object["NS198"] == "ns16:calendar1" and command == ".." then
            Calendar::run(object["item"])
        end

        if object["NS198"] == "ns16:calendar1" and command == "done" then
            Calendar::moveToArchives(object["item"])
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
            NxBallsService::issue(SecureRandom.uuid, description, [])
        end

        if command == "monitor" then
            Mx48s::interactivelyCreateNewOrNull()
        end

        if Interpreting::match("ondate", command) then
            item = Mx49s::interactivelyCreateNewOrNull()
            return if item.nil?
            puts JSON.pretty_generate(item)
        end

        if command == "today" then
            mx49 = Mx49s::interactivelyCreateNewTodayOrNull()
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

        if Interpreting::match("work on", command) then
            instruction = {
                "mode"       => "work-on",
                "expiryTime" => Time.new.to_i + 3600*2
            }
            KeyValueStore::set(nil, "dcef329c-a1eb-4fc5-b151-e94460fe280c", JSON.generate(instruction))
        end

        if Interpreting::match("work off", command) then
            instruction = {
                "mode"       => "work-off",
                "expiryTime" => Time.new.to_i + 3600*2
            }
            KeyValueStore::set(nil, "dcef329c-a1eb-4fc5-b151-e94460fe280c", JSON.generate(instruction))
        end

    end

    # CommandsOps::transmutation(object)
    def self.transmutation(object)

        if object["type"] == "inbox-transmutation" then
            location = object["location"]
            action = LucilleCore::selectEntityFromListOfEntitiesOrNull("action", ["dispatch to Nx50s", "dispatch to work Mx51s"])
            if action == "dispatch to Nx50s" then
                Nx50s::issueItemUsingInboxLocation(location)
                LucilleCore::removeFileSystemLocation(location)
            end
            if action == "dispatch to work Mx51s" then
                Mx51s::issueItemUsingInboxLocation(location)
                LucilleCore::removeFileSystemLocation(location)
            end
        end

        if object["type"] == "mx49-dated-transmutation" then
            mx49 = object["mx49"]
            puts "We are currently defaulting to sending Mx49/dated to Nx50, you can modify the code to change that"
            LucilleCore::pressEnterToContinue()
            nx50 = mx49.clone
            nx50["uuid"] = SecureRandom.uuid
            nx50["ordinal"] = Nx50s::ordinalBetweenN1thAndN2th(20, 30)
            Nx50s::commit(nx50)
            Mx49s::destroy(mx49["uuid"])
        end

        if object["type"] == "Nx50-transmutation" then
            nx50 = object["nx50"]
            puts "We are currently defaulting to sending Nx50 to Mx51/work-item, you can modify the code to change that"
            LucilleCore::pressEnterToContinue()
            mx51 = nx50.clone
            mx51["uuid"] = SecureRandom.uuid
            mx51["ordinal"] = Mx51s::interactivelyDecideNewOrdinal()
            Mx51s::commit(mx51)
            Nx50s::destroy(nx50["uuid"])
        end

        if object["type"] == "mx51-work-item-transmutation" then
            mx51 = object["mx51"]
            puts "We are currently defaulting to sending Mx51/work-item to Nx50, you can modify the code to change that"
            LucilleCore::pressEnterToContinue()
            nx50 = mx51.clone
            nx50["uuid"] = SecureRandom.uuid
            nx50["ordinal"] = Nx50s::ordinalBetweenN1thAndN2th(20, 30)
            Nx50s::commit(nx50)
            Mx51s::destroy(mx51["uuid"])
        end
    end
end
