
# encoding: UTF-8

class Commands

    # Commands::commands()
    def self.commands()
        [
            "wave | anniversary | frame | today | ondate | todo | task | project ",
            "anniversaries | calendar | ondates | todos | projects",
            "<datecode> | <n> | run/.. (<n>) | start (<n>) | stop (<n>) | access (<n>) | landing (<n>) | pause (<n>) | pursue (<n>) | resume (<n>) | restart (<n>) | push (<n>) | redate (<n>) | done (<n>) | done for today | time * * | Ax39 | expose (<n>) | transmute | transmute (<n>) | destroy | >project | >nyx",
            "require internet",
            "rstream | search | nyx | speed | pickup | nxballs | indices | maintenance | >>",
        ].join("\n")
    end

    # Commands::run(input, store)
    def self.run(input, store) # [command or null, item or null]

        if Interpreting::match("..", input) then
            LxAction::action("run", store.getDefault())
            return
        end

        if Interpreting::match(".. *", input) then
            _, ordinal = Interpreting::tokenizer(input)
            item = store.get(ordinal.to_i)
            return if item.nil?
            LxAction::action("run", item)
            return
        end

        if Interpreting::match(">project", input) then
            item = store.getDefault()
            return if item.nil?
            if !["NxTask", "NxLine"].include?(item["mikuType"]) then
                puts "The operation >project only works on NxTasks and NxLines"
                LucilleCore::pressEnterToContinue()
                return
            end
            project = TxProjects::architectOneOrNull()
            return if project.nil?
            TxProjects::addElement_v1(project["uuid"], item["uuid"])
            NxBallsService::close(item["uuid"], true)
            return
        end

        if Interpreting::match(">nyx", input) then
            item = store.getDefault()
            return if item.nil?
            LxAction::action(">nyx", item.clone)
            return
        end

        if input == ">>" then
            item = store.getDefault()
            return if item.nil?
            section2 = JSON.parse(XCache::getOrDefaultValue("c52feab4-9bfb-4e73-a8f3-b39d90a055c3", "[]"))
            section2 = section2.select{|ix| ix["item"]["uuid"] != item["uuid"]}
            XCache::set("c52feab4-9bfb-4e73-a8f3-b39d90a055c3", JSON.generate(section2))
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
            Anniversaries::issueNewAnniversaryOrNullInteractively()
            return
        end

        if Interpreting::match("anniversaries", input) then
            Anniversaries::anniversariesDive()
            return
        end

        if Interpreting::match("Ax39 *", input) then
            _, ordinal = Interpreting::tokenizer(input)
            item = store.get(ordinal.to_i)
            return if item.nil?
            return if item["mikuType"] != "TxProject"
            Fx18Attributes::setAttribute2(item["uuid"], "repeatType",  JSON.generate(Ax39::interactivelyCreateNewAx()))
            return
        end

        if input == "pickup" then
            EditionDesk::batchPickUp_v2()
            return
        end

        if Interpreting::match("destroy", input) then
            LxAction::action("destroy", store.getDefault())
            return
        end

        if Interpreting::match("destroy *", input) then
            _, ordinal = Interpreting::tokenizer(input)
            item = store.get(ordinal.to_i)
            return if item.nil?
            LxAction::action("destroy", item)
            return
        end

        if Interpreting::match("done", input) then
            LxAction::action("done-no-confirmation-prompt", store.getDefault())
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

        if Interpreting::match("indices", input) then
            Fx18Index2PrimaryLookup::rebuildIndex()
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

        if input == "line" then
            line = LucilleCore::askQuestionAnswerAsString("line (empty to abort): ")
            return if line == ""
            item = NxLines::issue(line)
            TxProjects::interactivelyProposeToAttachTaskToProject(item)
            return
        end

        if Interpreting::match("maintenance", input) then
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

        if input == "project" then
            TxProjects::interactivelyIssueNewItemOrNull()
            return
        end

        if Interpreting::match("projects", input) then
            TxProjects::dive()
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

        if Interpreting::match("run", input) then
            LxAction::action("run", store.getDefault())
            return
        end

        if Interpreting::match("run *", input) then
            _, ordinal = Interpreting::tokenizer(input)
            item = store.get(ordinal.to_i)
            return if item.nil?
            LxAction::action("run", item)
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
            Streaming::rstreamToInfinity()
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

        if Interpreting::match("task", input) then
            item = NxTasks::interactivelyCreateNewOrNull()
            return if item.nil?
            TxProjects::interactivelyProposeToAttachTaskToProject(item)
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

        if input == "top" then
            system("open '#{Catalyst::topFilepath()}'")
            return
        end

        if Interpreting::match("transmute", input) then
            item = store.getDefault()
            return if item.nil?
            LxAction::action("transmute", item)
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
            Waves::issueNewWaveInteractivelyOrNull()
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
                    "name" => "Anniversaries::section2()",
                    "lambda" => lambda { Anniversaries::section2() }
                },
                {
                    "name" => "Waves::section2(true)",
                    "lambda" => lambda { Waves::section2(true) }
                },
                {
                    "name" => "Waves::section2(false)",
                    "lambda" => lambda { Waves::section2(false) }
                },
                {
                    "name" => "TxDateds::section2()",
                    "lambda" => lambda { TxDateds::section2() }
                },
                {
                    "name" => "TxProjects::section2()",
                    "lambda" => lambda { TxProjects::section2() }
                },
                {
                    "name" => "Streaming::section2()",
                    "lambda" => lambda { Streaming::section2() }
                },
                {
                    "name" => "NxLines::section2()",
                    "lambda" => lambda { NxLines::section2() }
                },
                {
                    "name" => "NxTasks::section2()",
                    "lambda" => lambda { NxTasks::section2() }
                },
                {
                    "name" => "The99Percent::getCurrentCount()",
                    "lambda" => lambda { The99Percent::getCurrentCount() }
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
