
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

        if item["mikuType"] == "NxTimeCommitment" then
            puts NxTimeCommitments::toStringWithDetails(item, false)
            actions = ["set hours"]
            action = LucilleCore::selectEntityFromListOfEntitiesOrNull("action: ", actions)
            return if action.nil?
            if action == "set hours" then
                item["hours"] = LucilleCore::askQuestionAnswerAsString("hours (weekly): ").to_f
                TodoDatabase2::commitItem(item)
            end
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
            TodoDatabase2::commitItem(item)
            return
        end

        if item["mikuType"] == "Wave" then
            puts Waves::toString(item).green
            Waves::access(item)
            return
        end

        raise "(error: abb645e9-2575-458e-b505-f9c029f4ca69) I do not know how to access mikuType: #{item["mikuType"]}"
    end

    # PolyActions::done(item)
    def self.done(item)

        Locks::unlock(item["uuid"])

        # order: alphabetical order

        if item["mikuType"] == "LambdX1" then
            return
        end

        if item["mikuType"] == "NxAnniversary" then
            Anniversaries::done(item["uuid"])
            return
        end

        if item["mikuType"] == "NxTimeDrop" then
            puts "You cannot done a NxTimeDrop, only start and stop"
            if item["field2"] then
                if LucilleCore::askQuestionAnswerAsBoolean("Would you like to stop ? : ", true) then
                    NxTimeDrops::stop(item)
                end
            end
            return
        end

        if item["mikuType"] == "NxTodo" then
            puts PolyFunctions::toString(item)
            if LucilleCore::askQuestionAnswerAsBoolean("destroy NxTodo '#{item["description"].green}' ? ", true) then
                if item["nx113"] then
                    puts "You are attempting to done a NxTodo which carries some contents (Nx113)"
                    option = LucilleCore::selectEntityFromListOfEntitiesOrNull("option", ["destroy", "exit"])
                    return if option == ""
                    if option == "destroy" then
                        TodoDatabase2::destroy(item["uuid"])
                        return
                    end
                    if option == "exit" then
                        return
                    end
                    return
                else
                    TodoDatabase2::destroy(item["uuid"])
                end
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

        if item["mikuType"] == "NxTimeDrop" then
            if item["field2"] then
                NxTimeDrops::stop(item)
            else
                NxTimeDrops::start(item)
            end
            return
        end

        if item["mikuType"] == "NxTimeCommitment" then
            return
        end

        puts "I don't know how to doubleDot '#{item["mikuType"]}'"
        LucilleCore::pressEnterToContinue()
    end

    # PolyActions::touch(item)
    def self.touch(item)

        if item["mikuType"] == "NxAnniversary" then
            loop {
                actions = ["update description", "update start date"]
                action = LucilleCore::selectEntityFromListOfEntitiesOrNull("action: ", actions)
                break if action.nil?
                if action == "update description" then
                    description = CommonUtils::editTextSynchronously(anniversary["description"]).strip
                    return if description == ""
                    anniversary["description"] = description
                    TodoDatabase2::commitItem(anniversary)
                end
                if action == "update start date" then
                    startdate = CommonUtils::editTextSynchronously(anniversary["startdate"])
                    return if startdate == ""
                    anniversary["startdate"] = startdate
                    TodoDatabase2::commitItem(anniversary)
                end
            }
            return
        end

        if item["mikuType"] == "NxTimeCommitment" then
            loop {
                puts NxTimeCommitments::toStringWithDetails(item, false)
                actions = ["set hours", "add time"]
                action = LucilleCore::selectEntityFromListOfEntitiesOrNull("action: ", actions)
                break if action.nil?
                if action == "set hours" then
                    item["hours"] = LucilleCore::askQuestionAnswerAsString("hours (weekly): ").to_f
                    TodoDatabase2::commitItem(item)
                end
                if action == "add time" then
                    timeInHours = LucilleCore::askQuestionAnswerAsString("time in hours: ").to_f
                    drop = {
                        "uuid"        => SecureRandom.uuid,
                        "mikuType"    => "NxTimeDrop",
                        "unixtime"    => Time.new.to_i,
                        "datetime"    => Time.new.utc.iso8601,
                        "description" => "TimeDrop for #{item["description"]}",
                        "field1"      => -timeInHours,
                        "field2"      => nil,
                        "field4"      => item["uuid"]
                    }
                    puts JSON.pretty_generate(drop)
                    TodoDatabase2::commitItem(drop)
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
                    TodoDatabase2::commitItem(item)
                end
                if action == "update wave pattern" then
                    item["nx46"] = Waves::makeNx46InteractivelyOrNull()
                    TodoDatabase2::commitItem(item)
                end
                if action == "perform done" then
                    Waves::performWaveNx46WaveDone(item)
                    return
                end
                if action == "set days of the week" then
                    days, _ = CommonUtils::interactivelySelectSomeDaysOfTheWeekLowercaseEnglish()
                    item["onlyOnDays"] = days
                    TodoDatabase2::commitItem(item)
                end
            }
            return
        end

        puts "PolyActions::touch has not yet been implemented for miku type #{item["mikuType"]}"
        LucilleCore::pressEnterToContinue()
    end
end
