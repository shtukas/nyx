# encoding: UTF-8

class CatalystListing

    # CatalystListing::listingCommands()
    def self.listingCommands()
        [
            ".. | <datecode> | <n> | start (<n>) | stop (<n>) | access (<n>) | description (<n>) | name (<n>) | datetime (<n>) | nx113 (<n>) | landing (<n>) | pause (<n>) | pursue (<n>) | do not show until <n> | redate (<n>) | done (<n>) | done for today | edit (<n>) | transmute (<n>) | time * * | expose (<n>) | destroy",
            "update start date (<n>)",
            "wave | anniversary | today | ondate | todo | task | toplevel | inbox | line",
            "anniversaries | ondates | todos | waves | tc",
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

        if input == "done for today" then
            item = store.getDefault()
            return if item.nil?
            DoneForToday::setDoneToday(item["uuid"])
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

        if Interpreting::match("exit", input) then
            exit
        end

        if Interpreting::match("expose", input) then
            item = store.getDefault()
            return if item.nil?
            puts JSON.pretty_generate(item)
            puts "PolyFunctions::listingPriority(item): #{PolyFunctions::listingPriority(item)}"
            LucilleCore::pressEnterToContinue()
            return
        end

        if Interpreting::match("expose *", input) then
            _, ordinal = Interpreting::tokenizer(input)
            item = store.get(ordinal.to_i)
            return if item.nil?
            puts JSON.pretty_generate(item)
            puts "PolyFunctions::listingPriority(item): #{PolyFunctions::listingPriority(item)}"
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

        if input == "line" then
            line = LucilleCore::askQuestionAnswerAsString("line (empty to abort): ")
            return if line == ""
            item = NxTasks::issueDescriptionOnly(line)
            TxTimeCommitments::interactivelyAddThisElementToOwnerOrNothing(item)
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

        if Interpreting::match("task", input) then
            item = NxTasks::interactivelyCreateNewOrNull(true)
            return if item.nil?
            if item["ax39"].nil? then
                TxTimeCommitments::interactivelyAddThisElementToOwnerOrNothing(item)
            end
            return
        end

        if Interpreting::match("time * *", input) then
            _, ordinal, timeInHours = Interpreting::tokenizer(input)
            item = store.get(ordinal.to_i)
            return if item.nil?
            puts "Adding #{timeInHours.to_f} hours to #{PolyFunctions::toString(item).green}"
            Bank::put(item["uuid"], timeInHours.to_f*3600)
            return
        end

        if Interpreting::match("tc", input) then
            TxTimeCommitments::dive()
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
                    "name" => "fitness lookup",
                    "lambda" => lambda { JSON.parse(`#{Config::userHomeDirectory()}/Galaxy/Binaries/fitness ns16s`) }
                },
                {
                    "name" => "Anniversaries::listingItems()",
                    "lambda" => lambda { Anniversaries::listingItems() }
                },
                {
                    "name" => "NxTasks::listingItems1()",
                    "lambda" => lambda { NxTasks::listingItems1() }
                },
                {
                    "name" => "NxTodos::listingItems()",
                    "lambda" => lambda { NxTodos::listingItems() }
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

    # CatalystListing::listingItems()
    def self.listingItems()
        items = [
            JSON.parse(`#{Config::userHomeDirectory()}/Galaxy/Binaries/fitness ns16s`),
            Anniversaries::listingItems(),
            Waves::listingItems(true),
            TxTimeCommitments::listingItems(),
            Waves::listingItems(false),
            NxTasks::listingItems1(),
            NxTasks::listingItems2TimeCommitments(),
            NxTodos::listingItems()
        ]
            .flatten
            .select{|item| DoNotShowUntil::isVisible(item["uuid"]) or NxBallsService::isPresent(item["uuid"]) }
            .select{|item| InternetStatus::itemShouldShow(item["uuid"]) or NxBallsService::isPresent(item["uuid"]) }
            .select{|item| !TimeCommitmentMapping::isOwned(item["uuid"]) or NxBallsService::isPresent(item["uuid"]) }

        its1, its2 = items.partition{|item| NxBallsService::isPresent(item["uuid"]) }
        its1 + its2.sort{|i1, i2| PolyFunctions::listingPriority(i1) <=> PolyFunctions::listingPriority(i2) }.reverse
    end

    # CatalystListing::getContextOrNull()
    # context: a time commitment
    def self.getContextOrNull()
        uuid = XCache::getOrNull("7390a691-c8c4-4798-9214-704c5282f5e3")
        return nil if uuid.nil?
        Items::getItemOrNull(uuid)
    end

    # CatalystListing::setContext(uuid)
    def self.setContext(uuid)
        XCache::set("7390a691-c8c4-4798-9214-704c5282f5e3", uuid)
    end

    # CatalystListing::emptyContext()
    def self.emptyContext()
        XCache::destroy("7390a691-c8c4-4798-9214-704c5282f5e3")
    end

    # CatalystListing::mainListing()
    def self.mainListing()

        system("clear")

        context = CatalystListing::getContextOrNull()

        vspaceleft = CommonUtils::screenHeight() - (context ? 5 : 4)

        vspaceleft =  vspaceleft - CommonUtils::verticalSize(CatalystListing::listingCommands())

        if context.nil? then
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
        else
            puts ""
            puts "🚀 Time Commitment 🚀"
            vspaceleft = vspaceleft - 2
        end

        store = ItemStore.new()

        if !InternetStatus::internetIsActive() then
            puts ""
            puts "INTERNET IS OFF".green
            vspaceleft = vspaceleft - 2
        end

        if context then

            PolyActions::start(context)

            puts ""
            store.register(context, false)
            line = TxTimeCommitments::toString(context)
            if NxBallsService::isPresent(context["uuid"]) then
                line = "#{store.prefixString()} #{line} (#{NxBallsService::activityStringOrEmptyString("", context["uuid"], "")})".green
            end
            puts line
            vspaceleft = vspaceleft - 2

            nx79s = TxTimeCommitments::nx79s(context, CommonUtils::screenHeight())
            if nx79s.size > 0 then
                puts ""
                vspaceleft = vspaceleft - 1
                nx79s
                    .each{|nx79|
                        element = nx79["item"]
                        PolyActions::dataPrefetchAttempt(element)
                        indx = store.register(element, false)
                        line = "#{store.prefixString()} (#{"%6.2f" % nx79["ordinal"]}) #{PolyFunctions::toString(element)}"
                        if NxBallsService::isPresent(element["uuid"]) then
                            line = "#{line} (#{NxBallsService::activityStringOrEmptyString("", element["uuid"], "")})".green
                        end
                        puts line
                        vspaceleft = vspaceleft - CommonUtils::verticalSize(line)
                        break if vspaceleft <= 0
                    }
            end

            puts ""
            puts CatalystListing::listingCommands().yellow
            puts "commands: set ordinal <n> | ax39 | insert | detach <n> | exit".yellow

            input = LucilleCore::askQuestionAnswerAsString("> ")

            if input == "exit" then
                if LucilleCore::askQuestionAnswerAsBoolean("You are exiting context. Stop NxBall ? ", true) then
                    PolyActions::stop(context)
                end
                CatalystListing::emptyContext()
                return
            end

            if input == "stop 0" then
                NxBallsService::pause(context["uuid"])
                return
            end

            if input.start_with?("set ordinal")  then
                indx = input[11, 99].strip.to_i
                entity = store.get(indx)
                return if entity.nil?
                ordinal = LucilleCore::askQuestionAnswerAsString("ordinal: ").to_f
                TimeCommitmentMapping::link(context["uuid"], entity["uuid"], ordinal)
                return
            end

            if input.start_with?("detach")  then
                indx = input[6, 99].strip.to_i
                entity = store.get(indx)
                return if entity.nil?
                TimeCommitmentMapping::unlink(context["uuid"], entity["uuid"])
                return
            end

            if input == "ax39"  then
                ax39 = Ax39::interactivelyCreateNewAx()
                ItemsEventsLog::setAttribute2(context["uuid"], "ax39",  ax39)
                return
            end

            if input == "insert" then
                type = LucilleCore::selectEntityFromListOfEntitiesOrNull("type", ["line", "task"])
                return if type.nil?
                if type == "line" then
                    element = NxTasks::interactivelyIssueDescriptionOnlyOrNull()
                    return if element.nil?
                    ordinal = LucilleCore::askQuestionAnswerAsString("ordinal: ").to_f
                    TimeCommitmentMapping::link(context["uuid"], element["uuid"], ordinal)
                end
                if type == "task" then
                    element = NxTasks::interactivelyCreateNewOrNull(false)
                    return if element.nil?
                    ordinal = LucilleCore::askQuestionAnswerAsString("ordinal: ").to_f
                    TimeCommitmentMapping::link(context["uuid"], element["uuid"], ordinal)
                end
                return
            end

            if (indx = Interpreting::readAsIntegerOrNull(input)) then
                entity = store.get(indx)
                return if entity.nil?
                PolyPrograms::itemLanding(entity)
                return
            end

            puts ""
            CatalystListing::listingCommandInterpreter(input, store)

        else

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
    end

    # CatalystListing::program()
    def self.program()

        initialCodeTrace = CommonUtils::generalCodeTrace()

        SystemEvents::processCommsLine(true)

        loop {

            #puts "(code trace)"
            if CommonUtils::generalCodeTrace() != initialCodeTrace then
                puts "Code change detected"
                break
            end

            $commline_semaphore.synchronize {
                SystemEvents::processCommsLine(true)
            }

            LucilleCore::locationsAtFolder("#{ENV['HOME']}/Desktop/NxTasks")
                .each{|location|
                    next if File.basename(location).start_with?(".")
                    item = NxTasks::issueUsingLocation(location)
                    puts "Picked up from NxTasks: #{JSON.pretty_generate(item)}"
                    LucilleCore::removeFileSystemLocation(location)
                }

            CatalystListing::mainListing()
        }
    end
end