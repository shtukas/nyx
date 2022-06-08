
class LxAction

    # LxAction::action(command, item or nil, options = nil)
    def self.action(command, item = nil, options = nil)

        # All items sent to this are expected to have an mikyType attribute

        return if command.nil?

        if item and item["mikuType"].nil? then
            puts "Objects sent to LxAction::action if not null should have a mikuType attribute."
            puts "Got:"
            puts "command: #{command}"
            puts "item:"
            puts JSON.pretty_generate(item)
            puts "Aborting."
            exit
        end

        if command == ".." then

            if !NxBallsService::isRunning(item["uuid"]) then
                NxBallsService::issue(item["uuid"], item["announce"] ? item["announce"] : "(item: #{item["uuid"]})" , [item["uuid"]])
            end

            LxAction::action("access", item)

            if item["mikuType"] == "fitness1" then
                NxBallsService::close(item["uuid"], true)
            end

            if item["mikuType"] == "TxDated" and item["description"].include?("(vienna)") then
                if LucilleCore::askQuestionAnswerAsBoolean("destroy ? : ", true) then
                    TxDateds::destroy(item["uuid"])
                    NxBallsService::close(item["uuid"], true)
                end
            end

            if item["mikuType"] == "TxTodo" then
                if LucilleCore::askQuestionAnswerAsBoolean("destroy ? ") then
                    TxTodos::destroy(item["uuid"])
                    NxBallsService::close(item["uuid"], true)
                end
            end

            if item["mikuType"] == "Wave" then
                if LucilleCore::askQuestionAnswerAsBoolean("done ? ", true) then
                    Waves::performWaveNx46WaveDone(item)
                    NxBallsService::close(item["uuid"], true)
                end
            end

            return
        end

        if command == ">nyx" then
            if item["mikuType"] == "TxTodo" then
                Transmutation::transmutation1(item, "TxTodo", "Nx100")
                return
            end
        end

        if command == ">todo" then
            if item["mikuType"] == "TxDated" then
                Transmutation::transmutation1(item, "TxDated", "TxTodo")
                return
            end
        end

        if command == "access" then

            if item["lambda"] then
                item["lambda"].call()
                return
            end

            if item["i1as"] then
                EditionDesk::accessItemWithI1asAttribute(item)
                return
            end

            if item["mikuType"] == "Anniversary" then
                Anniversaries::access(item)
                return
            end

            if item["mikuType"] == "fitness1" then
                system("/Users/pascal/Galaxy/LucilleOS/Binaries/fitness doing #{item["fitness-domain"]}")
                return
            end

            if item["mikuType"] == "Wave" then
                EditionDesk::accessItemWithOneNx111Attribute(item, "nx111")
                return
            end

            if item["mikuType"] == "TxDated" then
                EditionDesk::accessItemWithI1asAttribute(item)
                return
            end

            if item["mikuType"] == "TxFloat" then
                EditionDesk::accessItemWithI1asAttribute(item)
                return
            end

            if item["mikuType"] == "TxTodo" then
                EditionDesk::accessItemWithI1asAttribute(item)
                return
            end

            if item["mikuType"] == "Wave" then
                EditionDesk::accessItemWithI1asAttribute(item)
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

        if command == "done" then

            Mercury::postValue("b6156390-059d-446e-ad51-adfc9f91abf1", item["uuid"])

            # If the item was running, then we stop it
            if NxBallsService::isRunning(item["uuid"]) then
                 NxBallsService::close(item["uuid"], true)
            end

            if item["mikuType"] == "(rstream)" then
                # That's the rstream
                return
            end

            if item["mikuType"] == "NxBall.v2" then
                NxBallsService::close(item["uuid"], true)
                return
            end
            if item["mikuType"] == "Anniversary" then
                Anniversaries::done(item)
                return
            end
            if item["mikuType"] == "TxDated" then
                shouldForce = options and options["forcedone"]
                if shouldForce then
                    TxDateds::destroy(item["uuid"])
                    return
                end
                if LucilleCore::askQuestionAnswerAsBoolean("Confirm destruction of dated '#{item["description"].green}' ? ", true) then
                    TxDateds::destroy(item["uuid"])
                end
                return
            end
            if item["mikuType"] == "TxTodo" then
                shouldForce = options and options["forcedone"]
                if shouldForce then
                    TxTodos::destroy(item["uuid"])
                    return
                end
                if LucilleCore::askQuestionAnswerAsBoolean("Confirm destruction of todo '#{item["description"].green}' ? ", true) then
                    TxTodos::destroy(item["uuid"])
                end
                return
            end

            if item["mikuType"] == "Wave" then
                shouldForce = options and options["forcedone"]
                if shouldForce then
                    Waves::performWaveNx46WaveDone(item)
                    return
                end
                if LucilleCore::askQuestionAnswerAsBoolean("confirm done-ing '#{Waves::toString(item).green} ? '", true) then
                    Waves::performWaveNx46WaveDone(item)
                end
                return
            end
        end

        if command == "expose" then
            puts JSON.pretty_generate(item)
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

        if command == "internet on" then
            InternetStatus::setInternetOn()
            return
        end

        if command == "internet off" then
            InternetStatus::setInternetOff()
            return
        end

        if command == "landing" then

            if item["mikuType"] == "Ax1Text" then
                Ax1Text::landing(item)
                return
            end

            if item["mikuType"] == "Anniversary" then
                Anniversaries::landing(item)
                return
            end

            if item["mikuType"] == "fitness1" then
                system("/Users/pascal/Galaxy/LucilleOS/Binaries/fitness doing #{item["fitness-domain"]}")
                return
            end

            if item["mikuType"] == "NxTimeline" then
                NxTimelines::landing(item)
                return
            end

            if item["mikuType"] == "Nx100" then
                Nx100s::landing(item)
                return
            end

            if item["mikuType"] == "Wave" then
                Waves::landing(item)
                return
            end

            if item["mikuType"] == "TxDated" then
                TxDateds::landing(item)
                return
            end

            if item["mikuType"] == "TxFloat" then
                TxFloats::landing(item)
                return
            end

            if item["mikuType"] == "TxTodo" then
                TxTodos::landing(item)
                return
            end

            if item["mikuType"] == "Wave" then
                Waves::landing(item)
                return
            end
        end

        if command == "nyx" then
            puts "(info: 4B14BAB4-7414-4090-982D-29C218EB5408) command nyx: to be written, call the executable"
            exit
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
            NxBallsService::pause(item["uuid"])
            return
        end

        if command == "pursue" then
            NxBallsService::pursue(item["uuid"])
            return
        end

        if command == "redate" then
            if item["mikuType"] == "TxDated" then
                datetime = (CommonUtils::interactivelySelectAUTCIso8601DateTimeOrNull() || Time.new.utc.iso8601)
                item["datetime"] = datetime
                Librarian::commit(item)
                return
            end
        end

        if command == "require internet" then
            InternetStatus::markIdAsRequiringInternet(item["uuid"])
            return
        end

        if command == "search" then
            Search::classicInterface()
            return
        end

        if command == "start" then
            NxBallsService::issue(item["uuid"], LxFunction::function("toString", item), [item["uuid"]])
            return
        end

        if command == "stop" then
            NxBallsService::close(item["uuid"], true)
            return
        end

        if command == "time" and item["mikuType"] == "TimeInstructionAdd" then
            payload = item["payload"]
            timeInHours = item["timeInHours"]

            if payload["mikuType"] == "TxTodo" then
                puts "Adding #{timeInHours} hours to #{payload["uuid"]}"
                Bank::put(payload["uuid"], timeInHours*3600)
                return
            end
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
            Streaming::rstream()
            return
        end

        if command == "transmute" then
            if item["mikuType"] == "TxDated" then
                Transmutation::transmutation2(item, "TxDated")
                return
            end

            if item["mikuType"] == "TxTodo" then
                Transmutation::transmutation2(item, "TxTodo")
                return
            end
        end

        if command == "wave" then
            item = Waves::issueNewWaveInteractivelyOrNull()
            return if item.nil?
            puts JSON.pretty_generate(item)
            return
        end

        puts "I do not know how to do action (command: #{command}, item: #{JSON.pretty_generate(item)})"
        LucilleCore::pressEnterToContinue()
    end
end