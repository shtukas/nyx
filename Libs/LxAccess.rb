
class LxAccess

    # LxAccess::access(item)
    def self.access(item)

        if item["mikuType"] == "(rstream-to-target)" then
            Streaming::icedStreamingToTarget()
            return
        end

        if item["mikuType"] == "fitness1" then
            puts LxFunction::function("toString", item).green
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
                LxAccess::access(item["payload"]["item"])
            end
            return
        end

        if item["mikuType"] == "MxPlanningDisplay" then
            LxAccess::access(item["item"])
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

        if item["mikuType"] == "NxIced" then
            Nx112::carrierAccess(item)
            return
        end

        if item["mikuType"] == "NxLine" then
            if LucilleCore::askQuestionAnswerAsBoolean("destroy '#{LxFunction::function("toString", item).green}' ? ") then
                DxF1::deleteObjectLogically(item["uuid"])
            end
            return
        end

        if item["mikuType"] == "NxTask" then
            Nx112::carrierAccess(item)
        end

        if item["mikuType"] == "TopLevel" then
            puts LxFunction::function("toString", item).green
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

        if item["mikuType"] == "TxIncoming" then
            puts TxIncomings::toString(item)
            LucilleCore::pressEnterToContinue()
            return
        end

        if item["mikuType"] == "TxTimeCommitmentProject" then
            puts LxFunction::function("toString", item).green
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

        raise "(error: abb645e9-2575-458e-b505-f9c029f4ca69) I do not know how to access mnikuType: #{item["mikuType"]}"
    end
end