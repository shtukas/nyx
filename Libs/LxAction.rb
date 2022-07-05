
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

            # Special circumstances

            if item["mikuType"] == "TxQueue" then
                task = TxQueues::getFirstTaskOrNull(item)
                return if task.nil?
                LxAction::action("start", task)
                return
            end

            # Stardard starting of the item

            LxAction::action("start", item)

            # Stardard access

            LxAction::action("access", item)

            # Dedicated post access (otherwise we carry on running)

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
            NxBallsService::close(item["uuid"], true)
            Transmutation::transmutation1(item, item["mikuType"], "NxDataNode")
            return
        end

        if command == "access" then

            puts LxFunction::function("toString", item).green

            if item["mikuType"] == "fitness1" then
                system("/Users/pascal/Galaxy/LucilleOS/Binaries/fitness doing #{item["fitness-domain"]}")
                return
            end

            if item["mikuType"] == "(rstream)" then
                Streaming::rstream()
                return
            end


            if item["mikuType"] == "NxAnniversary" then
                Anniversaries::access(item)
                return
            end

            if item["mikuType"] == "NxBall.v2" then
                if NxBallsService::isRunning(item["uuid"]) then
                    if LucilleCore::askQuestionAnswerAsBoolean("complete '#{LxFunction::function("toString", item).green}' ? ") then
                        NxBallsService::close(item["uuid"], true)
                    end
                end
                return
            end

            if item["mikuType"] == "NxOrdinal" then
                if LucilleCore::askQuestionAnswerAsBoolean("destroy '#{LxFunction::function("toString", item).green}' ? ") then
                    Librarian::destroyClique(item["uuid"])
                end
                return
            end

            if item["mikuType"] == "TxQueue" then
                TxQueues::diving(item)
                return
            end

            if Iam::implementsNx111(item) then
                EditionDesk::accessItemNx111Pair(EditionDesk::pathToEditionDesk(), item, item["nx111"])
                return
            end

            if Iam::isNetworkAggregation(item) then
                RelatedNavigation::navigate(item)
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

            if item["mikuType"] == "NxAnniversary" then
                Anniversaries::done(item)
                return
            end

            if item["mikuType"] == "NxBall.v2" then
                NxBallsService::close(item["uuid"], true)
                return
            end

            if item["mikuType"] == "NxTask" then
                if LucilleCore::askQuestionAnswerAsBoolean("destroy NxTask '#{LxFunction::function("toString", item).green}' ? ") then
                    Librarian::destroyClique(item["uuid"])
                end
                return
            end

            if item["mikuType"] == "NxOrdinal" then
                if LucilleCore::askQuestionAnswerAsBoolean("destroy NxOrdinal '#{LxFunction::function("toString", item).green}' ? ") then
                    Librarian::destroyClique(item["uuid"])
                end
                return
            end

            if item["mikuType"] == "TxDated" then
                shouldForce = options and options["forcedone"]
                if shouldForce then
                    TxDateds::destroy(item["uuid"])
                    return
                end
                if LucilleCore::askQuestionAnswerAsBoolean("Confirm destruction of TxDated '#{item["description"].green}' ? ", true) then
                    TxDateds::destroy(item["uuid"])
                end
                return
            end

            if item["mikuType"] == "Wave" then
                shouldForce = options and options["forcedone"]
                if shouldForce then
                    Waves::performWaveNx46WaveDone(item)
                    return
                end
                if LucilleCore::askQuestionAnswerAsBoolean("confirm wave done-ing '#{Waves::toString(item).green} ? '", true) then
                    Waves::performWaveNx46WaveDone(item)
                end
                return
            end
        end

        if command == "destroy" then
            if LucilleCore::askQuestionAnswerAsBoolean("confirm destruction of #{item["mikuType"]} '#{LxFunction::function("toString", item).green}' ") then
                Librarian::destroyClique(item["uuid"])
            end
            return
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

            if item["mikuType"] == "TxQueue" then
                TxQueues::landing(item)
                return
            end

            Landing::landing(item)
            return
        end

        if command == "redate" then
            if item["mikuType"] == "TxDated" then
                datetime = (CommonUtils::interactivelySelectDateTimeIso8601OrNullUsingDateCode() || Time.new.utc.iso8601)
                item["datetime"] = datetime
                Librarian::commit(item)
                return
            end
        end

        if command == "start" then
            return if NxBallsService::isRunning(item["uuid"])
            accounts = [item["uuid"]]
            if item["mikuType"] == "NxTask" then
                queue = Nx07::getOwnerForTaskOrNull(item)
                if queue then
                    accounts << queue["uuid"]
                end
            end
            NxBallsService::issue(item["uuid"], LxFunction::function("toString", item), accounts)
            return
        end

        if command == "stop" then
            NxBallsService::close(item["uuid"], true)
            return
        end

        if command == "transmute" then
            Transmutation::transmutationToInteractivelySelectedTargetType(item)
            return
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