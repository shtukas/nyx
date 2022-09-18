
class PolyActions

    # function name alphabetical order

    # PolyActions::access(item)
    def self.access(item)

        if item["mikuType"] == "fitness1" then
            puts PolyFunctions::toString(item).green
            system("#{Config::userHomeDirectory()}/Galaxy/Binaries/fitness doing #{item["fitness-domain"]}")
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

        if item["mikuType"] == "NxTask" then
            NxTasks::access(item)
            return
        end

        if item["mikuType"] == "NyxNode" then
            NyxNodes::access(item)
            return
        end

        if item["mikuType"] == "TxDated" then
            TxDateds::access(item)
            return
        end

        if item["mikuType"] == "TxTimeCommitment" then
            CatalystListing::setContext(item["uuid"])
            return
        end

        if item["mikuType"] == "Wave" then
            puts Waves::toString(item).green
            Waves::access(item)
            return
        end

        raise "(error: abb645e9-2575-458e-b505-f9c029f4ca69) I do not know how to access mikuType: #{item["mikuType"]}"
    end

    # PolyActions::dataPrefetchAttempt(item)
    def self.dataPrefetchAttempt(item)
        return if item.nil?

        # order : alphabetical order

        # TODO: 

    end

    # PolyActions::destroyWithPrompt(item)
    def self.destroyWithPrompt(item)
        PolyActions::stop(item)
        if LucilleCore::askQuestionAnswerAsBoolean("confirm destruction of #{item["mikuType"]} '#{PolyFunctions::toString(item).green}' ") then
            DxF1::deleteObject(item["uuid"])
        end
    end

    # PolyActions::doubleDot(item)
    def self.doubleDot(item)

        puts "PolyActions::doubleDot(#{JSON.pretty_generate(item)})"

        if item["mikuType"] == "fitness1" then
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
        PolyActions::stop(item)

        # order: alphabetical order

        if item["mikuType"] == "NxAnniversary" then
            Anniversaries::done(item["uuid"])
            return
        end

        if item["mikuType"] == "NxBall.v2" then
            return
        end

        if item["mikuType"] == "TxDated" then
            if LucilleCore::askQuestionAnswerAsBoolean("destroy TxDated '#{item["description"].green}' ? ", true) then
                TxDateds::destroy(item["uuid"])
            end
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
                DxF1::deleteObject(item["uuid"])
            end
            return
        end

        if item["mikuType"] == "TxTimeCommitment" then
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

    # PolyActions::editDatetime(item)
    def self.editDatetime(item)
        datetime = CommonUtils::editTextSynchronously(item["datetime"]).strip
        return if !CommonUtils::isDateTime_UTC_ISO8601(datetime)
        DxF1::setAttribute2(item["uuid"], "datetime", datetime)
    end

    # PolyActions::editDescription(item)
    def self.editDescription(item)
        description = CommonUtils::editTextSynchronously(item["description"]).strip
        return if description == ""
        DxF1::setAttribute2(item["uuid"], "description", description)
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

    # PolyActions::garbageCollectionAsPartOfLaterItemDestruction(item)
    def self.garbageCollectionAsPartOfLaterItemDestruction(item)
        return if item.nil?

        # order : alphabetical order

    end

    # PolyActions::linktoPureDataDescriptionOnly(item)
    def self.linktoPureDataDescriptionOnly(item)
        l1 = DxLine::interactivelyIssueNewOrNull()
        return if l1.nil?
        puts JSON.pretty_generate(l1)
        NetworkLinks::link(item["uuid"], l1["uuid"])
    end

    # PolyActions::linktoPureDataText(item)
    def self.linktoPureDataText(item)
        i2 = NyxNodes::interactivelyIssueNewPureDataTextOrNull()
        return if i2.nil?
        puts JSON.pretty_generate(i2)
        NetworkLinks::link(item["uuid"], i2["uuid"])
    end

    # PolyActions::redate(item)
    def self.redate(item)
        if item["mikuType"] == "TxDated" then
            datetime = (CommonUtils::interactivelySelectDateTimeIso8601OrNullUsingDateCode() || Time.new.utc.iso8601)
            DxF1::setAttribute2(item["uuid"], "datetime", datetime)
            return
        end

        puts "I do not know how to PolyActions::redate(#{JSON.pretty_generate(item)})"
        raise "(error: bfc8c526-b23a-4d38-bc47-40d3733b4044)"
    end

    # PolyActions::setNx113(item)
    def self.setNx113(item)
        nx113nhash = Nx113Make::interactivelyIssueNewNx113OrNullReturnDataBase1Nhash()
        return if nx113nhash.nil?
        DxF1::setAttribute2(item["uuid"], "nx113", nx113nhash)
    end

    # PolyActions::start(item)
    def self.start(item)
        #puts "PolyActions::start(#{JSON.pretty_generate(item)})"
        return if NxBallsService::isRunning(item["uuid"])
        NxBallsService::issue(item["uuid"], PolyFunctions::toString(item), [item["uuid"]], PolyFunctions::timeBeforeNotificationsInHours(item)*3600)
    end

    # PolyActions::stop(item)
    def self.stop(item)
        puts "PolyActions::stop(#{JSON.pretty_generate(item)})"
        NxBallsService::close(item["uuid"], true)
    end

    # PolyActions::transmute(item)
    def self.transmute(item)
        interactivelyChooseMikuTypeOrNull = lambda{|mikuTypes|
            LucilleCore::selectEntityFromListOfEntitiesOrNull("mikuType", mikuTypes)
        }
    end
end
