
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
                    Fx18::deleteObject(item["uuid"])
                end
                return
            end

            if item["mikuType"] == "TopLevel" then
                uuid = item["uuid"]
                nhash = Fx18Attributes::getOrNull(uuid, "nhash")
                text = ExData::getBlobOrNull(nhash)
                text = CommonUtils::editTextSynchronously(text)
                nhash = ExData::putBlobInLocalDatablobsFolder(text)
                Fx18Attributes::set_objectUpdate(uuid, "nhash", nhash)
                return
            end

            if item["mikuType"] == "TxThread" then
                TxThreads::runAndAccessElements(item)
                return
            end

            if item["mikuType"] == "TxTimeControl" then
                TxTimeControls::landing(item)
                return
            end

            if Iam::implementsNx111(item) then
                if item["nx111"].nil? then
                    LucilleCore::pressEnterToContinue()
                    return
                end
                EditionDesk::accessItemNx111Pair(EditionDesk::pathToEditionDesk(), item, item["nx111"])
                return
            end

            if Iam::isNetworkAggregation(item) then
                LinkedNavigation::navigate(item)
                return
            end
        end

        if command == "done" then

            # If the item was running, then we stop it
            if NxBallsService::isRunning(item["uuid"]) then
                 NxBallsService::close(item["uuid"], true)
            end

            if item["mikuType"] == "(rstream-to-target)" then
                return
            end

            if item["mikuType"] == "NxAnniversary" then
                Anniversaries::done(item["uuid"])
                return
            end

            if item["mikuType"] == "NxBall.v2" then
                NxBallsService::close(item["uuid"], true)
                return
            end

            if item["mikuType"] == "NxFrame" then
                return
            end

            if item["mikuType"] == "NxTask" then
                if LucilleCore::askQuestionAnswerAsBoolean("destroy NxTask '#{LxFunction::function("toString", item).green}' ? ") then
                    Fx18::deleteObject(item["uuid"])
                    NxBallsService::close(item["uuid"], true)
                    DailySlots::remove(item["uuid"])
                end
                return
            end

            if item["mikuType"] == "NxLine" then
                if LucilleCore::askQuestionAnswerAsBoolean("destroy NxLine '#{LxFunction::function("toString", item).green}' ? ", true) then
                    Fx18::deleteObject(item["uuid"])
                    NxBallsService::close(item["uuid"], true)
                    DailySlots::remove(item["uuid"])
                end
                return
            end

            if item["mikuType"] == "TxDated" then
                if LucilleCore::askQuestionAnswerAsBoolean("Confirm destruction of TxDated '#{item["description"].green}' ? ", true) then
                    TxDateds::destroy(item["uuid"])
                    NxBallsService::close(item["uuid"], true)
                    DailySlots::remove(item["uuid"])
                end
                return
            end

            if item["mikuType"] == "TxThread" then
                NxBallsService::close(item["uuid"], true)
                if LucilleCore::askQuestionAnswerAsBoolean("done for today ? ", true) then
                    DoneForToday::setDoneToday(item["uuid"])
                    DailySlots::remove(item["uuid"])
                end
                return
            end

            if item["mikuType"] == "TxTimeControl" then
                NxBallsService::close(item["uuid"], true)
                if LucilleCore::askQuestionAnswerAsBoolean("done for today ? ", true) then
                    DoneForToday::setDoneToday(item["uuid"])
                    DailySlots::remove(item["uuid"])
                end
                return
            end

            if item["mikuType"] == "Wave" then
                if LucilleCore::askQuestionAnswerAsBoolean("confirm wave done-ing '#{Waves::toString(item).green} ? '", true) then
                    Waves::performWaveNx46WaveDone(item)
                    DailySlots::remove(item["uuid"])
                end
                return
            end
        end

        if command == "destroy" then
            if LucilleCore::askQuestionAnswerAsBoolean("confirm destruction of #{item["mikuType"]} '#{LxFunction::function("toString", item).green}' ") then
                Fx18::deleteObject(item["uuid"])
            end
            return
        end

        if command == "exit" then
            exit
        end

        if command == "landing" then

            # TODO:
            #if item["mikuType"] == "Ax1Text" then
            #    Ax1Text::landing(item)
            #    return
            #end
 
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
                Fx18Attributes::set_objectUpdate(item["uuid"], "datetime", datetime)
                return
            end
        end

        if command == "run" then

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

        if command == "start" then
            return if NxBallsService::isRunning(item["uuid"])
            NxBallsService::issue(item["uuid"], LxFunction::function("toString", item), [item["uuid"]])
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