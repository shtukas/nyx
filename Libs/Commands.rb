
# encoding: UTF-8

class Commands

    # Commands::commands()
    def self.commands()
        [
            "wave | anniversary | float | zero | zero: <line> | today | ondate | ondate: <line> | todo | todo: <line> | flotille | make ship <flotille-indx> <item-indx>",
            "anniversaries | calendar | zeroes | ondates | todos",
            "<datecode> | <n> | .. (<n>) | expose (<n>) | transmute (<n>) | start (<n>) | search | nyx | >nyx",
            "require internet",
            "pull (download and process event from the other machine)",
            "ordinal line | ordinal item"
        ].join("\n")
    end

    # Commands::run(input, store)
    def self.run(input, store) # [command or null, item or null]

        if Interpreting::match("..", input) then
            LxAction::action("..", store.getDefault())
            return
        end

        if Interpreting::match(".. *", input) then
            _, ordinal = Interpreting::tokenizer(input)
            item = store.get(ordinal.to_i)
            return if item.nil?
            LxAction::action("..", item)
            return
        end

        if Interpreting::match(">todo", input) then
            LxAction::action(">todo", store.getDefault())
            return
        end

        if Interpreting::match(">nyx", input) then
            LxAction::action(">nyx", store.getDefault())
            return
        end

        if Interpreting::match("access", input) then
            LxAction::action("access", store.getDefault())
            return
        end

        if Interpreting::match("access *", input) then
            _, ordinal = Interpreting::tokenizer(input)
            item = store.get(ordinal.to_i)
            return if item.nil?
            LxAction::action("access", item)
            return
        end

        if Interpreting::match("anniversary", input) then
            item = Anniversaries::issueNewAnniversaryOrNullInteractively()
            return if item.nil?
            puts JSON.pretty_generate(item)
            return
        end

        if Interpreting::match("anniversaries", input) then
            Anniversaries::anniversariesDive()
            return
        end

        if Interpreting::match("Ax38", input) then
            item = store.getDefault()
            return if item.nil?
            return if item["mikuType"] != "TxZero"
            item["ax38"] = Ax38::interactivelyCreateNewAxOrNull()
            Librarian::commit(item)
            return
        end

        if Interpreting::match("destroy", input) then
            LxAction::action("destroy", store.getDefault())
            return
        end

        if Interpreting::match("done", input) then
            LxAction::action("done", store.getDefault())
            return
        end

        if Interpreting::match("done *", input) then
            _, ordinal = Interpreting::tokenizer(input)
            item = store.get(ordinal.to_i)
            return if item.nil?
            LxAction::action("done", item)
            return
        end

        if Interpreting::match("exit", input) then
            exit
        end

        if Interpreting::match("expose", input) then
            puts JSON.pretty_generate(store.getDefault())
            LucilleCore::pressEnterToContinue()
            return
        end

        if Interpreting::match("expose *", input) then
            _, ordinal = Interpreting::tokenizer(input)
            item = store.get(ordinal.to_i)
            return if item.nil?
            puts JSON.pretty_generate(item)
            LucilleCore::pressEnterToContinue()
            return
        end

        if Interpreting::match("float", input) then
            TxFloats::interactivelyCreateNewOrNull()
            return
        end

        if Interpreting::match("flotille", input) then
            NxFlotilles::interactivelyIssueNewItemOrNull()
            return
        end

        if Interpreting::match("help", input) then
            puts Commands::commands().yellow
            LucilleCore::pressEnterToContinue()
            return
        end

        if Interpreting::match("internet off", input) then
            InternetStatus::setInternetOff()
            return
        end

        if Interpreting::match("internet on", input) then
            InternetStatus::setInternetOn()
            return
        end

        if Interpreting::match("landing", input) then
            LxAction::action("landing", store.getDefault())
            return
        end

        if Interpreting::match("landing *", input) then
            _, ordinal = Interpreting::tokenizer(input)
            item = store.get(ordinal.to_i)
            return if item.nil?
            LxAction::action("landing", item)
            return
        end

        if Interpreting::match("make ship * *", input) then
            _, _, flotilleIndx, itemIdex = Interpreting::tokenizer(input)
            flotilleIndx = flotilleIndx.to_i
            itemIdex = itemIdex.to_i
            flotille = store.get(flotilleIndx)
            return if flotille.nil?
            return if flotille["mikuType"] != "NxFlotille"
            item = store.get(itemIdex)
            return if item.nil?
            ship = NxShips::issue(flotille["uuid"], item["uuid"])
            puts JSON.pretty_generate(ship)
            return
        end

        if Interpreting::match("nyx", input) then
            system("nyx")
            return
        end

        if Interpreting::match("ondate", input) then
            item = TxDateds::interactivelyCreateNewOrNull()
            return if item.nil?
            puts JSON.pretty_generate(item)
            return
        end

        if input.start_with?("ondate:") then
            message = input[7, input.length].strip
            item = TxDateds::interactivelyCreateNewOrNull(message)
            return if item.nil?
            puts JSON.pretty_generate(item)
            return
        end

        if Interpreting::match("ondates", input) then
            TxDateds::dive()
            return
        end

        if Interpreting::match("ordinal line", input) then
            line = LucilleCore::askQuestionAnswerAsString("line : ")
            ordinal = LucilleCore::askQuestionAnswerAsString("ordinal: ").to_f
            item = NxOrdinals::issueCarrier(line, ordinal)
            puts JSON.pretty_generate(item)
            return
        end 

        if Interpreting::match("ordinal item", input) then
            indx = LucilleCore::askQuestionAnswerAsString("index : ")
            item = store.get(indx.to_i)
            return if item.nil?
            ordinal = LucilleCore::askQuestionAnswerAsString("ordinal: ").to_f
            if item["mikuType"] == "NxOrdinal" then
                item["ordinal"] = ordinal
                XCacheSets::set("862f6f8e-e312-4163-81b4-7983d87731a6", item["uuid"], item)
                return
            end
            # Let's look for any existing nxordinals pointing at this item
            NxOrdinals::items()
                .select{|ix| ix["type"] == "pointer" }
                .select{|ix| ix["target"] == item["uuid"] }
                .each{|ix| XCacheSets::destroy("862f6f8e-e312-4163-81b4-7983d87731a6", ix["uuid"]) }
            item = NxOrdinals::issuePointer(item, ordinal)
            puts JSON.pretty_generate(item)
            return
        end

        if Interpreting::match("ordinal off", input) then
            indx = LucilleCore::askQuestionAnswerAsString("index : ")
            item = store.get(indx.to_i)
            return if item.nil?
            return if item["mikuType"] != "NxOrdinal"
            XCacheSets::destroy("862f6f8e-e312-4163-81b4-7983d87731a6", item["uuid"])
            return
        end 

        if Interpreting::match("pause", input) then
            item = store.getDefault()
            return if item.nil?
            NxBallsService::pause(item["uuid"])
            return
        end

        if Interpreting::match("pause *", input) then
            _, ordinal = Interpreting::tokenizer(input)
            item = store.get(ordinal.to_i)
            return if item.nil?
            NxBallsService::pause(item["uuid"])
            return
        end

        if Interpreting::match("pull", input) then
            SyncOperators::clientRunOnce(true)
            return
        end

        if Interpreting::match("pursue", input) then
            item = store.getDefault()
            return if item.nil?
            NxBallsService::pursue(item["uuid"])
            return
        end

        if Interpreting::match("pursue *", input) then
            _, ordinal = Interpreting::tokenizer(input)
            item = store.get(ordinal.to_i)
            return if item.nil?
            NxBallsService::pursue(item["uuid"])
            return
        end

        if Interpreting::match("push *", input) then
            _, ordinal = Interpreting::tokenizer(input)
            item = store.get(ordinal.to_i)
            return if item.nil?
            datecode = LucilleCore::askQuestionAnswerAsString("datecode: ")
            return if datecode == ""
            unixtime = CommonUtils::codeToUnixtimeOrNull(datecode.gsub(" ", ""))
            return if unixtime.nil?
            NxBallsService::close(item["uuid"], true)
            DoNotShowUntil::setUnixtime(item["uuid"], unixtime)
            return
        end

        if Interpreting::match("rstream", input) then
            Streaming::rstream()
            return
        end

        if Interpreting::match("redate", input) then
            LxAction::action("redate", store.getDefault())
            return
        end

        if Interpreting::match("redate *", input) then
            _, ordinal = Interpreting::tokenizer(input)
            item = store.get(ordinal.to_i)
            return if item.nil?
            LxAction::action("redate", item)
            return
        end

        if Interpreting::match("require internet", input) then
            item = store.getDefault()
            return if item.nil?
            InternetStatus::markIdAsRequiringInternet(item["uuid"])
            return
        end

        if Interpreting::match("search", input) then
            Search::classicInterface()
            return
        end

        if Interpreting::match("start", input) then
            LxAction::action("start", store.getDefault())
            return
        end

        if Interpreting::match("start *", input) then
            _, ordinal = Interpreting::tokenizer(input)
            item = store.get(ordinal.to_i)
            return if item.nil?
            LxAction::action("start", item)
            return
        end

        if Interpreting::match("stop", input) then
            LxAction::action("stop", store.getDefault())
            return
        end

        if Interpreting::match("stop *", input) then
            _, ordinal = Interpreting::tokenizer(input)
            item = store.get(ordinal.to_i)
            return if item.nil?
            LxAction::action("stop", item)
            return
        end

        if Interpreting::match("time * *", input) then
            _, ordinal, timeInHours = Interpreting::tokenizer(input)
            item = store.get(ordinal.to_i)
            return if item.nil?
            puts "Adding #{timeInHours.to_f} hours to #{LxFunction::function("toString", item).green}"
            Bank::put(item["uuid"], timeInHours.to_f*3600)
            return
        end

        if Interpreting::match("today", input) then
            item = TxDateds::interactivelyCreateNewTodayOrNull()
            return if item.nil?
            puts JSON.pretty_generate(item)
            return
        end

        if input.start_with?("today:") then
            message = input[6, input.length].strip
            item = TxDateds::interactivelyCreateNewTodayOrNull(message)
            return if item.nil?
            puts JSON.pretty_generate(item)
            return
        end

        if Interpreting::match("todo", input) then
            item = TxTodos::interactivelyCreateNewOrNull()
            return if item.nil?
            puts JSON.pretty_generate(item)
            return
        end

        if input.start_with?("todo:") then
            message = input[5, input.length].strip
            item = TxTodos::interactivelyCreateNewOrNull(message)
            return if item.nil?
            puts JSON.pretty_generate(item)
            return
        end

        if Interpreting::match("transmute", input) then
            LxAction::action("transmute", store.getDefault())
            return
        end

        if Interpreting::match("transmute *", input) then
            _, ordinal = Interpreting::tokenizer(input)
            item = store.get(ordinal.to_i)
            return if item.nil?
            LxAction::action("transmute", item)
            return
        end

        if input.start_with?("wave") then
            item = Waves::issueNewWaveInteractivelyOrNull()
            return if item.nil?
            puts JSON.pretty_generate(item)
            return
        end

        if Interpreting::match("zero", input) then
            item = TxZero::interactivelyIssueNewOrNull()
            return if item.nil?
            puts JSON.pretty_generate(item)
            return
        end

        if input.start_with?("zero:") then
            message = input[5, input.length].strip
            item = TxZero::interactivelyIssueNewOrNull(message)
            return if item.nil?
            puts JSON.pretty_generate(item)
            return
        end

        if Interpreting::match("zeroes", input) then
            TxZero::dive()
            return
        end
    end
end
