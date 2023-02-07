
# encoding: UTF-8

class PolyActions

    # function names in alphabetical order

    # PolyActions::access(item)
    def self.access(item)

        # types in alphabetical order

        if item["mikuType"] == "LambdX1" then
            item["lambda"].call()
            return
        end

        if item["mikuType"] == "NxAnniversary" then
            Anniversaries::accessAndDone(item)
            return
        end

        if item["mikuType"] == "NxBoard" then
            NxStreams::listingProgram(item)
            return
        end

        if item["mikuType"] == "NxBoardFirstItem" then
            todo = item["todo"]
            PolyActions::access(todo)
            return
        end

        if item["mikuType"] == "NxDrop" then
            return
        end

        if item["mikuType"] == "NxOndate" then
            NxOndates::access(item)
            return
        end

        if item["mikuType"] == "NxTimeCommitment" then
            puts NxTimeCommitments::toString(item, false)
            actions = ["set hours"]
            action = LucilleCore::selectEntityFromListOfEntitiesOrNull("action: ", actions)
            return if action.nil?
            if action == "set hours" then
                item["hours"] = LucilleCore::askQuestionAnswerAsString("hours (weekly): ").to_f
                ObjectStore2::commit("NxTimeCommitments", item)
            end
            return
        end

        if item["mikuType"] == "NxTodo" then
            NxTodos::access(item)
            return
        end

        if item["mikuType"] == "NxTop" then
            return
        end

        if item["mikuType"] == "TxManualCountDown" then
            TxManualCountDowns::access(item)
            return
        end

        if item["mikuType"] == "Wave" then
            Waves::access(item)
            return
        end

        raise "(error: abb645e9-2575-458e-b505-f9c029f4ca69) I do not know how to access mikuType: #{item["mikuType"]}"
    end

    # PolyActions::done(item)
    def self.done(item)

        NxBalls::stop(item)
        Locks::unlock(item["uuid"])

        # order: alphabetical order

        if item["mikuType"] == "LambdX1" then
            return
        end

        if item["mikuType"] == "NxAnniversary" then
            Anniversaries::done(item["uuid"])
            return
        end

        if item["mikuType"] == "NxBoard" then
            puts "There is no doen action on NxStreams. You probaly want stop"
            LucilleCore::pressEnterToContinue()
            return
        end

        if item["mikuType"] == "NxBoardFirstItem" then
            todo = item["todo"]
            PolyActions::done(todo)
            return
        end

        if item["mikuType"] == "NxDrop" then
            if LucilleCore::askQuestionAnswerAsBoolean("destroy '#{PolyFunctions::toString(item).green} ? '", true) then
                NxDrops::destroy(item["uuid"])
            end
            return
        end

        if item["mikuType"] == "NxOndate" then
            if LucilleCore::askQuestionAnswerAsBoolean("destroy '#{PolyFunctions::toString(item).green} ? '", true) then
                NxOndates::destroy(item["uuid"])
            end
            return
        end

        if item["mikuType"] == "NxTop" then
            if LucilleCore::askQuestionAnswerAsBoolean("destroy '#{PolyFunctions::toString(item).green} ? '", true) then
                NxTops::destroy(item["uuid"])
            end
            return
        end

        if item["mikuType"] == "NxTodo" then
            if LucilleCore::askQuestionAnswerAsBoolean("destroy '#{PolyFunctions::toString(item).green} ? '", true) then
                NxTodos::destroy(item["uuid"])
            end
            return
        end

        if item["mikuType"] == "NxTimeCommitment" then
            return
        end

        if item["mikuType"] == "TxManualCountDown" then
            TxManualCountDowns::performUpdate(item)
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

    # PolyActions::doubleDot(item)
    def self.doubleDot(item)

        if item["mikuType"] == "NxBoard" then
            PolyActions::access(item)
            return
        end

        if item["mikuType"] == "NxBoardFirstItem" then
            board = item["board"]
            todo = item["todo"]
            if board["hasTimeCommitmentCompanion"] == "true" and ItemToTimeCommitmentMapping::getOrNull(todo).nil? then
                ItemToTimeCommitmentMapping::interactiveProposalToSetMapping(todo)
            end

            NxBalls::start(todo)

            options = ["done (destroy)", "run in background", "do not display until"]
            option = LucilleCore::selectEntityFromListOfEntitiesOrNull("action", options)
            return if option.nil?
            if option == "done (destroy)" then
                NxTodos::destroy(todo["uuid"])
            end
            if option == "run in background" then
                return
            end
            if option == "do not show until" then
                unixtime = CommonUtils::interactivelySelectUnixtimeUsingDateCodeOrNull()
                return if unixtime.nil?
                DoNotShowUntil::setUnixtime(todo["uuid"], unixtime)
            end

            return
        end

        if item["mikuType"] == "NxOndate" then
            NxBalls::start(item)
            NxOndates::access(item)
            options = ["done (destroy)", "run in background", "do not display until"]
            option = LucilleCore::selectEntityFromListOfEntitiesOrNull("action", options)
            return if option.nil?
            if option == "done (destroy)" then
                NxOndates::destroy(todo["uuid"])
            end
            if option == "run in background" then
                return
            end
            if option == "redate" then
                NxOndates::redate(item)
            end
            return
        end

        if item["mikuType"] == "NxTimeCommitment" then
            if NxBalls::itemIsRunning(item) then
                if LucilleCore::askQuestionAnswerAsBoolean("We are running, would you like to stop ? ".green, true) then
                    NxBalls::stop(item)
                end
                return
            end
            if NxBalls::itemIsPaused(item) then
                if LucilleCore::askQuestionAnswerAsBoolean("We are paused would you like to pursue ? ".green, true) then
                    NxBalls::pursue(item)
                end
                return
            end
            if NxBalls::itemIsBallFree(item) then
                if LucilleCore::askQuestionAnswerAsBoolean("Would you like to start ? ".green, true) then
                    NxBalls::start(item)
                end
                return
            end
            return
        end

        if item["mikuType"] == "NxTodo" then
            NxBalls::start(item)
            NxTodos::access(item)
            options = ["done (destroy)", "do not display until"]
            option = LucilleCore::selectEntityFromListOfEntitiesOrNull("action", options)
            return if option.nil?
            if option == "done (destroy)" then
                NxTodos::destroy(item["uuid"])
            end
            if option == "do not show until" then
                unixtime = CommonUtils::interactivelySelectUnixtimeUsingDateCodeOrNull()
                return if unixtime.nil?
                DoNotShowUntil::setUnixtime(item["uuid"], unixtime)
            end
            return
        end

        if item["mikuType"] == "NxTriage" then
            NxBalls::start(item)
            NxTriages::access(item)
            options = ["done (destroy)", "move to board", "do not display until"]
            option = LucilleCore::selectEntityFromListOfEntitiesOrNull("action", options)
            return if option.nil?
            if option == "done (destroy)" then
                NxTriages::destroy(item["uuid"])
            end
            if option == "move to board" then
                board = NxStreams::interactivelySelectOne()
                newitem = item.clone
                newitem["uuid"] = SecureRandom.uuid
                newitem["mikuType"] = "NxTodo"
                newitem["boarduuid"] = board["uuid"]
                newitem["boardposition"] = NxStreams::decideNewBoardPosition(board)
                NxTodos::commit(newitem)
                NxTriages::destroy(item["uuid"])
            end
            if option == "do not show until" then
                unixtime = CommonUtils::interactivelySelectUnixtimeUsingDateCodeOrNull()
                return if unixtime.nil?
                DoNotShowUntil::setUnixtime(item["uuid"], unixtime)
            end
            return
        end

        if item["mikuType"] == "TxManualCountDown" then
            TxManualCountDowns::access(item)
            return
        end

        if item["mikuType"] == "Wave" then
            NxBalls::start(item)
            PolyActions::access(item)
            if LucilleCore::askQuestionAnswerAsBoolean("done-ing '#{Waves::toString(item).green} ? '", true) then
                NxBalls::stop(item)
                Waves::performWaveNx46WaveDone(item)
            end
            return
        end

        puts "I don't know how to doubleDot '#{item["mikuType"]}'"
        LucilleCore::pressEnterToContinue()
    end

    # PolyActions::landing(item)
    def self.landing(item)

        if item["mikuType"] == "NxAnniversary" then
            loop {
                actions = ["update description", "update start date"]
                action = LucilleCore::selectEntityFromListOfEntitiesOrNull("action: ", actions)
                break if action.nil?
                if action == "update description" then
                    description = CommonUtils::editTextSynchronously(anniversary["description"]).strip
                    return if description == ""
                    anniversary["description"] = description
                    ObjectStore2::commit("NxAnniversaries", anniversary)
                end
                if action == "update start date" then
                    startdate = CommonUtils::editTextSynchronously(anniversary["startdate"])
                    return if startdate == ""
                    anniversary["startdate"] = startdate
                    ObjectStore2::commit("NxAnniversaries", anniversary)
                end
            }
            return
        end

        if item["mikuType"] == "NxTimeCommitment" then
            loop {
                puts NxTimeCommitments::toString(item, false)
                actions = ["set hours", "add time"]
                action = LucilleCore::selectEntityFromListOfEntitiesOrNull("action: ", actions)
                break if action.nil?
                if action == "set hours" then
                    item["hours"] = LucilleCore::askQuestionAnswerAsString("hours (weekly): ").to_f
                    ObjectStore2::commit("NxTimeCommitments", item)
                end
                if action == "add time" then
                    timeInHours = LucilleCore::askQuestionAnswerAsString("time in hours: ").to_f
                    BankCore::put(item["uuid"], timeInHours * 3600)
                end
            }
            return
        end

        if item["mikuType"] == "Wave" then
            loop {
                puts Waves::toString(item)
                actions = ["update description", "update wave pattern", "perform done", "set days of the week"]
                action = LucilleCore::selectEntityFromListOfEntitiesOrNull("action: ", actions)
                break if action.nil?
                if action == "update description" then
                    item["description"] = CommonUtils::editTextSynchronously(item["description"])
                    ObjectStore2::commit("Waves", item)
                end
                if action == "update wave pattern" then
                    item["nx46"] = Waves::makeNx46InteractivelyOrNull()
                    ObjectStore2::commit("Waves", item)
                end
                if action == "perform done" then
                    Waves::performWaveNx46WaveDone(item)
                    return
                end
                if action == "set days of the week" then
                    days, _ = CommonUtils::interactivelySelectSomeDaysOfTheWeekLowercaseEnglish()
                    item["onlyOnDays"] = days
                    ObjectStore2::commit("Waves", item)
                end
            }
            return
        end

        puts "PolyActions::landing has not yet been implemented for miku type #{item["mikuType"]}"
        LucilleCore::pressEnterToContinue()
    end

    # PolyActions::pursue(item)
    def self.pursue(item)
        NxBalls::pursue(item)
    end
end
