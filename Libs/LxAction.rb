
class LxAction

    # LxAction::action(command, item or nil)
    def self.action(command, item = nil)

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

        if command == ">nyx" then
            NxBallsService::close(item["uuid"], true)
            Transmutation::transmutation1(item, item["mikuType"], "NxDataNode")
            return
        end

        if command == "access" then

            puts LxFunction::function("toString", item).green

            if item["mikuType"] == "fitness1" then
                system("#{Config::userHomeDirectory()}/Galaxy/Binaries/fitness doing #{item["fitness-domain"]}")
                return
            end

            if item["mikuType"] == "(rstream-to-target)" then
                Streaming::icedStreamingToTarget()
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

            if item["mikuType"] == "NxLine" then
                if LucilleCore::askQuestionAnswerAsBoolean("destroy '#{LxFunction::function("toString", item).green}' ? ") then
                    Fx256::deleteObjectLogically(item["uuid"])
                end
                return
            end

            if item["mikuType"] == "TopLevel" then
                uuid = item["uuid"]
                text = item["text"]
                CommonUtils::accessText(text)
                if LucilleCore::askQuestionAnswerAsBoolean("Would you like to edit ? ") then
                    text = CommonUtils::editTextSynchronously(text)
                    Fx18Attributes::setJsonEncoded(uuid, "text", text)
                end
                return
            end

            if Iam::implementsNx111(item) then
                if item["nx111"].nil? then
                    LucilleCore::pressEnterToContinue()
                    return
                end
                Nx111::access(item, item["nx111"])
                return
            end

            if Iam::isNetworkAggregation(item) then
                LinkedNavigation::navigate(item)
                return
            end
        end

        if command == "done" then

            if item["mikuType"] == "(rstream-to-target)" then
                NxBallsService::close(item["uuid"], true)
                return
            end

            if item["mikuType"] == "NxAnniversary" then
                Anniversaries::done(item["uuid"])
                NxBallsService::close(item["uuid"], true)
                return
            end

            if item["mikuType"] == "NxBall.v2" then
                NxBallsService::close(item["uuid"], true)
                return
            end

            if item["mikuType"] == "NxFrame" then
                NxBallsService::close(item["uuid"], true)
                return
            end

            if item["mikuType"] == "NxTask" then
                if item["ax39"] then
                    if LucilleCore::askQuestionAnswerAsBoolean("'#{LxFunction::function("toString", item).green}' done for today ? ", true) then
                        DoneForToday::setDoneToday(item["uuid"])
                    end
                    NxBallsService::close(item["uuid"], true)
                    return
                end
                if LucilleCore::askQuestionAnswerAsBoolean("destroy NxTask '#{LxFunction::function("toString", item).green}' ? ") then
                    Fx256::deleteObjectLogically(item["uuid"])
                    NxBallsService::close(item["uuid"], true)
                end
                return
            end

            if item["mikuType"] == "NxLine" then
                if LucilleCore::askQuestionAnswerAsBoolean("destroy NxLine '#{LxFunction::function("toString", item).green}' ? ", true) then
                    Fx256::deleteObjectLogically(item["uuid"])
                end
                NxBallsService::close(item["uuid"], true)
                return
            end

            if item["mikuType"] == "TxDated" then
                if LucilleCore::askQuestionAnswerAsBoolean("destroy TxDated '#{item["description"].green}' ? ", true) then
                    TxDateds::destroy(item["uuid"])
                end
                NxBallsService::close(item["uuid"], true)
                return
            end

            if item["mikuType"] == "Wave" then
                if LucilleCore::askQuestionAnswerAsBoolean("done-ing '#{Waves::toString(item).green} ? '", true) then
                    Waves::performWaveNx46WaveDone(item)
                end
                NxBallsService::close(item["uuid"], true)
                return
            end
        end

        if command == "destroy" then
            if LucilleCore::askQuestionAnswerAsBoolean("confirm destruction of #{item["mikuType"]} '#{LxFunction::function("toString", item).green}' ") then
                Fx256::deleteObjectLogically(item["uuid"])
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
                system("#{Config::userHomeDirectory()}/Galaxy/Binaries/fitness doing #{item["fitness-domain"]}")
                return
            end

            Landing::landing(item, isSearchAndSelect = false)
            return
        end

        if command == "redate" then
            if item["mikuType"] == "TxDated" then
                datetime = (CommonUtils::interactivelySelectDateTimeIso8601OrNullUsingDateCode() || Time.new.utc.iso8601)
                Fx18Attributes::setJsonEncoded(item["uuid"], "datetime", datetime)
                return
            end
        end

        if command == "run" then
            LxAction::action("start", item)
            LxAction::action("access", item)
            LucilleCore::pressEnterToContinue("Press [enter] to done and finish: ")
            LxAction::action("done", item)
            return
        end

        if command == "start" then
            return if NxBallsService::isRunning(item["uuid"])
            accounts = [item["uuid"]] + OwnerMapping::elementuuidToOwnersuuids(item["uuid"])
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
            Waves::issueNewWaveInteractivelyOrNull()
            return
        end

        puts "I do not know how to do action (command: #{command}, item: #{JSON.pretty_generate(item)})"
        LucilleCore::pressEnterToContinue()
    end
end