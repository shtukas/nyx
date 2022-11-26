
# encoding: UTF-8

class PolyActions

    # function names in alphabetical order

    # PolyActions::access(item)
    def self.access(item)

        # types in alphabetical order

        if item["mikuType"] == "Cx22" then
            return
        end

        if item["mikuType"] == "Lx01" then
            item["lambda"].call()
            return
        end

        if item["mikuType"] == "NxAnniversary" then
            Anniversaries::access(item)
            return
        end

        if item["mikuType"] == "NxBall" then
            NxBall::access(item)
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

        if item["mikuType"] == "NxTriage" then
            NxTriages::access(item)
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
            Nx7::commit(item)
            return
        end

        if item["mikuType"] == "Wave" then
            Waves::commitItem(item)
            return
        end

        raise "(error: 92a90b00-4582-4678-9c7b-686b74e64713) I don't know how to commit Miku type: #{item["mikuType"]}"
    end

    # PolyActions::destroy(item)
    def self.destroy(item)
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
        if LucilleCore::askQuestionAnswerAsBoolean("confirm destruction of #{item["mikuType"]} '#{PolyFunctions::toString(item).green}' ") then
            PolyActions::destroy(item)
        end
    end

    # PolyActions::done(item, useConfirmationIfRelevant = true)
    def self.done(item, useConfirmationIfRelevant = true)

        # order: alphabetical order

        if item["mikuType"] == "Cx22" then
            return
        end

        if item["mikuType"] == "Lx01" then
            return
        end

        if item["mikuType"] == "NxAnniversary" then
            Anniversaries::done(item["uuid"])
            return
        end

        if item["mikuType"] == "NxBall" then
            NxBall::commitTimeAndDestroy(item)
            return
        end

        if item["mikuType"] == "NxTodo" then
            puts PolyFunctions::toString(item)
            if item["nx113"] then
                puts "You are attempting to done a NxTodo which carries some contents (Nx113)"
                option = LucilleCore::selectEntityFromListOfEntitiesOrNull("option", ["Luke, use the Force (destroy)", "exit"])
                return if option == ""
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

    # PolyActions::postDoubleAccess(item)
    def self.postDoubleAccess(item)

        # order: alphabetical order

        if item["mikuType"] == "Cx22" then
            return
        end

        if item["mikuType"] == "Lx01" then
            return
        end

        if item["mikuType"] == "NxAnniversary" then
            Anniversaries::done(item["uuid"])
            return
        end

        if item["mikuType"] == "NxBall" then
            NxBall::commitTimeAndDestroy(item)
            return
        end

        if item["mikuType"] == "NxTriage" then
            option = LucilleCore::selectEntityFromListOfEntitiesOrNull("option", ["Luke, use the Force (destroy)", "transmute > todo", "exit"])
            return if option == ""
            if option == "Luke, use the Force (destroy)" then
                NxTriages::destroy(item["uuid"])
            end
            if option == "transmute > todo" then
                raise "not implemented yet"
            end
            if option == "exit" then
                return
            end
            return
        end

        if item["mikuType"] == "NxOndate" then
            option = LucilleCore::selectEntityFromListOfEntitiesOrNull("option", ["Luke, use the Force (destroy)", "redate", "exit"])
            return if option == ""
            if option == "Luke, use the Force (destroy)" then
                NxOndates::destroy(item["uuid"])
            end
            if option == "redate" then
                raise "not implemented yet"
            end
            if option == "exit" then
                return
            end
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

        puts "I do not know how to PolyActions::postDoubleAccess(#{JSON.pretty_generate(item)})"
        raise "(error: 9CD4B61D-8B13-4075-A560-7F3D801DD0D6)"
    end

    # PolyActions::redate(item)
    def self.redate(item)
        if item["mikuType"] != "NxOndate" then
            puts "redate only applies to NxOndate"
            LucilleCore::pressEnterToContinue()
            return
        end
        item["datetime"] = CommonUtils::interactivelySelectDateTimeIso8601UsingDateCode()
        PolyActions::commit(item)
    end
end
