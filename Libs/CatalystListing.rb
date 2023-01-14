# encoding: UTF-8

class CatalystListing

    # CatalystListing::listingCommands()
    def self.listingCommands()
        [
            "[listing interaction] .. | <datecode> | access (<n>) | do not show until <n> | done (<n>) | edit (<n>) | expose (<n>) | probe (<n>) | >> # lock the default item | destroy",
            "[makers] wave | anniversary | today | ondate | todo | project | manual countdown",
            "[nxballs] start (<n>) | stop <n> | pause <n> | pursue <n>",
            "[divings] anniversaries | ondates | waves | projects | todos | float | limited-emptier",
            "[transmutations] >todo (ondates and triages)",
            "[misc] require internet",
            "[misc] search | speed | commands | lock (<n>)",
        ].join("\n")
    end

    # CatalystListing::listingCommandInterpreter(input, store)
    def self.listingCommandInterpreter(input, store)

        if input.start_with?("+") and (unixtime = CommonUtils::codeToUnixtimeOrNull(input.gsub(" ", ""))) then
            if (item = store.getDefault()) then
                DoNotShowUntil::setUnixtime(item["uuid"], unixtime)
                return
            end
        end

        if Interpreting::match("..", input) then
            item = store.getDefault()
            return if item.nil?
            PolyActions::doubleDotAccess(item)
            return
        end

        if Interpreting::match(".. *", input) then
            _, ordinal = Interpreting::tokenizer(input)
            item = store.get(ordinal.to_i)
            return if item.nil?
            PolyActions::doubleDotAccess(item)
            return
        end

        if Interpreting::match(">>", input) then
            item = store.getDefault()
            return if item.nil?
            Locks::lock(item)
            return
        end

        if Interpreting::match(">todo", input) then
            item = store.getDefault()
            return if item.nil?
            if item["mikuType"] == "NxOndate" then
                NxTodos::issueConsumingNxOndate(item)
                return
            end
            if item["mikuType"] == "NxTriage" then
                NxTodos::issueConsumingNxTriage(item)
                return
            end
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
            Anniversaries::mainprobe()
            return
        end

        if Interpreting::match("commands", input) then
            puts CatalystListing::listingCommands().yellow
            LucilleCore::pressEnterToContinue()
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

        if Interpreting::match("do not show until *", input) then
            _, _, _, _, ordinal = Interpreting::tokenizer(input)
            item = store.get(ordinal.to_i)
            return if item.nil?
            datecode = LucilleCore::askQuestionAnswerAsString("datecode: ")
            return if datecode == ""
            unixtime = CommonUtils::codeToUnixtimeOrNull(datecode.gsub(" ", ""))
            return if unixtime.nil?
            DoNotShowUntil::setUnixtime(item["uuid"], unixtime)
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
            TxFloats::interactivelyIssueOrNull()
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

        if Interpreting::match("limited-emptier", input) then
            NxLimitedEmptiers::interactivelyIssueNewOrNull()
            return
        end

        if Interpreting::match("lock", input) then
            item = store.getDefault()
            return if item.nil?
            Locks::lock(item)
            return
        end

        if Interpreting::match("lock *", input) then
            _, ordinal = Interpreting::tokenizer(input)
            item = store.get(ordinal.to_i)
            return if item.nil?
            Locks::lock(item)
            return
        end

        if Interpreting::match("manual countdown", input) then
            TxManualCountDowns::issueNewOrNull()
            return
        end

        if Interpreting::match("ondate", input) then
            item = NxOndates::interactivelyIssueNewOrNull()
            return if item.nil?
            puts JSON.pretty_generate(item)
            return
        end

        if Interpreting::match("ondates", input) then
            NxOndates::dive()
            return
        end

        if Interpreting::match("project", input) then
            NxProjects::interactivelyIssueNewOrNull()
            return
        end

        if Interpreting::match("projects", input) then
            NxProjects::mainprobe()
            return
        end

        if Interpreting::match("probe", input) then
            item = store.getDefault()
            return if item.nil?
            PolyActions::probe(item)
            return
        end

        if Interpreting::match("probe *", input) then
            _, ordinal = Interpreting::tokenizer(input)
            item = store.get(ordinal.to_i)
            return if item.nil?
            PolyActions::probe(item)
            return
        end

        if Interpreting::match("pause *", input) then
            _, ordinal = Interpreting::tokenizer(input)
            item = store.get(ordinal.to_i)
            return if item.nil?
            if item["mikuType"] == "Nxball" then
                NxBalls::pause(item)
                return
            end
            nxball = NxBalls::getNxBallForItemOrNull(item)
            if nxball then
                NxBalls::pause(nxball)
                return
            end
            return
        end

        if Interpreting::match("pursue *", input) then
            _, ordinal = Interpreting::tokenizer(input)
            item = store.get(ordinal.to_i)
            return if item.nil?
            if item["mikuType"] == "Nxball" then
                NxBalls::pursue(item)
                return
            end
            nxball = NxBalls::getNxBallForItemOrNull(item)
            if nxball then
                NxBalls::pursue(nxball)
                return
            end
            return
        end

        if Interpreting::match("require internet", input) then
            item = store.getDefault()
            return if item.nil?
            InternetStatus::markIdAsRequiringInternet(item["uuid"])
            return
        end

        if Interpreting::match("search", input) then
            SearchCatalyst::run()
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

            if item["mikuType"] == "NxBall" then
                NxBalls::close(item)
                return
            else
                nxball = NxBalls::getNxBallForItemOrNull(item)
                if nxball then
                    NxBalls::close(nxball)
                end
            end
            return
        end

        if Interpreting::match("stop *", input) then
            _, ordinal = Interpreting::tokenizer(input)
            item = store.get(ordinal.to_i)
            return if item.nil?

            if item["mikuType"] == "NxBall" then
                NxBalls::close(item)
                return
            else
                nxball = NxBalls::getNxBallForItemOrNull(item)
                if nxball then
                    NxBalls::close(nxball)
                end
            end
            return
        end

        if Interpreting::match("today", input) then
            item = NxOndates::interactivelyIssueNewTodayOrNull()
            return if item.nil?
            puts JSON.pretty_generate(item)
            return
        end

        if Interpreting::match("todo", input) then
            item = NxTodos::interactivelyIssueNewOrNull()
            return if item.nil?
            puts JSON.pretty_generate(item)
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
            CatalystListing::runSpeedTest()
            LucilleCore::pressEnterToContinue()
            return
        end
    end

    # CatalystListing::runSpeedTest()
    def self.runSpeedTest()
        tests = [
            {
                "name" => "source code trace generation",
                "lambda" => lambda { CommonUtils::stargateTraceCode() }
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
                "name" => "Waves::listingItems(ns:mandatory-today)",
                "lambda" => lambda { Waves::listingItems("ns:mandatory-today") }
            },
            {
                "name" => "NxOndates::listingItems()",
                "lambda" => lambda { NxOndates::listingItems() }
            },
            {
                "name" => "NxProjects::listingWorkProjects()",
                "lambda" => lambda { NxProjects::listingWorkProjects() }
            },
            {
                "name" => "NxTriages::items()",
                "lambda" => lambda { NxTriages::items() }
            },
            {
                "name" => "TxManualCountDowns::listingItems()",
                "lambda" => lambda { TxManualCountDowns::listingItems() }
            },
            {
                "name" => "NxProjects::listingClassicProjects()",
                "lambda" => lambda { NxProjects::listingClassicProjects() }
            },
            {
                "name" => "Waves::listingItems(ns:time-important)",
                "lambda" => lambda { Waves::listingItems("ns:time-important") }
            },
            {
                "name" => "Waves::listingItems(ns:beach)",
                "lambda" => lambda { Waves::listingItems("ns:beach") }
            },
            {
                "name" => "Waves::listingItems(ns:beach)",
                "lambda" => lambda { Waves::listingItems("ns:beach") }
            }
        ]

        runTest = lambda {|test|
            t1 = Time.new.to_f
            (1..3).each{ test["lambda"].call() }
            t2 = Time.new.to_f
            {
                "name" => test["name"],
                "runtime" => (t2 - t1).to_f/3
            }
        }

        printTestResults = lambda{|result, padding|
            puts "- #{result["name"].ljust(padding)} : #{"%6.3f" % result["runtime"]}"
        }

        padding = tests.map{|test| test["name"].size }.max

        # dry run to initialise things
        tests
            .each{|test|
                test["lambda"].call()
            }

        results = tests
                    .map{|test|
                        puts "running: #{test["name"]}"
                        runTest.call(test)
                    }
                    .sort{|r1, r2| r1["runtime"] <=> r2["runtime"] }
                    .reverse

        puts ""
        results
            .each{|result|
                printTestResults.call(result, padding)
            }

        puts ""
        printTestResults.call(runTest.call({
            "name" => "CatalystListing::listingItems()",
            "lambda" => lambda { CatalystListing::listingItems() }
        }), padding)
    end

    # CatalystListing::listingItems()
    def self.listingItems()
        [
            TxFloats::listingItems(),
            NxTriages::items(),
            Anniversaries::listingItems(),
            Waves::listingItems("ns:mandatory-today"),
            NxOndates::listingItems(),
            NxProjects::listingWorkProjects(),
            TxManualCountDowns::listingItems(),
            NxLimitedEmptiers::listingItems(),
            Waves::listingItems("ns:time-important"),
            NxProjects::listingClassicProjects(),
            Waves::listingItems("ns:beach")
        ]
            .flatten
            .select{|item| DoNotShowUntil::isVisible(item["uuid"]) }
            .select{|item| InternetStatus::itemShouldShow(item["uuid"]) }
    end

    # CatalystListing::displayListing()
    def self.displayListing()

        system("clear")
        store = ItemStore.new()
        vspaceleft = CommonUtils::screenHeight() - 4

        puts ""
        linecount = TimeCommitments::printMissingHoursLine()
        vspaceleft = vspaceleft - linecount

        NxProjects::runningProjects().each{|project|
            store.register(project, false)
            puts "(#{store.prefixString()}) #{NxProjects::toStringWithDetails(project, true)}".green
            vspaceleft = vspaceleft - 1
        }

        #puts The99Percent::line()
        #vspaceleft = vspaceleft - 2

        if !InternetStatus::internetIsActive() then
            puts ""
            puts "INTERNET IS OFF".green
            vspaceleft = vspaceleft - 2
        end

        nxballHasAnItemInThere = lambda {|nxball, listingItems|
            itemuuid = nxball["itemuuid"]
            return false if itemuuid.nil?
            listingItems.any?{|item| item["uuid"] == itemuuid }
        }

        projects = NxProjects::projectsForListing()

        listingItems = CatalystListing::listingItems()

        nxballs = NxBalls::items()
                    .select{|nxball| !nxballHasAnItemInThere.call(nxball, projects + listingItems) }
        if nxballs.size > 0 then
            puts ""
            vspaceleft = vspaceleft - 1
            nxballs
                .each{|nxball|
                    store.register(nxball, false)
                    puts "(#{store.prefixString()}) #{NxBalls::toString(nxball)}".green
                    vspaceleft = vspaceleft - 1
                }
        end

        #linecount = TimeCommitments::printing(store)
        #vspaceleft = vspaceleft - linecount

        locks = Locks::locks()

        lockStatus = lambda{|item|
            oldlocks, newlocks = locks.partition{|lock| lock["unixtime"] < (Time.new.to_i - 86400)}
            if oldlocks.map{|data| data["uuid"]}.include?(item["uuid"]) then
                return "oldlock"
            end
            if newlocks.map{|data| data["uuid"]}.include?(item["uuid"]) then
                return "newlock"
            end
            nil
        }

        puts ""
        vspaceleft = vspaceleft - 1

        set1, set2 = listingItems.partition{|item| NxBalls::getNxBallForItemOrNull(item) }

        (set1 + set2)
            .each{|item|

                canBeDefault = lambda {|item|
                    lockstat = lockStatus.call(item)
                    return false if ["oldlock", "newlock"].include?(lockstat)
                    return false if item["mikuType"] == "TxFloat"
                    true
                }

                break if vspaceleft <= 0
                store.register(item, canBeDefault.call(item))

                project =  project =  NxProjects::itemToProject(item)
                projectStr = project ? " (NxProject: #{project["description"]})" : ""
                line = "(#{store.prefixString()}) #{PolyFunctions::toStringForCatalystListing(item)}#{projectStr.green}"

                lockstat = lockStatus.call(item)
                if lockstat == "oldlock" then
                    line = "#{line} #{NxBalls::toRunningStatement(nxball)}".yellow
                end

                nxball = NxBalls::getNxBallForItemOrNull(item)

                if nxball then
                    line = "#{line} #{NxBalls::toRunningStatement(nxball)}".green
                end

                puts line
                vspaceleft = vspaceleft - CommonUtils::verticalSize(line)
            }

        puts ""
        input = LucilleCore::askQuestionAnswerAsString("> ")
        return if input == ""
        CatalystListing::listingCommandInterpreter(input, store)
    end

    # CatalystListing::mainListingProgram()
    def self.mainListingProgram()

        initialCodeTrace = CommonUtils::stargateTraceCode()

        $SyncConflictInterruptionFilepath = nil

        loop {

            if CommonUtils::stargateTraceCode() != initialCodeTrace then
                puts "Code change detected"
                break
            end

            if $SyncConflictInterruptionFilepath then
                puts "$SyncConflictInterruptionFilepath: #{$SyncConflictInterruptionFilepath}"
                exit
            end

            LucilleCore::locationsAtFolder("#{ENV['HOME']}/Galaxy/DataHub/NxTodos-BufferIn")
                .each{|location|
                    next if File.basename(location).start_with?(".")
                    item = NxTriages::bufferInImport(location)
                    puts "Picked up from NxTodos-BufferIn: #{JSON.pretty_generate(item)}"
                    LucilleCore::removeFileSystemLocation(location)
                }

            Ticks::gc()

            CatalystListing::displayListing()
        }
    end
end
