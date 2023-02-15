
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
            NxBoards::listingProgram(item)
            return
        end

        if item["mikuType"] == "NxOndate" then
            NxOndates::access(item)
            return
        end

        if item["mikuType"] == "NxBoard" then
            puts NxBoards::toString(item)
            actions = ["set hours", "access items"]
            action = LucilleCore::selectEntityFromListOfEntitiesOrNull("action: ", actions)
            return if action.nil?
            if action == "set hours" then
                puts "Not implemented yet"
                LucilleCore::pressEnterToContinue()
            end
            if action == "access items" then
                puts "Not implemented yet"
                LucilleCore::pressEnterToContinue()
            end
            return
        end

        if item["mikuType"] == "NxHead" then
            NxHeads::access(item)
            return
        end

        if item["mikuType"] == "NxTail" then
            NxTails::access(item)
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
            puts "There is no done action on NxBoards. If it was running, I have stopped it."
            LucilleCore::pressEnterToContinue()
            return
        end

        if item["mikuType"] == "NxOpen" then
            if LucilleCore::askQuestionAnswerAsBoolean("destroy '#{PolyFunctions::toString(item).green} ? '", true) then
                NxOpens::destroy(item["uuid"])
            end
            return
        end

        if item["mikuType"] == "NxOndate" then
            if LucilleCore::askQuestionAnswerAsBoolean("destroy '#{PolyFunctions::toString(item).green} ? '", true) then
                NxOndates::destroy(item["uuid"])
            end
            return
        end

        if item["mikuType"] == "NxBoardItem" then
            if LucilleCore::askQuestionAnswerAsBoolean("destroy '#{PolyFunctions::toString(item).green} ? '", true) then
                NxBoardItems::destroy(item["uuid"])
            end
            return
        end

        if item["mikuType"] == "NxTop" then
            if LucilleCore::askQuestionAnswerAsBoolean("destroy '#{PolyFunctions::toString(item).green} ? '", true) then
                NxTops::destroy(item["uuid"])
            end
            return
        end

        if item["mikuType"] == "NxHead" then
            if LucilleCore::askQuestionAnswerAsBoolean("destroy '#{PolyFunctions::toString(item).green} ? '", true) then
                NxHeads::destroy(item["uuid"])
            end
            return
        end

        if item["mikuType"] == "NxTail" then
            if LucilleCore::askQuestionAnswerAsBoolean("destroy '#{PolyFunctions::toString(item).green} ? '", true) then
                NxTails::destroy(item["uuid"])
            end
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

        if item["mikuType"] == "NxBoardItem" then
            NxBalls::start(item)
            NxBoardItems::access(item)
            options = ["done (destroy)", "do not display until", "keep running"]
            option = LucilleCore::selectEntityFromListOfEntitiesOrNull("action", options)
            return if option.nil?
            if option == "done (destroy)" then
                NxBoardItems::destroy(item["uuid"])
            end
            if option == "do not show until" then
                unixtime = CommonUtils::interactivelySelectUnixtimeUsingDateCodeOrNull()
                return if unixtime.nil?
                DoNotShowUntil::setUnixtime(item["uuid"], unixtime)
            end
            if option == "keep running" then
            end
            return
        end

        if item["mikuType"] == "NxHead" then
            NxBalls::start(item)
            NxHeads::access(item)
            options = ["done (destroy)", "do not display until", "keep running"]
            option = LucilleCore::selectEntityFromListOfEntitiesOrNull("action", options)
            return if option.nil?
            if option == "done (destroy)" then
                NxHeads::destroy(item["uuid"])
            end
            if option == "do not show until" then
                unixtime = CommonUtils::interactivelySelectUnixtimeUsingDateCodeOrNull()
                return if unixtime.nil?
                DoNotShowUntil::setUnixtime(item["uuid"], unixtime)
            end
            if option == "keep running" then
            end
            return
        end

        if item["mikuType"] == "NxTail" then
            NxBalls::start(item)
            NxTails::access(item)
            options = ["done (destroy)", "do not display until", "keep running"]
            option = LucilleCore::selectEntityFromListOfEntitiesOrNull("action", options)
            return if option.nil?
            if option == "done (destroy)" then
                NxTails::destroy(item["uuid"])
            end
            if option == "do not show until" then
                unixtime = CommonUtils::interactivelySelectUnixtimeUsingDateCodeOrNull()
                return if unixtime.nil?
                DoNotShowUntil::setUnixtime(item["uuid"], unixtime)
            end
            if option == "keep running" then
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

        if item["mikuType"] == "NxBoard" then
            PolyActions::access(item)
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

    # PolyActions::start(item)
    def self.start(item)
        NxBalls::start(item)
    end
end
