
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

        if item["mikuType"] == "NxOndate" then
            NxOndates::access(item)
            return
        end

        if item["mikuType"] == "NxTimeCommitment" then
            NxTimeCommitments::probe(item)
            return
        end

        if item["mikuType"] == "NxTodo" then
            NxTodos::access(item)
            return
        end

        if item["mikuType"] == "NxTriage" then
            NxTriages::access(item)
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

        if item["mikuType"] == "NxOndate" then
            if LucilleCore::askQuestionAnswerAsBoolean("destroy NxOndate '#{item["description"].green}' ? ", true) then
                TodoDatabase2::destroy(item["uuid"])
            end
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

        if item["mikuType"] == "NxTriage" then
            if LucilleCore::askQuestionAnswerAsBoolean("destroy NxTriage '#{NxTriages::toString(item).green} ? '", true) then
                TodoDatabase2::destroy(item["uuid"])
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
            NxTimeDrops::start(item)
            if LucilleCore::askQuestionAnswerAsBoolean("> stop ? ", true) then
                NxTimeDrops::stop(item)
            end
            return
        end

        PolyActions::access(item)

        if LucilleCore::askQuestionAnswerAsBoolean("> done ? ", true) then
            PolyActions::done(item)
        end
    end

    # PolyActions::edit(item)
    def self.edit(item)
        puts "PolyActions Edit has not yet been implemented for miku type #{item["mikuType"]}"
        LucilleCore::pressEnterToContinue()
    end

    # PolyActions::probe(item)
    def self.probe(item)

        # order: alphabetical order

        if item["mikuType"] == "NxTimeCommitment" then
            NxTimeCommitments::probe(item)
            return
        end

        if item["mikuType"] == "LambdX1" then
            return
        end

        if item["mikuType"] == "NxAnniversary" then
            Anniversaries::probe(item)
            return
        end

        if item["mikuType"] == "NxTriage" then
            NxTriages::probe(item)
            return
        end

        if item["mikuType"] == "NxTodo" then
            NxTodos::probe(item)
            return
        end

        if item["mikuType"] == "Wave" then
            Waves::probe(item)
            return
        end

        puts "I do not know how to PolyActions::probe(#{JSON.pretty_generate(item)})"
        raise "(error: 9CD4B61D-8B13-4075-A560-7F3D801DD0D6)"
    end
end
