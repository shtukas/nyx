
class PolyActions

    # PolyActions::doubleDot(item)
    def self.doubleDot(item)

        PolyFunctions::_check(item, "PolyActions::doubleDot")

        if item["mikuType"] == "fitness1" then
            PolyActions::access(item)
            return
        end

        if item["mikuType"] == "NxIced" then
            PolyActions::start(item)
            PolyActions::access(item)
            return
        end

        if item["mikuType"] == "TxDated" then
            PolyActions::start(item)
            PolyActions::access(item)
            loop {
                actions = ["keep running and back to listing", "stop and back to listing", "stop and destroy"]
                action = LucilleCore::selectEntityFromListOfEntitiesOrNull("action", actions)
                next if action.nil?
                if action == "keep running and back to listing" then
                    return
                end
                if action == "stop and back to listing" then
                    PolyActions::stop(item)
                    return
                end
                if action == "stop and destroy" then
                    PolyActions::stop(item)
                    PolyActions::destroyWithPrompt(item)
                    return
                end
            }
            return
        end

        if item["mikuType"] == "InboxItem" then
            PolyActions::start(item)
            PolyActions::access(item)
            actions = ["destroy", "transmute to task and get owner", "do not display until"]
            action = LucilleCore::selectEntityFromListOfEntitiesOrNull("action", actions)
            if action.nil? then
                PolyActions::stop(item)
                return
            end
            if action == "destroy" then
                PolyActions::stop(item)
                PolyActions::destroyWithPrompt(item)
                return
            end
            if action == "transmute to task and get owner" then
                PolyActions::stop(item)
                DxF1::setAttribute2(item["uuid"], "mikuType", "NxTask")
                item = TheIndex::getItemOrNull(item["uuid"]) # We assume it's not null
                TxTimeCommitmentProjects::interactivelyAddThisElementToOwner(item)
                return
            end
            if action == "do not display until" then
                PolyActions::stop(item)
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
            PolyActions::start(item)
            PolyActions::access(item)
            if LucilleCore::askQuestionAnswerAsBoolean("done '#{PolyFunctions::toString(item).green}' ? ") then
                Waves::performWaveNx46WaveDone(item)
                PolyActions::stop(item)
            else
                if LucilleCore::askQuestionAnswerAsBoolean("continue ? ") then
                    return
                else
                    PolyActions::stop(item)
                end
            end
            return
        end

        puts "I do not know how to PolyActions::doubleDot(#{JSON.pretty_generate(item)})"
        raise "(error: afbb56ca-90fa-47bc-972c-6681c6c58831)"
    end

    # PolyActions::done(item)
    def self.done(item)
        PolyFunctions::_check(item, "PolyActions::done")

        PolyActions::stop(item)

        if item["mikuType"] == "(rstream-to-target)" then
            return
        end

        if item["mikuType"] == "InboxItem" then
            DxF1::deleteObjectLogically(item["uuid"])
            return
        end

        if item["mikuType"] == "MxPlanning" then
            if LucilleCore::askQuestionAnswerAsBoolean("'#{PolyFunctions::toString(item).green}' done ? ", true) then
                MxPlanning::destroy(item["uuid"])
                if item["payload"]["type"] == "pointer" then
                    PolyActions::done(item["payload"]["item"])
                end
            end
            return
        end

        if item["mikuType"] == "MxPlanningDisplay" then
            PolyActions::done(item["item"])
            return
        end

        if item["mikuType"] == "NxAnniversary" then
            Anniversaries::done(item["uuid"])
            return
        end

        if item["mikuType"] == "NxBall.v2" then
            return
        end

        if item["mikuType"] == "TxFloat" then
            return
        end

        if item["mikuType"] == "NxIced" then
            NxIceds::destroy(item["uuid"])
            return
        end

        if item["mikuType"] == "NxTask" then
            if item["ax39"] then
                if LucilleCore::askQuestionAnswerAsBoolean("'#{PolyFunctions::toString(item).green}' done for today ? ", true) then
                    DoneForToday::setDoneToday(item["uuid"])
                end
                return
            end
            if LucilleCore::askQuestionAnswerAsBoolean("destroy NxTask '#{PolyFunctions::toString(item).green}' ? ") then
                DxF1::deleteObjectLogically(item["uuid"])
            end
            return
        end

        if item["mikuType"] == "NxLine" then
            if LucilleCore::askQuestionAnswerAsBoolean("destroy NxLine '#{PolyFunctions::toString(item).green}' ? ", true) then
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

        if item["mikuType"] == "TxTimeCommitmentProject" then
            return
        end

        if item["mikuType"] == "Wave" then
            if LucilleCore::askQuestionAnswerAsBoolean("done-ing '#{Waves::toString(item).green} ? '", true) then
                Waves::performWaveNx46WaveDone(item)
            end
            return
        end

        puts "I do not know how to PolyActions::done(#{JSON.pretty_generate(item)})"
        raise "(error: f278f3e4-3f49-4f79-89d2-e5d3b8f728e6)"
    end

    # PolyActions::destroyWithPrompt(item)
    def self.destroyWithPrompt(item)
        PolyFunctions::_check(item, "PolyActions::destroyWithPrompt")

        PolyActions::stop(item)
        if LucilleCore::askQuestionAnswerAsBoolean("confirm destruction of #{item["mikuType"]} '#{PolyFunctions::toString(item).green}' ") then
            DxF1::deleteObjectLogically(item["uuid"])
        end
    end

    # PolyActions::landing(item)
    def self.landing(item)
        PolyFunctions::_check(item, "PolyActions::landing")

        if item["mikuType"] == "fitness1" then
            system("#{Config::userHomeDirectory()}/Galaxy/Binaries/fitness doing #{item["fitness-domain"]}")
            return
        end

        if ["DxText", "NxAnniversary", "NxIced"].include?(item["mikuType"]) then
            return PolyFunctions::landing(item, isSearchAndSelect)
        end

        return PolyFunctions::landing(item, isSearchAndSelect = false)

        puts "I do not know how to PolyActions::landing(#{JSON.pretty_generate(item)})"
        raise "(error: 249ab52b-2eb5-4d99-904b-70994e223654)"
    end

    # PolyActions::redate(item)
    def self.redate(item)
        PolyFunctions::_check(item, "PolyActions::redate")

        if item["mikuType"] == "TxDated" then
            datetime = (CommonUtils::interactivelySelectDateTimeIso8601OrNullUsingDateCode() || Time.new.utc.iso8601)
            DxF1::setAttribute2(item["uuid"], "datetime", datetime)
            return
        end

        puts "I do not know how to PolyActions::redate(#{JSON.pretty_generate(item)})"
        raise "(error: bfc8c526-b23a-4d38-bc47-40d3733b4044)"
    end

    # PolyActions::start(item)
    def self.start(item)
        PolyFunctions::_check(item, "PolyActions::start")

        if item["mikuType"] == "MxPlanning" then
            if item["payload"]["type"] == "pointer" then
                PolyActions::start(item["payload"]["item"])
            end
        end

        if item["mikuType"] == "MxPlanningDisplay" then
            PolyActions::start(item["item"])
        end

        return if NxBallsService::isRunning(item["uuid"])

        NxBallsService::issue(item["uuid"], PolyFunctions::toString(item), PolyActions::bankAccounts(item), PolyFunctions::timeBeforeNotificationsInHours(item)*3600)
    end

    # PolyActions::stop(item)
    def self.stop(item)
        PolyFunctions::_check(item, "PolyActions::stop")
        if item["mikuType"] == "MxPlanning" then
            if item["payload"]["type"] == "pointer" then
                PolyActions::stop(item["payload"]["item"])
            end
        end
        if item["mikuType"] == "MxPlanningDisplay" then
            PolyActions::stop(item["item"])
        end
        NxBallsService::close(item["uuid"], true)
    end

    # PolyActions::access(item)
    def self.access(item)

        if item["mikuType"] == "(rstream-to-target)" then
            Streaming::icedStreamingToTarget()
            return
        end

        if item["mikuType"] == "fitness1" then
            puts PolyFunctions::toString(item).green
            system("#{Config::userHomeDirectory()}/Galaxy/Binaries/fitness doing #{item["fitness-domain"]}")
            return
        end

        if item["mikuType"] == "CxAionPoint" then
            CxAionPoint::access(item)
            return
        end

        if item["mikuType"] == "CxFile" then
            CxFile::access(item)
            return
        end

        if item["mikuType"] == "CxUrl" then
            CxUrl::access(item)
            return
        end

        if item["mikuType"] == "DxAionPoint" then
            DxAionPoint::access(item)
            return
        end

        if item["mikuType"] == "DxText" then
            CommonUtils::accessText(item["text"])
            return
        end

        if item["mikuType"] == "MxPlanning" then
            if item["payload"]["type"] == "simple" then
                puts item["payload"]["description"].green
                LucilleCore::pressEnterToContinue()
            end
            if item["payload"]["type"] == "pointer" then
                PolyActions::access(item["payload"]["item"])
            end
            return
        end

        if item["mikuType"] == "MxPlanningDisplay" then
            PolyActions::access(item["item"])
            return
        end

        if item["mikuType"] == "NxAnniversary" then
            Anniversaries::access(item)
            return
        end

        if item["mikuType"] == "NxBall.v2" then
            if NxBallsService::isRunning(item["uuid"]) then
                if LucilleCore::askQuestionAnswerAsBoolean("complete '#{PolyFunctions::toString(item).green}' ? ") then
                    NxBallsService::close(item["uuid"], true)
                end
            end
            return
        end

        if item["mikuType"] == "NxIced" then
            Nx112::carrierAccess(item)
            return
        end

        if item["mikuType"] == "NxLine" then
            if LucilleCore::askQuestionAnswerAsBoolean("destroy '#{PolyFunctions::toString(item).green}' ? ") then
                DxF1::deleteObjectLogically(item["uuid"])
            end
            return
        end

        if item["mikuType"] == "NxTask" then
            Nx112::carrierAccess(item)
            return
        end

        if item["mikuType"] == "TopLevel" then
            puts PolyFunctions::toString(item).green
            action = LucilleCore::selectEntityFromListOfEntitiesOrNull("action", ["access", "edit"])
            return if action.nil?
            if action == "access" then
                TopLevel::access(item)
            end
            if action == "edit" then
                TopLevel::edit(item)
            end
            return
        end

        if item["mikuType"] == "InboxItem" then
            Nx112::carrierAccess(item)
            return
        end

        if item["mikuType"] == "TxFloat" then
            Nx112::carrierAccess(item)
            return
        end

        if item["mikuType"] == "TxTimeCommitmentProject" then
            puts PolyFunctions::toString(item).green
            TxTimeCommitmentProjects::access(item)
            return
        end

        if item["mikuType"] == "Wave" then
            puts Waves::toString(item).green
            Nx112::carrierAccess(item)
            return
        end

        if Iam::isNetworkAggregation(item) then
            LinkedNavigation::navigate(item)
            return
        end

        raise "(error: abb645e9-2575-458e-b505-f9c029f4ca69) I do not know how to access mikuType: #{item["mikuType"]}"
    end

    # PolyActions::bankAccounts(item)
    def self.bankAccounts(item)

        decideTxTimeCommitmentProjectUUIDOrNull = lambda {|itemuuid|
            key = "bb9bf6c2-87c4-4fa1-a8eb-21c0b3c67c61:#{itemuuid}"
            uuid = XCache::getOrNull(key)
            if uuid == "null" then
                return nil
            end
            if uuid then
                return uuid
            end
            puts "This is important, pay attention"
            LucilleCore::pressEnterToContinue()
            ox = TxTimeCommitmentProjects::interactivelySelectOneOrNull()
            if ox then
                XCache::set(key, ox["uuid"])
                return ox["uuid"]
            else
                XCache::set(key, "null")
                return nil
            end
        }

        accounts = [item["uuid"]] # Item's own uuid

        if ["NxLine", "Nxtask"].include?(item["mikuType"]) then
            accounts = accounts + OwnerMapping::elementuuidToOwnersuuids(item["uuid"])
        end

        if ["InboxItem", "TxDated"].include?(item["mikuType"]) then
            accounts = accounts + [decideTxTimeCommitmentProjectUUIDOrNull.call(item["uuid"])].compact
        end

        accounts
    end

    # PolyActions::transmutation(item, targetMikuType)
    def self.transmutation(item, targetMikuType)

    end
end
