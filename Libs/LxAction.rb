
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

        if command == ".." then
            ## .. performs the optimal sequence for this item

            if item["mikuType"] == "fitness1" then
                LxAccess::access(item)
                return
            end

            if item["mikuType"] == "NxIced" then
                LxAction::action("start", item)
                LxAccess::access(item)
                return
            end

            if item["mikuType"] == "TxDated" then
                LxAction::action("start", item)
                LxAccess::access(item)
                loop {
                    actions = ["keep running and back to listing", "stop and back to listing", "stop and destroy"]
                    action = LucilleCore::selectEntityFromListOfEntitiesOrNull("action", actions)
                    next if action.nil?
                    if action == "keep running and back to listing" then
                        return
                    end
                    if action == "stop and back to listing" then
                        LxAction::action("stop", item)
                        return
                    end
                    if action == "stop and destroy" then
                        LxAction::action("stop", item)
                        LxAction::action("destroy-with-prompt", item)
                        return
                    end
                }
                return
            end

            if item["mikuType"] == "TxIncoming" then
                LxAction::action("start", item)
                LxAccess::access(item)
                actions = ["destroy", "transmute to task and get owner", "do not display until"]
                action = LucilleCore::selectEntityFromListOfEntitiesOrNull("action", actions)
                if action.nil? then
                    LxAction::action("stop", item)
                    return
                end
                if action == "destroy" then
                    LxAction::action("stop", item)
                    LxAction::action("destroy-with-prompt", item)
                    return
                end
                if action == "transmute to task and get owner" then
                    LxAction::action("stop", item)
                    puts "Write it: 7a114e67-6767-4d99-b6d0-fc002e2ebd0f"
                    exit
                    return
                end
                if action == "do not display until" then
                    LxAction::action("stop", item)
                    puts "Write it: 9a681ca6-c5ca-4839-ae1a-0ecd973d25a0"
                    exit
                    return
                end
                return
            end

            if item["mikuType"] == "TxTimeCommitmentProject" then
                TxTimeCommitmentProjects::doubleDot(item)
                return
            end

            if item["mikuType"] == "Wave" then
                LxAction::action("start", item)
                LxAccess::access(item)
                if LucilleCore::askQuestionAnswerAsBoolean("done '#{LxFunction::function("toString", item).green}' ? ") then
                    Waves::performWaveNx46WaveDone(item)
                    LxAction::action("stop", item)
                else
                    if LucilleCore::askQuestionAnswerAsBoolean("continue ? ") then
                        return
                    else
                        LxAction::action("stop", item)
                    end
                end
                return
            end

            raise "(.. action not implemented for mikuType: #{item["mikuType"]})"

            return
        end

        if command == ">nyx" then
            LxAction::action("stop", item)
            puts "TODO"
            exit
            return
        end

        if command == "done" then

            LxAction::action("stop", item)

            if item["mikuType"] == "(rstream-to-target)" then
                return
            end

            if item["mikuType"] == "MxPlanning" then
                if LucilleCore::askQuestionAnswerAsBoolean("'#{LxFunction::function("toString", item).green}' done ? ", true) then
                    MxPlanning::destroy(item["uuid"])
                    if item["payload"]["type"] == "pointer" then
                        LxAction::action("done", item["payload"]["item"])
                    end
                end
                return
            end

            if item["mikuType"] == "MxPlanningDisplay" then
                LxAction::action("done", item["item"])
                return
            end

            if item["mikuType"] == "NxAnniversary" then
                Anniversaries::done(item["uuid"])
                return
            end

            if item["mikuType"] == "NxBall.v2" then
                return
            end

            if item["mikuType"] == "NxFrame" then
                return
            end

            if item["mikuType"] == "NxIced" then
                NxIceds::destroy(item["uuid"])
                return
            end

            if item["mikuType"] == "NxTask" then
                if item["ax39"] then
                    if LucilleCore::askQuestionAnswerAsBoolean("'#{LxFunction::function("toString", item).green}' done for today ? ", true) then
                        DoneForToday::setDoneToday(item["uuid"])
                    end
                    return
                end
                if LucilleCore::askQuestionAnswerAsBoolean("destroy NxTask '#{LxFunction::function("toString", item).green}' ? ") then
                    DxF1::deleteObjectLogically(item["uuid"])
                end
                return
            end

            if item["mikuType"] == "NxLine" then
                if LucilleCore::askQuestionAnswerAsBoolean("destroy NxLine '#{LxFunction::function("toString", item).green}' ? ", true) then
                    DxF1::deleteObjectLogically(item["uuid"])
                end
                return
            end

            if item["mikuType"] == "TxDated" then
                if LucilleCore::askQuestionAnswerAsBoolean("destroy TxDated '#{item["description"].green}' ? ", true) then
                    TxDateds::destroy(item["uuid"])
                end
                return
            end

            if item["mikuType"] == "TxIncoming" then
                DxF1::deleteObjectLogically(item["uuid"])
                return
            end

            if item["mikuType"] == "Wave" then
                if LucilleCore::askQuestionAnswerAsBoolean("done-ing '#{Waves::toString(item).green} ? '", true) then
                    Waves::performWaveNx46WaveDone(item)
                end
                return
            end
        end

        if command == "destroy-with-prompt" then
            LxAction::action("stop", item)
            if LucilleCore::askQuestionAnswerAsBoolean("confirm destruction of #{item["mikuType"]} '#{LxFunction::function("toString", item).green}' ") then
                DxF1::deleteObjectLogically(item["uuid"])
            end
            return
        end

        if command == "exit" then
            exit
        end

        if command == "landing" then
 
            if item["mikuType"] == "fitness1" then
                system("#{Config::userHomeDirectory()}/Galaxy/Binaries/fitness doing #{item["fitness-domain"]}")
                return
            end

            if ["DxText", "NxAnniversary", "NxIced"].include?(item["mikuType"]) then
                return LxLanding::landing(item, isSearchAndSelect)
            end

            return LxLanding::landing(item, isSearchAndSelect = false)
        end

        if command == "redate" then
            if item["mikuType"] == "TxDated" then
                datetime = (CommonUtils::interactivelySelectDateTimeIso8601OrNullUsingDateCode() || Time.new.utc.iso8601)
                DxF1::setAttribute2(item["uuid"], "datetime", datetime)
                return
            end
        end

        if command == "start" then

            if item["mikuType"] == "MxPlanning" then
                if item["payload"]["type"] == "pointer" then
                    LxAction::action("start", item["payload"]["item"])
                end
            end

            if item["mikuType"] == "MxPlanningDisplay" then
                LxAction::action("start", item["item"])
            end

            return if NxBallsService::isRunning(item["uuid"])

            accounts = []
            accounts << item["uuid"] # Item's own uuid
            OwnerMapping::elementuuidToOwnersuuids(item["uuid"])
                .each{|owneruuid|
                    accounts << owneruuid # Owner of a owned item
                }
            if ["TxIncoming", "TxDated"].include?(item["mikuType"]) then
                ox = TxTimeCommitmentProjects::interactivelySelectOneOrNull()
                if ox then
                    puts "registering extra bank account: #{LxFunction::function("toString", ox).green}"
                    accounts << ox["uuid"] # temporary owner for TxIncoming
                end
            end

            NxBallsService::issue(item["uuid"], LxFunction::function("toString", item), accounts)
            return
        end

        if command == "stop" then
            if item["mikuType"] == "MxPlanning" then
                if item["payload"]["type"] == "pointer" then
                    LxAction::action("stop", item["payload"]["item"])
                end
            end
            if item["mikuType"] == "MxPlanningDisplay" then
                LxAction::action("stop", item["item"])
            end
            NxBallsService::close(item["uuid"], true)
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