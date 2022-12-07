
# encoding: UTF-8

class PolyActions

    # function names in alphabetical order

    # PolyActions::access(item)
    def self.access(item)

        # types in alphabetical order

        if item["mikuType"] == "Cx22" then
            Cx22::probe(item)
            return
        end

        if item["mikuType"] == "LambdX1" then
            item["lambda"].call()
            return
        end

        if item["mikuType"] == "NxAnniversary" then
            Anniversaries::accessAndDone(item)
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

        if item["mikuType"] == "NxOndate" then
            NxOndates::access(item)
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
            PolyActions::garbageCollectionAfterItemDeletion(item)
            return
        end

        if item["mikuType"] == "TxProject" then
            TxProjects::destroy(item["uuid"])
            return
        end

        if item["mikuType"] == "Wave" then
            Waves::destroy(item["uuid"])
            PolyActions::garbageCollectionAfterItemDeletion(item)
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

    # PolyActions::done(item)
    def self.done(item)

        filepath = "#{Config::pathToDataCenter()}/Locks/#{item["uuid"]}.lock"
        if File.exists?(filepath) then
            FileUtils.touch(filepath)
        end

        # order: alphabetical order

        if item["mikuType"] == "Cx22" then
            return
        end

        if item["mikuType"] == "LambdX1" then
            return
        end

        if item["mikuType"] == "NxAnniversary" then
            Anniversaries::done(item["uuid"])
            return
        end

        if item["mikuType"] == "NxBall" then
            NxBalls::close(item)
            return
        end

        if item["mikuType"] == "NxOndate" then
            if LucilleCore::askQuestionAnswerAsBoolean("destroy NxOndate '#{item["description"].green}' ? ", true) then
                NxOndates::destroy(item["uuid"])
            end
            return
        end

        if item["mikuType"] == "NxTodo" then
            puts PolyFunctions::toString(item)
            if item["nx113"] then
                puts "You are attempting to done a NxTodo which carries some contents (Nx113)"
                option = LucilleCore::selectEntityFromListOfEntitiesOrNull("option", ["destroy", "exit"])
                return if option == ""
                if option == "destroy" then
                    NxTodos::destroy(item["uuid"])
                    TxItemCx22Pair::closeNxBallForItemIfExists(item["uuid"])
                end
                if option == "exit" then
                    return
                end
                return
            end
            if LucilleCore::askQuestionAnswerAsBoolean("destroy NxTodo '#{item["description"].green}' ? ", true) then
                NxTodos::destroy(item["uuid"])
                TxItemCx22Pair::closeNxBallForItemIfExists(item["uuid"])
            end
            return
        end

        if item["mikuType"] == "NxTriage" then
            if LucilleCore::askQuestionAnswerAsBoolean("destroy NxTriage '#{NxTriages::toString(item).green} ? '") then
                NxTriages::destroy(item["uuid"])
                TxItemCx22Pair::closeNxBallForItemIfExists(item["uuid"])
            end
            return
        end

        if item["mikuType"] == "TxFloat" then
            if LucilleCore::askQuestionAnswerAsBoolean("destroy TxFloat '#{NxTriages::toString(item).green} ? '") then
                TxFloats::destroy(item["uuid"])
            end
            return
        end

        if item["mikuType"] == "Wave" then
            if LucilleCore::askQuestionAnswerAsBoolean("done-ing '#{Waves::toString(item).green} ? '", true) then
                Waves::performWaveNx46WaveDone(item)
                TxItemCx22Pair::closeNxBallForItemIfExists(item["uuid"])
            end
            return
        end

        puts "I do not know how to PolyActions::done(#{JSON.pretty_generate(item)})"
        raise "(error: f278f3e4-3f49-4f79-89d2-e5d3b8f728e6)"
    end

    # PolyActions::doubleDotAccess(item)
    def self.doubleDotAccess(item)

        filepath = "#{Config::pathToDataCenter()}/Locks/#{item["uuid"]}.lock"
        if File.exists?(filepath) then
            FileUtils.touch(filepath)
        end

        # order: alphabetical order

        issueNxBallForItem = lambda {|item|
            description = PolyFunctions::toString(item)
            accounts = PolyFunctions::bankAccountsForItem(item)
            return if accounts.empty?
            announce = accounts.map{|account| account["description"] }.join("; ")
            puts "NxBall: starting: #{announce}".green
            NxBalls::issue(accounts)
        }

        if item["mikuType"] == "Cx22" then
            PolyActions::start(item)
            return
        end

        if item["mikuType"] == "LambdX1" then
            PolyActions::access(item)
            return
        end

        if item["mikuType"] == "NxAnniversary" then
            Anniversaries::accessAndDone(item)
            return
        end

        if item["mikuType"] == "NxBall" then
            puts "You cannot doubleDot a NxBall, but you can stop it"
            LucilleCore::pressEnterToContinue()
            return
        end

        if item["mikuType"] == "NxTriage" then
            NxTriages::access(item)
            option = LucilleCore::selectEntityFromListOfEntitiesOrNull("option", ["done", ">todo", "exit"])
            return if option.nil?
            if option == "done" then
                NxTriages::destroy(item["uuid"])
            end
            if option == ">todo" then
                NxTriages::transmuteItemToNxTodo(item)
                return
            end
            if option == "exit" then
                return
            end
            return
        end

        if item["mikuType"] == "NxOndate" then
            nxball = PolyActions::start(item)
            NxOndates::access(item)
            option = LucilleCore::selectEntityFromListOfEntitiesOrNull("option", ["done", "redate", "run in background"])
            return if option.nil?
            if option == "done" then
                NxOndates::destroy(item["uuid"])
                NxBalls::close(nxball) if nxball
            end
            if option == "redate" then
                item["datetime"] = CommonUtils::interactivelySelectDateTimeIso8601UsingDateCode()
                NxOndates::commitObject(item)
                NxBalls::close(nxball)
            end
            if option == "run in background" then
                TxItemCx22Pair::issue(item["uuid"], nxball["uuid"])
                return
            end
            return
        end

        if item["mikuType"] == "NxTodo" then
            nxball = PolyActions::start(item)
            NxTodos::access(item)
            option = LucilleCore::selectEntityFromListOfEntitiesOrNull("option", ["done", "run in background"])
            return if option.nil?
            if option == "done" then
                NxTodos::destroy(item["uuid"])
                NxBalls::close(nxball) if nxball
            end
            if option == "run in background" then
                TxItemCx22Pair::issue(item["uuid"], nxball["uuid"])
                return
            end
            return
        end

        if item["mikuType"] == "TxManualCountDown" then
            puts item["description"]
            count = LucilleCore::askQuestionAnswerAsString("#{item["description"]}: done count: ").to_i
            item["counter"] = item["counter"] - count
            item["lastUpdatedUnixtime"] = Time.new.to_i
            puts JSON.pretty_generate(item)
            TxManualCountDowns::commit(item)
            return
        end

        if item["mikuType"] == "TxFloat" then
            if LucilleCore::askQuestionAnswerAsBoolean("destroy TxFloat '#{TxFloats::toString(item)}' ? ") then
                TxFloats::destroy(item["uuid"])
            end
            return
        end

        if item["mikuType"] == "TxProject" then
            issueNxBallForItem.call(item)
            return
        end

        if item["mikuType"] == "Wave" then
            nxball = PolyActions::start(item)
            PolyActions::access(item)
            option = LucilleCore::selectEntityFromListOfEntitiesOrNull("option", ["done", "run in background"])
            return if option.nil?
            if option == "done" then
                Waves::performWaveNx46WaveDone(item)
                NxBalls::close(nxball) if nxball
            end
            if option == "run in background" then
                TxItemCx22Pair::issue(item["uuid"], nxball["uuid"])
                return
            end
            return
        end

        puts "I do not know how to PolyActions::doubleDotAccess(#{JSON.pretty_generate(item)})"
        raise "(error: 9CD4B61D-8B13-4075-A560-7F3D801DD0D6)"
    end

    # PolyActions::garbageCollectionAfterItemDeletion(item)
    def self.garbageCollectionAfterItemDeletion(item)
        return if item.nil?
        if item["nx113"] then
            nx113 = item["nx113"]
            if nx113["type"] == "Dx8Unit" then
                Nx113Dx33s::issue(nx113["unitId"])
            end
        end
    end

    # PolyActions::probe(item)
    def self.probe(item)

        # order: alphabetical order

        if item["mikuType"] == "Cx22" then
            Cx22::probe(item)
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

        if item["mikuType"] == "NxOndate" then
            NxOndates::probe(item)
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

    # PolyActions::start(item) # null or NxBall
    def self.start(item)
        accounts = PolyFunctions::bankAccountsForItem(item)
        return nil if accounts.empty?
        announce = accounts.map{|account| account["description"] }.join("; ")
        puts "NxBall: starting: #{announce}".green
        nxball = NxBalls::issue(accounts)
        XCache::set("item-to-nxball-c15a5a0bcc54:#{item["uuid"]}", nxball["uuid"])
        XCache::set("nxball-to-item-44f636350009:#{nxball["uuid"]}", item["uuid"])
    end
end
