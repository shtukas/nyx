
# encoding: UTF-8

class Commands

    # Commands::commands()
    def self.commands()
        [
            "wave | anniversary | frame | ship | ship: <line> | today | ondate | ondate: <line> | todo | todo: <line>",
            "anniversaries | calendar | zeroes | ondates | todos",
            "<datecode> | <n> | .. (<n>) | expose (<n>) | Ax38 | transmute (<n>) | start (<n>) | search | nyx | >nyx",
            "require internet",
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
            return if item["mikuType"] != "NxShip"
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

        if Interpreting::match("frame", input) then
            NxFrames::interactivelyCreateNewOrNull()
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

        if Interpreting::match("nyx", input) then
            Nyx::program()
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

        if Interpreting::match("ship", input) then
            item = NxShip::interactivelyIssueNewOrNull()
            return if item.nil?
            puts JSON.pretty_generate(item)
            return
        end

        if input.start_with?("ship:") then
            message = input[5, input.length].strip
            item = NxShip::interactivelyIssueNewOrNull(message)
            return if item.nil?
            puts JSON.pretty_generate(item)
            return
        end

        if Interpreting::match("ships", input) then
            NxShip::dive()
            return
        end

        if Interpreting::match("speed", input) then

            tests = [
                {
                    "name" => "source code trace generation",
                    "lambda" => lambda { CommonUtils::generalCodeTrace() }
                },
                {
                    "name" => "fitness lookup",
                    "lambda" => lambda { JSON.parse(`/Users/pascal/Galaxy/LucilleOS/Binaries/fitness ns16s`) }
                },
                {
                    "name" => "Anniversaries::itemsForListing()",
                    "lambda" => lambda { Anniversaries::itemsForListing() }
                },
                {
                    "name" => "Waves::itemsForListing()",
                    "lambda" => lambda { Waves::itemsForListing() }
                },
                {
                    "name" => "TxDateds::itemsForListing()",
                    "lambda" => lambda { TxDateds::itemsForListing() }
                },
                {
                    "name" => "NxShip::itemsForListing()",
                    "lambda" => lambda { NxShip::itemsForListing() }
                },
            ]

            # dry run to initialise things
            tests
                .each{|test|
                    test["lambda"].call()
                }

            padding = tests.map{|test| test["name"].size }.max

            results = tests
                        .map{|test|
                            t1 = Time.new.to_f
                            test["lambda"].call()
                            t2 = Time.new.to_f
                            {
                                "name" => test["name"],
                                "runtime" => t2 - t1
                            }
                        }
                        .sort{|r1, r2| r1["runtime"] <=> r2["runtime"] }
                        .reverse
                        .each{|result|
                            puts "- #{result["name"].ljust(padding)} : #{"%6.3f" % result["runtime"]}"
                        }

            LucilleCore::pressEnterToContinue()
            return
        end
    end
end
