
# encoding: UTF-8

class PolyActions

    # function name alphabetical order

    # PolyActions::access(item)
    def self.access(item)

        if item["mikuType"] == "Cx22" then
            Cx22::dive(item)
            return
        end

        if item["mikuType"] == "NxAnniversary" then
            Anniversaries::access(item)
            return
        end

        if item["mikuType"] == "NxBall.v2" then
            if NxBallsService::isRunning(item) then
                if LucilleCore::askQuestionAnswerAsBoolean("complete '#{PolyFunctions::toString(item).green}' ? ") then
                    NxBallsService::close(NxBallsService::itemToNxBallOpt(item), true)
                end
            end
            return
        end

        if item["mikuType"] == "Nx7" then
            Nx7::access(item)
            return
        end

        if item["mikuType"] == "NxTodo" then
            NxTodos::access(item)
            return
        end

        if item["mikuType"] == "TxManualCountDown" then
            puts item["description"]
            count = LucilleCore::askQuestionAnswerAsString("done count: ").to_i
            item["counter"] = item["counter"] - count
            TxManualCountDowns::commit(item)
            return
        end

        if item["mikuType"] == "Wave" then
            puts Waves::toString(item).green
            Waves::access(item)
            return
        end

        raise "(error: abb645e9-2575-458e-b505-f9c029f4ca69) I do not know how to access mikuType: #{item["mikuType"]}"
    end

    # PolyActions::commit(item)
    def self.commit(item)

        if item["mikuType"] == "Cx22" then
            Cx22::commit(item)
            return
        end

        if item["mikuType"] == "NxTodo" then
            NxTodos::commitObject(item)
            return
        end

        if item["mikuType"] == "Nx7" then
            Nx7::commitObject(item)
            return
        end

        if item["mikuType"] == "Wave" then
            Waves::commit(item)
            return
        end

        raise "(error: 92a90b00-4582-4678-9c7b-686b74e64713) I don't know how to commit Miku type: #{item["mikuType"]}"
    end

    # PolyActions::destroy(item)
    def self.destroy(item)
        PolyActions::stop(item)

        if item["mikuType"] == "NxTodo" then
            NxTodos::destroy(item["uuid"])
            return
        end

        if item["mikuType"] == "Nx7" then
            Nx7::destroy(item["uuid"])
            return
        end

        if item["mikuType"] == "Wave" then
            Waves::destroy(item["uuid"])
            return
        end

        raise "(error: 518883e2-76bc-4611-b0aa-9a69c8877400) I don't know how to destroy Miku type: #{item["mikuType"]}"
    end

    # PolyActions::destroyWithPrompt(item)
    def self.destroyWithPrompt(item)
        PolyActions::stop(item)
        if LucilleCore::askQuestionAnswerAsBoolean("confirm destruction of #{item["mikuType"]} '#{PolyFunctions::toString(item).green}' ") then
            PolyActions::destroy(item)
        end
    end

    # PolyActions::doubleDot(item)
    def self.doubleDot(item)

        #puts "PolyActions::doubleDot(#{JSON.pretty_generate(item)})"

        if item["mikuType"] == "Cx22" then
            return
        end

        if item["mikuType"] == "NxTodo" then

            # We havea a special processing of triage items
            if item["nx11e"]["type"] == "triage" then
                loop {
                    puts PolyFunctions::toString(item).green
                    actions = ["access >> ♻️", "access >> description >> ♻️", "standard >> contribution", "start >> access >> al.", "destroy", "exit"]
                    action = LucilleCore::selectEntityFromListOfEntitiesOrNull("action", actions)
                    next if action.nil?
                    if action == "access >> ♻️" then
                        PolyActions::access(item)
                        next
                    end
                    if action == "access >> description >> ♻️" then
                        PolyActions::access(item)
                        PolyActions::editDescription(item)
                        next
                    end
                    if action == "start >> access >> al." then
                        PolyActions::start(item)
                        PolyActions::access(item)
                        LucilleCore::pressEnterToContinue("Press enter to move to stop and continue")
                        PolyActions::stop(item)
                        actions = ["destroy", "keep as standard and return to listing"]
                        action = LucilleCore::selectEntityFromListOfEntitiesOrNull("action", actions)
                        return if action.nil?
                        if action == "destroy" then
                            if LucilleCore::askQuestionAnswerAsBoolean("destroy NxTodo '#{item["description"].green}' ? ", true) then
                                NxTodos::destroy(item["uuid"])
                            end
                            return
                        end
                        if action == "keep as standard and return to listing" then
                            item["nx11e"] = Nx11E::makeStandard()
                            item["cx23"] = Cx23::interactivelyMakeNewOrNull()
                            PolyActions::commit(item)
                            return
                        end
                    end
                    if action == "standard >> contribution" then
                        item["nx11e"] = Nx11E::makeStandard()
                        item["cx23"] = Cx23::interactivelyMakeNewOrNull()
                        PolyActions::commit(item)
                        return
                    end
                    if action == "destroy" then
                        if LucilleCore::askQuestionAnswerAsBoolean("destroy NxTodo '#{item["description"].green}' ? ", true) then
                            NxTodos::destroy(item["uuid"])
                        end
                        return
                    end
                    if action == "exit" then
                        return
                    end
                }
                return
            end

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

        if item["mikuType"] == "TxManualCountDown" then
            PolyActions::access(item)
            return
        end

        raise "(error: 2b6aab43-6a93-4c0e-99b0-0cf882e66bde) I do not know how to PolyActions::doubleDot(#{JSON.pretty_generate(item)})"
    end

    # PolyActions::done(item, useConfirmationIfRelevant = true)
    def self.done(item, useConfirmationIfRelevant = true)

        if item["mikuType"] == "Cx22" then
            return
        end

        if item["mikuType"] == "NxBall.v2" then
            NxBallsService::close(item, true)
            return
        end

        PolyActions::stop(item)

        # order: alphabetical order

        if item["mikuType"] == "NxAnniversary" then
            Anniversaries::done(item["uuid"])
            return
        end

        if item["mikuType"] == "NxTodo" then
            puts PolyFunctions::toString(item)
            if item["nx113"] then
                puts "You are attempting to done a NxTodo which carries some contents (Nx113)"
                option = LucilleCore::selectEntityFromListOfEntitiesOrNull("option", ["landing", "Luke, use the Force (destroy)", "exit"])
                return if option == ""
                if option == "landing" then
                    PolyActions::landing(item)
                end
                if option == "Luke, use the Force (destroy)" then
                    NxTodos::destroy(item["uuid"])
                end
                if option == "exit" then
                    return
                end
                return
            end
            if useConfirmationIfRelevant then
                if LucilleCore::askQuestionAnswerAsBoolean("destroy NxTodo '#{item["description"].green}' ? ", true) then
                    NxTodos::destroy(item["uuid"])
                end
            else
                NxTodos::destroy(item["uuid"])
            end
            return
        end

        if item["mikuType"] == "Wave" then
            if useConfirmationIfRelevant then
                if LucilleCore::askQuestionAnswerAsBoolean("done-ing '#{Waves::toString(item).green} ? '", true) then
                    Waves::performWaveNx46WaveDone(item)
                end
            else
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
        item["datetime"] = datetime
        PolyActions::commit(item)
    end

    # PolyActions::editDescription(item)
    def self.editDescription(item)
        description = CommonUtils::editTextSynchronously(item["description"]).strip
        return if description == ""
        item["description"] = description
        PolyActions::commit(item)
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
        item["startdate"] = startdate
        PolyActions::commit(item)
    end

    # PolyActions::garbageCollectionAfterItemDeletion(item)
    def self.garbageCollectionAfterItemDeletion(item)
        return if item.nil?
        if item["nx113"] then
            nx113 = Nx113Access::getNx113(item["nx113"])
            if nx113["type"] == "Dx8Unit" then
                Nx113Dx33s::issue(nx113["unitId"])
            end
        end
    end

    # PolyActions::giveTime(item, timeInSeconds)
    def self.giveTime(item, timeInSeconds)
        PolyFunctions::bankAccountsForItem(item).each{|account|
            puts "(#{Time.new.to_s}) putting #{timeInSeconds} seconds into account: #{account}"
            Bank::put(account, timeInSeconds)
        }
    end

    # PolyActions::landing(item)
    def self.landing(item)
        if item["mikuType"] == "Cx22" then
            Cx22::dive(item)
            return
        end

        if item["mikuType"] == "NxAnniversary" then
            Anniversaries::landing(item)
            return
        end

        if item["mikuType"] == "Wave" then
            Waves::landing(item)
            return
        end

        if item["mikuType"] == "NxLine" then
            puts "#{PolyFunctions::toString(item)}"
            puts "uuid: #{item["uuid"]}".yellow
            puts ""
            puts "destroy".yellow
            puts ""
            input = LucilleCore::askQuestionAnswerAsString("> ")
            if input == "destroy" then
                NxLines::destroy(item["uuid"])
            end
            return
        end

        if item["mikuType"] == "NxTodo" then
            NxTodos::landing(item)
            return
        end

        if item["mikuType"] == "Nx7" then
            Nx7::landing(item)
            return
        end

        raise "(error: D9DD0C7C-ECC4-46D0-A1ED-CD73591CC87B): item: #{item}"
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
        item["nx11e"] = Nx11E::makeOndate(datetime)
        PolyActions::commit(item)
    end

    # PolyActions::start(item)
    def self.start(item)
        #puts "PolyActions::start(#{JSON.pretty_generate(item)})"
        return if NxBallsService::isRunning(NxBallsService::itemToNxBallOpt(item))
        NxBallsService::issue(
            item["uuid"], 
            PolyFunctions::toString(item), 
            PolyFunctions::bankAccountsForItem(item), 
            PolyFunctions::timeBeforeNotificationsInHours(item)*3600
        )
    end

    # PolyActions::stop(item)
    def self.stop(item)
        #puts "PolyActions::stop(#{JSON.pretty_generate(item)})"
        if item["mikuType"] == "NxBall.v2" then
            NxBallsService::close(item, true)
            return
        end

        NxBallsService::close(NxBallsService::itemToNxBallOpt(item), true)
    end
end
