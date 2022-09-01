
# encoding: UTF-8

class Commands

    # Commands::commands()
    def self.commands()
        [
            "wave | anniversary | frame | today | ondate | todo | task | toplevel | incoming | line | planning",
            "anniversaries | ondates | todos | waves | frames | toplevels",
            ".. / <datecode> | <n> | start (<n>) | stop (<n>) | access (<n>) | landing (<n>) | pause (<n>) | pursue (<n>) | resume (<n>) | restart (<n>) | do not show until (<n>) | redate (<n>) | done (<n>) | done for today | edit (<n>) | time * * | expose (<n>) | destroy",
            ">owner | >owner (n) | >nyx | >planning",
            "planning set ordinal <n> | planning set timespan <n>",
            "require internet",
            "search | nyx | speed | nxballs | maintenance",
        ].join("\n")
    end

    # Commands::run(input, store)
    def self.run(input, store) # [command or null, item or null]

        if input == ".." then
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

        if Interpreting::match(">nyx", input) then
            item = store.getDefault()
            return if item.nil?
            LxAction::action(">nyx", item.clone)
            return
        end

        if Interpreting::match(">owner", input) then
            item = store.getDefault()
            return if item.nil?
            TxTimeCommitmentProjects::interactivelyAddThisElementToOwner(item)
            return
        end

        if Interpreting::match(">owner *", input) then
            _, ordinal = Interpreting::tokenizer(input)
            item = store.get(ordinal.to_i)
            return if item.nil?
            TxTimeCommitmentProjects::interactivelyAddThisElementToOwner(item)
            return
        end

        if Interpreting::match("access", input) then
            LxAccess::access(store.getDefault())
            return
        end

        if Interpreting::match("access *", input) then
            _, ordinal = Interpreting::tokenizer(input)
            item = store.get(ordinal.to_i)
            return if item.nil?
            LxAccess::access(item)
            return
        end

        if Interpreting::match("anniversary", input) then
            Anniversaries::issueNewAnniversaryOrNullInteractively()
            return
        end

        if Interpreting::match("anniversaries", input) then
            Anniversaries::anniversariesDive()
            return
        end

        if Interpreting::match("destroy", input) then
            LxAction::action("destroy-with-prompt", store.getDefault())
            return
        end

        if Interpreting::match("destroy *", input) then
            _, ordinal = Interpreting::tokenizer(input)
            item = store.get(ordinal.to_i)
            return if item.nil?
            LxAction::action("destroy-with-prompt", item)
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

        if input == "done for today" then
            item = store.getDefault()
            return if item.nil?
            DoneForToday::setDoneToday(item["uuid"])
            return
        end

        if Interpreting::match("edit", input) then
            item = store.getDefault()
            return if item.nil?
            DxF1Extended::edit(item)
            return
        end

        if Interpreting::match("edit *", input) then
            _, ordinal = Interpreting::tokenizer(input)
            item = store.get(ordinal.to_i)
            return if item.nil?
            DxF1Extended::edit(item)
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

        if Interpreting::match("frames", input) then
            NxFrames::dive()
            return
        end

        if Interpreting::match("help", input) then
            puts Commands::commands().yellow
            LucilleCore::pressEnterToContinue()
            return
        end

        if input == "incoming" then
            item = TxIncomings::interactivelyIssueNewLineOrNull()
            puts JSON.pretty_generate(item)
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

        if input == "line" then
            line = LucilleCore::askQuestionAnswerAsString("line (empty to abort): ")
            return if line == ""
            item = NxTasks::issueDescriptionOnly(line)
            TxTimeCommitmentProjects::interactivelyAddThisElementToOwner(item)
            return
        end

        if Interpreting::match("maintenance", input) then
            TxDateds::dive()
            return
        end

        if Interpreting::match("nyx", input) then
            Nyx::program()
            return
        end

        if Interpreting::match("nxballs", input) then
            puts JSON.pretty_generate(NxBallsIO::nxballs())
            LucilleCore::pressEnterToContinue()
            return
        end

        if Interpreting::match("ondate", input) then
            item = TxDateds::interactivelyCreateNewOrNull()
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

        if Interpreting::match("planning *", input) then
            _, ordinal = Interpreting::tokenizer(input)
            catalystitem = store.get(ordinal.to_i)
            return if catalystitem.nil?
            planningItem = MxPlanning::interactivelyIssueNewWithCatalystItem(catalystitem)
            puts JSON.pretty_generate(planningItem)
            return
        end

        if Interpreting::match("planning", input) then
            item = MxPlanning::interactivelyIssueNewLineOrNull()
            return if item.nil?
            puts JSON.pretty_generate(item)
            return
        end

        if Interpreting::match("planning set ordinal *", input) then
            _, _, _, o = Interpreting::tokenizer(input)
            item = store.get(o.to_i)
            return if item.nil?
            if item["mikuType"] != "MxPlanningDisplay" then
                puts "You can only do that on a MxPlanningDisplay which acts on behalf of a MxPlanning"
                LucilleCore::pressEnterToContinue()
                return
            end
            item2 = item["item"]
            item2["ordinal"] = MxPlanning::interactivelyDecideOrdinal()
            MxPlanning::commit(item2)
            return
        end

        if Interpreting::match("planning set timespan *", input) then
            _, _, _, o = Interpreting::tokenizer(input)
            item = store.get(o.to_i)
            return if item.nil?
            if item["mikuType"] != "MxPlanningDisplay" then
                puts "You can only do that on a MxPlanningDisplay which acts on behalf of a MxPlanning"
                LucilleCore::pressEnterToContinue()
                return
            end
            item2 = item["item"]
            item2["timespanInHour"] = MxPlanning::interactivelyDecideTimespanInHours()
            MxPlanning::commit(item2)
            return
        end

        if Interpreting::match("pursue", input) then
            item = store.getDefault()
            return if item.nil?
            NxBallsService::carryOn(item["uuid"])
            return
        end

        if Interpreting::match("pursue *", input) then
            _, ordinal = Interpreting::tokenizer(input)
            item = store.get(ordinal.to_i)
            return if item.nil?
            NxBallsService::carryOn(item["uuid"])
            return
        end

        if Interpreting::match("resume", input) then
            item = store.getDefault()
            return if item.nil?
            NxBallsService::carryOn(item["uuid"])
            return
        end

        if Interpreting::match("resume *", input) then
            _, ordinal = Interpreting::tokenizer(input)
            item = store.get(ordinal.to_i)
            return if item.nil?
            NxBallsService::carryOn(item["uuid"])
            return
        end

        if Interpreting::match("restart", input) then
            item = store.getDefault()
            return if item.nil?
            NxBallsService::carryOn(item["uuid"])
            return
        end

        if Interpreting::match("restart *", input) then
            _, ordinal = Interpreting::tokenizer(input)
            item = store.get(ordinal.to_i)
            return if item.nil?
            NxBallsService::carryOn(item["uuid"])
            return
        end

        if Interpreting::match("do not show until *", input) then
            _, _, _, _, ordinal = Interpreting::tokenizer(input)
            item = store.get(ordinal.to_i)
            return if item.nil?
            datecode = LucilleCore::askQuestionAnswerAsString("datecode: ")
            return if datecode == ""
            unixtime = CommonUtils::codeToUnixtimeOrNull(datecode.gsub(" ", ""))
            return if unixtime.nil?
            LxAction::action("stop", item)
            DoNotShowUntil::setUnixtime(item["uuid"], unixtime)
            return
        end

        if Interpreting::match("redate", input) then
            item = store.getDefault()
            return if item.nil?
            LxAction::action("redate", item)
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
            Search::run(isSearchAndSelect = false)
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

        if Interpreting::match("task", input) then
            item = NxTasks::interactivelyCreateNewOrNull(true)
            return if item.nil?
            if item["ax39"].nil? then
                TxTimeCommitmentProjects::interactivelyAddThisElementToOwner(item)
            end
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
            TxDateds::interactivelyCreateNewTodayOrNull()
            return
        end

        if input == "toplevel" then
            item = TopLevel::interactivelyIssueNew()
            puts JSON.pretty_generate(item)
            return
        end

        if input == "toplevels" then
            TopLevel::dive()
            return
        end

        if input == "wave" then
            Waves::issueNewWaveInteractivelyOrNull()
            return
        end

        if input == "waves" then
            Waves::dive()
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
                    "lambda" => lambda { JSON.parse(`#{Config::userHomeDirectory()}/Galaxy/Binaries/fitness ns16s`) }
                },
                {
                    "name" => "Anniversaries::listingItems()",
                    "lambda" => lambda { Anniversaries::listingItems() }
                },
                {
                    "name" => "MxPlanning::listingItems()",
                    "lambda" => lambda { MxPlanning::listingItems() }
                },
                {
                    "name" => "NxTasks::listingItems()",
                    "lambda" => lambda { NxTasks::listingItems() }
                },
                {
                    "name" => "Streaming::listingItems()",
                    "lambda" => lambda { Streaming::listingItems() }
                },
                {
                    "name" => "TopLevel::items()",
                    "lambda" => lambda { TopLevel::items() }
                },
                {
                    "name" => "TxDateds::listingItems()",
                    "lambda" => lambda { TxDateds::listingItems() }
                },
                {
                    "name" => "TxIncomings::listingItems()",
                    "lambda" => lambda { TxIncomings::listingItems() }
                },
                {
                    "name" => "TxTimeCommitmentProjects::listingItems()",
                    "lambda" => lambda { TxTimeCommitmentProjects::listingItems() }
                },
                {
                    "name" => "The99Percent::getCurrentCount()",
                    "lambda" => lambda { The99Percent::getCurrentCount() }
                },
                {
                    "name" => "Waves::listingItems(true)",
                    "lambda" => lambda { Waves::listingItems(true) }
                },
                {
                    "name" => "Waves::listingItems(false)",
                    "lambda" => lambda { Waves::listingItems(false) }
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
                            puts "running: #{test["name"]}"
                            t1 = Time.new.to_f
                            (1..3).each{ test["lambda"].call() }
                            t2 = Time.new.to_f
                            {
                                "name" => test["name"],
                                "runtime" => (t2 - t1).to_f/3
                            }
                        }
                        .sort{|r1, r2| r1["runtime"] <=> r2["runtime"] }
                        .reverse

            puts ""
            results
                .each{|result|
                    puts "- #{result["name"].ljust(padding)} : #{"%6.3f" % result["runtime"]}"
                }

            LucilleCore::pressEnterToContinue()
            return
        end
    end
end
