
class PolyActions

    # function name alphabetical order

    # PolyActions::access(item)
    def self.access(item)

        if item["mikuType"] == "EndOfDayChecklist" then
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

        if item["mikuType"] == "NyxNode" then
            NyxNodes::access(item)
            return
        end

        if item["mikuType"] == "NxTodo" then
            NxTodos::access(item)
            return
        end

        if item["mikuType"] == "Wave" then
            puts Waves::toString(item).green
            Waves::access(item)
            return
        end

        raise "(error: abb645e9-2575-458e-b505-f9c029f4ca69) I do not know how to access mikuType: #{item["mikuType"]}"
    end

    # PolyActions::destroyWithPrompt(item)
    def self.destroyWithPrompt(item)
        PolyActions::stop(item)
        if LucilleCore::askQuestionAnswerAsBoolean("confirm destruction of #{item["mikuType"]} '#{PolyFunctions::toString(item).green}' ") then
            NxDeleted::deleteObject(item["uuid"])
        end
    end

    # PolyActions::doubleDot(item)
    def self.doubleDot(item)

        puts "PolyActions::doubleDot(#{JSON.pretty_generate(item)})"

        if item["mikuType"] == "EndOfDayChecklist" then
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

        if item["mikuType"] == "EndOfDayChecklist" then
            EndOfDayChecklist::doneForToday(item)
            return
        end

        if item["mikuType"] == "NxAnniversary" then
            Anniversaries::done(item["uuid"])
            return
        end

        if item["mikuType"] == "NxBall.v2" then
            return
        end

        if item["mikuType"] == "NxTodo" then
            if LucilleCore::askQuestionAnswerAsBoolean("destroy NxTodo '#{item["description"].green}' ? ", true) then
                NxTodos::destroy(item["uuid"])
            end
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
        Items::setAttribute2(item["uuid"], "datetime", datetime)
    end

    # PolyActions::editDescription(item)
    def self.editDescription(item)
        description = CommonUtils::editTextSynchronously(item["description"]).strip
        return if description == ""
        Items::setAttribute2(item["uuid"], "description", description)
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
        Items::setAttribute2(item["uuid"], "startdate",   startdate)
    end

    # PolyActions::garbageCollectionAsPartOfLaterItemDestruction(item)
    def self.garbageCollectionAsPartOfLaterItemDestruction(item)
        return if item.nil?

        # order : alphabetical order
    end

    # PolyActions::redate(item)
    def self.redate(item)
        if item["mikuType"] != "NxTodo" then
            puts "redate only applies to NxTodos (engine: ondate)"
            LucilleCore::pressEnterToContinue()
            return
        end
        if item["nx11e"]["type"] != "ondate" then
            puts "redate only applies to NxTodos (engine: ondate)"
            LucilleCore::pressEnterToContinue()
            return
        end
        datetime = CommonUtils::interactivelySelectDateTimeIso8601UsingDateCode()
        Items::setAttribute2(item["uuid"], "nx11e", Nx11E::makeOndate(datetime))
    end

    # PolyActions::setNx113(item)
    def self.setNx113(item)
        nx113nhash = Nx113Make::interactivelyIssueNewNx113OrNullReturnDataBase1Nhash()
        return if nx113nhash.nil?
        Items::setAttribute2(item["uuid"], "nx113", nx113nhash)
    end

    # PolyActions::start(item)
    def self.start(item)
        #puts "PolyActions::start(#{JSON.pretty_generate(item)})"
        return if NxBallsService::isRunning(item["uuid"])
        accounts = []
        accounts << item["uuid"]
        if item["cx22"] then
            accounts << item["cx22"]["bankaccount"] # Contribution
        end
        NxBallsService::issue(item["uuid"], PolyFunctions::toString(item), accounts, PolyFunctions::timeBeforeNotificationsInHours(item)*3600)
    end

    # PolyActions::stop(item)
    def self.stop(item)
        #puts "PolyActions::stop(#{JSON.pretty_generate(item)})"
        NxBallsService::close(item["uuid"], true)
    end

    # PolyActions::transmute(item)
    def self.transmute(item)
        puts "PolyActions::transmute(#{JSON.pretty_generate(item)})"
        interactivelyChooseMikuTypeOrNull = lambda{|mikuTypes|
            LucilleCore::selectEntityFromListOfEntitiesOrNull("mikuType", mikuTypes)
        }

        if item["mikuType"] == "NxTodo" then
            targetMikuType = interactivelyChooseMikuTypeOrNull.call(["NyxNode"])
            return if targetMikuType.nil?
            if targetMikuType == "NyxNode" then
                networkType = NyxNodes::interactivelySelectNetworkType()
                if item["nx113"] and networkType != "PureData" then
                    puts "You are transmuting from a NxTodo with data, to a non data carrier NyxNode"
                    puts "You are going to lose the data"
                    return if !LucilleCore::askQuestionAnswerAsBoolean("confirm operation: ")
                end
                Items::setAttribute2(item["uuid"], "networkType", networkType)
                Items::setAttribute2(item["uuid"], "mikuType", "NyxNode")
                item = Items::getItemOrNull(item["uuid"])
                FileSystemCheck::fsckItemErrorArFirstFailure(item, SecureRandom.uuid, true)
                NyxNodes::landing(item)
            end
        end
    end
end
