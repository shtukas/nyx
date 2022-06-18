
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

            if item["mikuType"] == "NxShip" then
                NxShip::doubleDot(item)
                return
            end

            if !NxBallsService::isRunning(item["uuid"]) then
                NxBallsService::issue(item["uuid"], LxFunction::function("toString", item), [item["uuid"]])
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

            if item["mikuType"] == "Wave" then
                if LucilleCore::askQuestionAnswerAsBoolean("'#{item["description"].green}' done ? ", true) then
                    Waves::performWaveNx46WaveDone(item)
                    NxBallsService::close(item["uuid"], true)
                end
            end

            return
        end

        if command == ">nyx" then
            if item["mikuType"] == "TxTodo" then
                Transmutation::transmutation1(item, "TxTodo", "NxDataNode")
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

            puts LxFunction::function("toString", item).green

            if item["lambda"] then
                item["lambda"].call()
                return
            end

            if item["mikuType"] == "NxAnniversary" then
                Anniversaries::access(item)
                return
            end

            if item["mikuType"] == "fitness1" then
                system("/Users/pascal/Galaxy/LucilleOS/Binaries/fitness doing #{item["fitness-domain"]}")
                return
            end

            if Iam::implementsNx111(item) then
                EditionDesk::accessItemNx111Pair(EditionDesk::pathToEditionDesk(), item, item["nx111"])
                return
            end

            if Iam::isNetworkAggregation(item) then
                CircleNavigation::navigate(item)
                return
            end
        end

        if command == "done" then

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
            if item["mikuType"] == "NxAnniversary" then
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
                TxTodos::done(item)
                return
            end
            if item["mikuType"] == "NxShip" then
                NxShip::done(item)
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

        if command == "exit" then
            exit
        end

        if command == "landing" then

            if item["mikuType"] == "Ax1Text" then
                Ax1Text::landing(item)
                return
            end
 
            if item["mikuType"] == "NxAnniversary" then
                Anniversaries::landing(item)
                return
            end
 
            if item["mikuType"] == "fitness1" then
                system("/Users/pascal/Galaxy/LucilleOS/Binaries/fitness doing #{item["fitness-domain"]}")
                return
            end

            Landing::landing(item)
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

        if command == "start" then
            NxBallsService::issue(item["uuid"], LxFunction::function("toString", item), [item["uuid"]])
            return
        end

        if command == "stop" then
            NxBallsService::close(item["uuid"], true)
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