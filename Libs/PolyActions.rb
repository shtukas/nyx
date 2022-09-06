
class PolyActions

    # function name alphabetical order

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

        if item["mikuType"] == "CxDx8Unit" then
            CxDx8Unit::access(item)
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

        if item["mikuType"] == "NxAnniversary" then
            Anniversaries::access(item)
            return
        end

        if item["mikuType"] == "NxEvent" then
            Nx112::carrierAccess(item)
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
            puts PolyFunctions::toString(item).green
            LucilleCore::pressEnterToContinue()
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
            TxTimeCommitmentProjects::access(item, "access")
            return
        end

        if item["mikuType"] == "Wave" then
            puts Waves::toString(item).green
            Nx112::carrierAccess(item)
            return
        end

        if Iam::isNetworkAggregation(item) then
            LinkedNavigation::navigateItem(item)
            return
        end

        raise "(error: abb645e9-2575-458e-b505-f9c029f4ca69) I do not know how to access mikuType: #{item["mikuType"]}"
    end

    # PolyActions::destroyWithPrompt(item)
    def self.destroyWithPrompt(item)
        PolyFunctions::_check(item, "PolyActions::destroyWithPrompt")

        PolyActions::stop(item)
        if LucilleCore::askQuestionAnswerAsBoolean("confirm destruction of #{item["mikuType"]} '#{PolyFunctions::toString(item).green}' ") then
            DxF1::deleteObjectLogically(item["uuid"])
        end
    end

    # PolyActions::doubleDot(item)
    def self.doubleDot(item)

        puts "PolyActions::doubleDot(#{JSON.pretty_generate(item)})"

        PolyFunctions::_check(item, "PolyActions::doubleDot")

        if item["mikuType"] == "fitness1" then
            PolyActions::access(item)
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

        if item["mikuType"] == "TxTimeCommitmentProject" then
            # We do not start the commitment item itself, we just start the program
            TxTimeCommitmentProjects::access(item, "doubleDot")
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

        PolyActions::start(item)
        PolyActions::access(item)
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

    # PolyActions::link_line(item)
    def self.link_line(item)
        l1 = NxLines::interactivelyIssueNewLineOrNull()
        return if l1.nil?
        puts JSON.pretty_generate(l1)
        NetworkLinks::link(item["uuid"], l1["uuid"])
    end

    # PolyActions::link_text(item)
    def self.link_text(item)
        i2 = DxText::interactivelyIssueNewOrNull()
        return if i2.nil?
        puts JSON.pretty_generate(i2)
        NetworkLinks::link(item["uuid"], i2["uuid"])
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

    # PolyActions::setNx112(item)
    def self.setNx112(item)
        i2 = Cx::interactivelyCreateNewCxForOwnerOrNull(item["uuid"])
        return if i2.nil?
        puts JSON.pretty_generate(i2)
        DxF1::setAttribute2(item["uuid"], "nx112", i2["uuid"])
    end

    # PolyActions::issueNxBallForItem(item)
    def self.issueNxBallForItem(item)
        puts "PolyActions::issueNxBallForItem(#{JSON.pretty_generate(item)})"
        NxBallsService::issue(item["uuid"], PolyFunctions::toString(item), PolyFunctions::bankAccounts(item), PolyFunctions::timeBeforeNotificationsInHours(item)*3600)
    end

    # PolyActions::start(item)
    def self.start(item)

        puts "PolyActions::start(#{JSON.pretty_generate(item)})"

        PolyFunctions::_check(item, "PolyActions::start")
        return if NxBallsService::isRunning(item["uuid"])

        PolyActions::issueNxBallForItem(item)
    end

    # PolyActions::stop(item)
    def self.stop(item)
        PolyFunctions::_check(item, "PolyActions::stop")
        NxBallsService::close(item["uuid"], true)
    end

    # PolyActions::transmute(item)
    def self.transmute(item)
        interactivelyChooseMikuTypeOrNull = lambda{|mikuTypes|
            LucilleCore::selectEntityFromListOfEntitiesOrNull("mikuType", mikuTypes)
        }

        if item["mikuType"] == "TxFloat" then
            puts "Need to write the code (follow: e143fbfd-8819-4310-8857-9aec554b5271)"
            LucilleCore::pressEnterToContinue()
        end
    end

    # PolyActions::editDescription(item)
    def self.editDescription(item)

        noImplementationTypes = [
            "CxAionPoint",
            "CxDx8Unit",
            "CxFile",
            "CxText",
            "CxUniqueString",
            "CxUrl",
            "DxUrl"
        ]

        if noImplementationTypes.include?(item["mikuType"]) then
            puts "update description is not implemented for #{item["mikuType"]}"
            LucilleCore::pressEnterToContinue()
            return
        end

        if item["mikuType"] == "DxLine" then
            str = CommonUtils::editTextSynchronously(item["line"]).strip
            return if str == ""
            DxF1::setAttribute2(item["uuid"], "line", str)
        end

        if item["mikuType"] == "NxPerson" then
            str = CommonUtils::editTextSynchronously(item["name"]).strip
            return if str == ""
            DxF1::setAttribute2(item["uuid"], "name", str)
        end

        description = CommonUtils::editTextSynchronously(item["description"]).strip
        return if description == ""
        DxF1::setAttribute2(item["uuid"], "description", description)
    end

    # PolyActions::editDatetime(item)
    def self.editDatetime(item)
        datetime = CommonUtils::editTextSynchronously(item["datetime"]).strip
        return if !CommonUtils::isDateTime_UTC_ISO8601(datetime)
        DxF1::setAttribute2(item["uuid"], "datetime", datetime)
    end

    # PolyActions::editStartDate(item)
    def self.editStartDate(item)
        if item["mikuType"] != "NxAnniversary" then
            puts "update description is only implemented for NxAnniversary"
            LucilleCore::pressEnterToContinue()
            return
        end

        startdate = CommonUtils::editTextSynchronously(item["startdate"])
        return if startdate == ""
        DxF1::setAttribute2(item["uuid"], "startdate",   startdate)
    end
end
