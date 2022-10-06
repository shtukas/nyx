# encoding: UTF-8

class CatalystGroupMonitor
    def initialize()
        @lx13 = []
        @lx13 = XCacheValuesWithExpiry::getOrNull("abc03773-bdca-4c5d-86e9-92a253f3e23a")
        if @lx13.nil? then
            rebuildLx13sFromScratch()
        end
        Thread.new {
            loop {
                sleep 300
                rebuildLx13sFromScratch()
            }
        }
    end

    def getLx13sForDisplay()
        @lx13
            .select{|packet| packet["cr"] < 1 }
            .select{|packet| 
                bankaccount = packet["bankaccount"]
                !BankAccountDoneForToday::isDoneToday(bankaccount) 
            }
            .sort{|p1, p2| p1["cr"] <=> p2["cr"] }
    end

    def rebuildLx13sFromScratch()
        @lx13 = Cx22::getLx13s()
        XCacheValuesWithExpiry::set("abc03773-bdca-4c5d-86e9-92a253f3e23a", @lx13, nil)
    end
end

class CatalystListing

    # CatalystListing::listingCommands()
    def self.listingCommands()
        [
            ".. | <datecode> | <n> | start (<n>) | stop (<n>) | access (<n>) | description (<n>) | name (<n>) | datetime (<n>) | nx113 (<n>) | engine (<n>) | contribution (<n>) | cx23 (group position) | landing (<n>) | pause (<n>) | pursue (<n>) | do not show until <n> | redate (<n>) | done (<n>) | group done for today | edit (<n>) | transmute (<n>) | time * * | expose (<n>) | destroy",
            "update start date (<n>)",
            "wave | anniversary | hot | today | ondate | todo",
            "anniversaries | ondates | todos | waves | groups",
            "require internet",
            "search | nyx | speed | nxballs",
        ].join("\n")
    end

    # CatalystListing::listingCommandInterpreter(input, store)
    def self.listingCommandInterpreter(input, store)

        if input.start_with?("+") and (unixtime = CommonUtils::codeToUnixtimeOrNull(input.gsub(" ", ""))) then
            if (item = store.getDefault()) then
                PolyActions::stop(item)
                DoNotShowUntil::setUnixtime(item["uuid"], unixtime)
                return
            end
        end

        if input == ".." then
            item = store.getDefault()
            return if item.nil?
            PolyActions::doubleDot(item)
            return
        end

        if Interpreting::match(".. *", input) then
            _, ordinal = Interpreting::tokenizer(input)
            item = store.get(ordinal.to_i)
            return if item.nil?
            PolyActions::doubleDot(item)
            return
        end

        if Interpreting::match("access", input) then
            item = store.getDefault()
            return if item.nil?
            PolyActions::access(item)
            return
        end

        if Interpreting::match("access *", input) then
            _, ordinal = Interpreting::tokenizer(input)
            item = store.get(ordinal.to_i)
            return if item.nil?
            PolyActions::access(item)
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

        if Interpreting::match("contribution", input) then
            item = store.getDefault()
            return if item.nil?
            Cx22::interactivelySetANewContributionForItemOrNothing(item)
            return
        end

        if Interpreting::match("contribution *", input) then
            _, ordinal = Interpreting::tokenizer(input)
            item = store.get(ordinal.to_i)
            return if item.nil?
            Cx22::interactivelySetANewContributionForItemOrNothing(item)
            return
        end

        if Interpreting::match("cx23", input) then
            item = store.getDefault()
            return if item.nil?
            Cx23::interactivelySetCx23ForItemOrNothing(item)
            return
        end

        if Interpreting::match("cx23 *", input) then
            _, ordinal = Interpreting::tokenizer(input)
            item = store.get(ordinal.to_i)
            return if item.nil?
            Cx23::interactivelySetCx23ForItemOrNothing(item)
            return
        end

        if Interpreting::match("destroy", input) then
            item = store.getDefault()
            return if item.nil?
            PolyActions::destroyWithPrompt(item)
            return
        end

        if Interpreting::match("destroy *", input) then
            _, ordinal = Interpreting::tokenizer(input)
            item = store.get(ordinal.to_i)
            return if item.nil?
            PolyActions::destroyWithPrompt(item)
            return
        end

        if Interpreting::match("datetime", input) then
            item = store.getDefault()
            return if item.nil?
            PolyActions::editDatetime(item)
            return
        end

        if Interpreting::match("datetime *", input) then
            _, ordinal = Interpreting::tokenizer(input)
            item = store.get(ordinal.to_i)
            return if item.nil?
            PolyActions::editDatetime(item)
            return
        end

        if Interpreting::match("description", input) then
            item = store.getDefault()
            return if item.nil?
            PolyActions::editDescription(item)
            return
        end

        if Interpreting::match("description *", input) then
            _, ordinal = Interpreting::tokenizer(input)
            item = store.get(ordinal.to_i)
            return if item.nil?
            PolyActions::editDescription(item)
            return
        end

        if Interpreting::match("done", input) then
            item = store.getDefault()
            return if item.nil?
            PolyActions::done(item)
            return
        end

        if Interpreting::match("done *", input) then
            _, ordinal = Interpreting::tokenizer(input)
            item = store.get(ordinal.to_i)
            return if item.nil?
            PolyActions::done(item)
            return
        end

        if Interpreting::match("edit", input) then
            item = store.getDefault()
            return if item.nil?
            PolyFunctions::edit(item)
            return
        end

        if Interpreting::match("edit *", input) then
            _, ordinal = Interpreting::tokenizer(input)
            item = store.get(ordinal.to_i)
            return if item.nil?
            PolyFunctions::edit(item)
            return
        end

        if Interpreting::match("engine", input) then
            item = store.getDefault()
            return if item.nil?
            Nx11E::interactivelySetANewEngineForItemOrNothing(item)
            return
        end

        if Interpreting::match("engine *", input) then
            _, ordinal = Interpreting::tokenizer(input)
            item = store.get(ordinal.to_i)
            return if item.nil?
            Nx11E::interactivelySetANewEngineForItemOrNothing(item)
            return
        end

        if Interpreting::match("exit", input) then
            exit
        end

        if Interpreting::match("expose", input) then
            item = store.getDefault()
            return if item.nil?
            puts JSON.pretty_generate(item)
            if item["mikuType"] == "NxBall.v2" then
                LucilleCore::pressEnterToContinue()
                return
            end
            puts "PolyFunctions::listingPriorityOrNull(item): #{PolyFunctions::listingPriorityOrNull(item)}"
            LucilleCore::pressEnterToContinue()
            return
        end

        if Interpreting::match("expose *", input) then
            _, ordinal = Interpreting::tokenizer(input)
            item = store.get(ordinal.to_i)
            return if item.nil?
            puts JSON.pretty_generate(item)
            if item["mikuType"] == "NxBall.v2" then
                LucilleCore::pressEnterToContinue()
                return
            end
            puts "PolyFunctions::listingPriorityOrNull(item): #{PolyFunctions::listingPriorityOrNull(item)}"
            LucilleCore::pressEnterToContinue()
            return
        end

        if input == "group done for today" then
            item = store.getDefault()
            return if item.nil?

            return if item["cx22"].nil?

            bankaccount = item["cx22"]["bankaccount"]
            BankAccountDoneForToday::setDoneToday(bankaccount)
            return
        end

        if Interpreting::match("groups", input) then
            Cx22::repsDive()
            return
        end

        if Interpreting::match("hot", input) then
            description = LucilleCore::askQuestionAnswerAsString("hot: ")
            item = NxTodos::interactivelyCreateNewHot(description)
            puts JSON.pretty_generate(item)
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
            PolyPrograms::itemLanding(store.getDefault())
            return
        end

        if Interpreting::match("landing *", input) then
            _, ordinal = Interpreting::tokenizer(input)
            item = store.get(ordinal.to_i)
            return if item.nil?
            PolyPrograms::itemLanding(item)
            return
        end

        if Interpreting::match("nx113", input) then
            item = store.getDefault()
            return if item.nil?
            PolyActions::setNx113(item)
            return
        end

        if Interpreting::match("nx113 *", input) then
            _, ordinal = Interpreting::tokenizer(input)
            item = store.get(ordinal.to_i)
            return if item.nil?
            PolyActions::setNx113(item)
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
            item = NxTodos::interactivelyCreateNewOndateOrNull()
            return if item.nil?
            puts JSON.pretty_generate(item)
            return
        end

        if Interpreting::match("ondates", input) then
            NxTodos::diveOndates()
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
            puts "pursuing: #{JSON.pretty_generate(item)}"
            NxBallsService::pursue(item["uuid"])
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
            PolyActions::stop(item)
            DoNotShowUntil::setUnixtime(item["uuid"], unixtime)
            return
        end

        if Interpreting::match("require internet", input) then
            item = store.getDefault()
            return if item.nil?
            InternetStatus::markIdAsRequiringInternet(item["uuid"])
            return
        end

        if Interpreting::match("redate", input) then
            item = store.getDefault()
            return if item.nil?
            PolyActions::redate(item)
            return
        end

        if Interpreting::match("redate *", input) then
            _, ordinal = Interpreting::tokenizer(input)
            item = store.get(ordinal.to_i)
            return if item.nil?
            PolyActions::redate(item)
            return
        end

        if Interpreting::match("search", input) then
            Search::navigation()
            return
        end

        if Interpreting::match("start", input) then
            item = store.getDefault()
            return if item.nil?
            PolyActions::start(item)
            return
        end

        if Interpreting::match("start *", input) then
            _, ordinal = Interpreting::tokenizer(input)
            item = store.get(ordinal.to_i)
            return if item.nil?
            PolyActions::start(item)
            return
        end

        if Interpreting::match("stop", input) then
            item = store.getDefault()
            return if item.nil?
            PolyActions::stop(item)
            return
        end

        if Interpreting::match("stop *", input) then
            _, ordinal = Interpreting::tokenizer(input)
            item = store.get(ordinal.to_i)
            return if item.nil?
            PolyActions::stop(item)
            return
        end

        if Interpreting::match("time * *", input) then
            _, ordinal, timeInHours = Interpreting::tokenizer(input)
            item = store.get(ordinal.to_i)
            return if item.nil?
            puts "Adding #{timeInHours.to_f} hours to #{PolyFunctions::toString(item).green}"
            Bank::put(item["uuid"], timeInHours.to_f*3600)
            if item["cx22"] then
                bankaccount = item["cx22"]["bankaccount"] # Contribution
                puts "Adding (Cx22, contributions) #{timeInHours.to_f} hours to bank account #{bankaccount}"
                Bank::put(bankaccount, timeInHours.to_f*3600)
            end
            return
        end

        if Interpreting::match("today", input) then
            NxTodos::interactivelyCreateNewTodayOrNull()
            return
        end

        if Interpreting::match("todo", input) then
            item = NxTodos::interactivelyCreateNewOrNull()
            return if item.nil?
            puts JSON.pretty_generate(item)
            return
        end

        if input == "transmute" then
            item = store.getDefault()
            return if item.nil?
            PolyActions::transmute(item)
            return
        end

        if input == "transmute *" then
            _, ordinal = Interpreting::tokenizer(input)
            item = store.get(ordinal.to_i)
            return if item.nil?
            PolyActions::transmute(item)
            return
        end

        if Interpreting::match("update start date", input) then
            item = store.getDefault()
            return if item.nil?
            PolyActions::editStartDate(item)
        end

        if Interpreting::match("update start date *", input) then
            _, ordinal = Interpreting::tokenizer(input)
            item = store.get(ordinal.to_i)
            return if item.nil?
            PolyActions::editStartDate(item)
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
                    "name" => "Anniversaries::listingItems()",
                    "lambda" => lambda { Anniversaries::listingItems() }
                },
                {
                    "name" => "The99Percent::getCurrentCount()",
                    "lambda" => lambda { The99Percent::getCurrentCount() }
                },
                {
                    "name" => "EndOfDayChecklist::listingItems()",
                    "lambda" => lambda { EndOfDayChecklist::listingItems() }
                },
                {
                    "name" => "NxTodos::itemsInDisplayOrder(Cx22::getNonDoneForTodayRepWithLowersCRBelow1OrNull()).first(100)",
                    "lambda" => lambda { NxTodos::itemsInDisplayOrder(Cx22::getNonDoneForTodayRepWithLowersCRBelow1OrNull()).first(100) }
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

    # CatalystListing::listingItems()
    def self.listingItems()
        [
            Anniversaries::listingItems(),
            TxManualCountDowns::listingItems(),
            Waves::items(),
            EndOfDayChecklist::listingItems(),
            NxTodos::itemsInDisplayOrder(Cx22::getNonDoneForTodayRepWithLowersCRBelow1OrNull()).first(100)
        ]
            .flatten
            .select{|item| DoNotShowUntil::isVisible(item["uuid"]) or NxBallsService::isPresent(item["uuid"]) }
            .select{|item| InternetStatus::itemShouldShow(item["uuid"]) or NxBallsService::isPresent(item["uuid"]) }
            .sort{|i1, i2| (PolyFunctions::listingPriorityOrNull(i1) || 0) <=> (PolyFunctions::listingPriorityOrNull(i2) || 0) }
            .reverse
    end

    # CatalystListing::displayListing()
    def self.displayListing()

        system("clear")

        vspaceleft = CommonUtils::screenHeight() - 4

        vspaceleft =  vspaceleft - CommonUtils::verticalSize(CatalystListing::listingCommands())

        if Config::get("instanceId") == "Lucille20-pascal" then
            reference = The99Percent::getReferenceOrNull()
            current   = The99Percent::getCurrentCount()
            ratio     = current.to_f/reference["count"]
            line      = "👩‍💻 🔥 #{current} #{ratio} ( #{reference["count"]} @ #{reference["datetime"]} )"
            puts ""
            puts line
            vspaceleft = vspaceleft - 2
            if ratio < 0.99 then
                The99Percent::issueNewReferenceOrNull()
            end
        end

        store = ItemStore.new()

        if !InternetStatus::internetIsActive() then
            puts ""
            puts "INTERNET IS OFF".green
            vspaceleft = vspaceleft - 2
        end

        packets = $CatalystGroupMonitor1.getLx13sForDisplay()
        if packets.size > 0 then
            puts ""
            puts "Cx22 (Contribution Groups) below completion 1:".yellow
            vspaceleft = vspaceleft - 2
            packets
                .each{|packet|
                    puts "    - #{packet["groupname"]} (#{packet["cr"].round(2)})".yellow
                    vspaceleft = vspaceleft - 1
                }
        end

        nxballs = NxBallsIO::nxballs()
        if nxballs.size > 0 then
            puts ""
            vspaceleft = vspaceleft - 1
            nxballs
                .sort{|t1, t2| t1["unixtime"] <=> t2["unixtime"] }
                .each{|nxball|
                    store.register(nxball, false)
                    line = "#{store.prefixString()} [NxBall] #{nxball["description"]} (#{NxBallsService::activityStringOrEmptyString("", nxball["uuid"], "")})"
                    puts line.green
                    vspaceleft = vspaceleft - CommonUtils::verticalSize(line)
                }
        end

        puts ""
        vspaceleft = vspaceleft - 1

        CatalystListing::listingItems()
            .each{|item|
                break if vspaceleft <= 0
                store.register(item, true)
                line = "#{store.prefixString()} #{PolyFunctions::toString(item)}"
                if NxBallsService::isPresent(item["uuid"]) then
                    line = "#{line} (#{NxBallsService::activityStringOrEmptyString("", item["uuid"], "")})".green
                end
                puts line
                vspaceleft = vspaceleft - CommonUtils::verticalSize(line)
            }

        puts ""
        puts CatalystListing::listingCommands().yellow
        puts ""
        input = LucilleCore::askQuestionAnswerAsString("> ")
        return if input == ""
        CatalystListing::listingCommandInterpreter(input, store)
    end

    # CatalystListing::program()
    def self.program()

        initialCodeTrace = CommonUtils::generalCodeTrace()

        loop {

            #puts "(code trace)"
            if CommonUtils::generalCodeTrace() != initialCodeTrace then
                puts "Code change detected"
                break
            end

            SystemEvents::processIncomingEventsFromLine(true)

            LucilleCore::locationsAtFolder("#{ENV['HOME']}/Galaxy/DataHub/NxTodos-BufferIn")
                .each{|location|
                    next if File.basename(location).start_with?(".")
                    item = NxTodos::issueUsingLocation(location)
                    puts "Picked up from NxTodos: #{JSON.pretty_generate(item)}"
                    LucilleCore::removeFileSystemLocation(location)
                }

            CatalystListing::displayListing()
        }
    end
end
