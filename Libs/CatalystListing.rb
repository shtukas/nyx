# encoding: UTF-8

class CatalystListing

    # CatalystListing::listingCommands()
    def self.listingCommands()
        [
            "[listing interaction] .. | <datecode> | access (<n>) | group (<n>) | do not show until <n> | done (<n>) | edit (<n>) | expose (<n>) | probe (<n>) | destroy",
            "[makers] wave | anniversary | today | ondate | todo | Cx22 | project | manual countdown",
            "[nxballs] start (<n>) | stop <n>",
            "[divings] anniversaries | ondates | waves | groups | todos | float",
            "[transmutations] >todo",
            "[misc] require internet",
            "[misc] search | nyx | speed | commands | lock (<n>)",
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

        if Interpreting::match(">todo", input) then
            item = store.getDefault()
            return if item.nil?

            # We apply this to only to Triage items
            if item["mikuType"] != "NxTriage" then
                puts "The >todo command only applies to NxTriages"
                LucilleCore::pressEnterToContinue()
                return
            end

            NxTriages::transmuteItemToNxTodo(item)
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

        if Interpreting::match("group", input) then
            item = store.getDefault()
            return if item.nil?
            Item2Cx22::interactivelySelectAndMapToCx22OrNothing(item["uuid"])
            return
        end

        if Interpreting::match("group *", input) then
            _, ordinal = Interpreting::tokenizer(input)
            item = store.get(ordinal.to_i)
            return if item.nil?
            Item2Cx22::interactivelySelectAndMapToCx22OrNothing(item["uuid"])
            return
        end

        if Interpreting::match("groups", input) then
            Cx22::mainprobe()
            return
        end

        if Interpreting::match("Cx22", input) then
            Cx22::interactivelyIssueNewOrNull()
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

        if Interpreting::match("groups", input) then
            TxFloats::interactivelyIssueOrNull()
            return
        end

        if Interpreting::match("groups", input) then
            Cx22::mainprobe()
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

        if Interpreting::match("lock", input) then
            item = store.getDefault()
            return if item.nil?
            filepath = "#{Config::pathToDataCenter()}/Locks/#{item["uuid"]}.lock"
            return if File.exists?(filepath)
            FileUtils.touch(filepath)
            return
        end

        if Interpreting::match("lock *", input) then
            _, ordinal = Interpreting::tokenizer(input)
            item = store.get(ordinal.to_i)
            return if item.nil?
            filepath = "#{Config::pathToDataCenter()}/Locks/#{item["uuid"]}.lock"
            return if File.exists?(filepath)
            FileUtils.touch(filepath)
            return
        end

        if Interpreting::match("manual countdown", input) then
            TxManualCountDowns::issueNewOrNull()
            return
        end

        if Interpreting::match("nyx", input) then
            Nyx::program()
            return
        end

        if Interpreting::match("ondate", input) then
            item = NxTodos::interactivelyIssueNewOndateOrNull()
            return if item.nil?
            puts JSON.pretty_generate(item)
            return
        end

        if Interpreting::match("ondates", input) then
            NxOndates::dive()
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

        if Interpreting::match("require internet", input) then
            item = store.getDefault()
            return if item.nil?
            InternetStatus::markIdAsRequiringInternet(item["uuid"])
            return
        end

        if Interpreting::match("search", input) then
            SearchCatalyst::catalyst()
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
                "name" => "Cx22::listingItemsIsWork()",
                "lambda" => lambda { Cx22::listingItemsIsWork() }
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
                "name" => "Cx22::listingItemsTop()",
                "lambda" => lambda { Cx22::listingItemsTop() }
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
            },
            {
                "name" => "NxTodos::listingItems()",
                "lambda" => lambda { NxTodos::listingItems() }
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
            Anniversaries::listingItems(),
            Waves::listingItems("ns:mandatory-today"),
            NxOndates::listingItems(),
            Cx22::listingItemsIsWork(),
            NxTriages::items(),
            TxManualCountDowns::listingItems(),
            Cx22::listingItemsTop(),
            Waves::listingItems("ns:time-important"),
            Waves::listingItems("ns:beach"),
            NxTodos::listingItems()
        ]
            .flatten
            .select{|item| DoNotShowUntil::isVisible(item["uuid"]) }
            .select{|item| InternetStatus::itemShouldShow(item["uuid"]) }
    end

    # CatalystListing::displayListing()
    def self.displayListing()

        system("clear")

        vspaceleft = CommonUtils::screenHeight() - 4

        puts ""
        puts The99Percent::line()
        vspaceleft = vspaceleft - 2

        store = ItemStore.new()

        if !InternetStatus::internetIsActive() then
            puts ""
            puts "INTERNET IS OFF".green
            vspaceleft = vspaceleft - 2
        end

        nxballHasAnItemInThere = lambda {|nxball, listingItems|
            itemuuid = nxball["itemuuid"]
            return false if itemuuid.nil?
            listingItems.any?{|packet| packet["item"]["uuid"] == itemuuid }
        }

        floats = TxFloats::listingItems()

        listingItems = CatalystListing::listingItems

        lockeds, unlockeds = listingItems.partition{|item|
            filepath = "#{Config::pathToDataCenter()}/Locks/#{item["uuid"]}.lock"
            File.exists?(filepath)
        }

        if (floats.size+lockeds.size) > 0 then
            puts ""
            vspaceleft = vspaceleft - 1
            floats.each{|float|
                    store.register(float, false)
                    puts "#{store.prefixString()} #{TxFloats::toString(float)}".yellow
                    vspaceleft = vspaceleft - 1
                }
            lockeds
                .each{|item|

                    break if vspaceleft <= 0
                    store.register(item, false)

                    cx22 =  Item2Cx22::getCx22OrNull(item["uuid"])
                    cx22Str = cx22 ? " (#{Cx22::toString(cx22)})" : ""
                    line = "#{store.prefixString()} #{PolyFunctions::toStringForCatalystListing(item)}#{cx22Str.green}"
                    
                    line = line.yellow

                    nxball = NxBalls::getNxBallForItemOrNull(item)
                    if nxball then
                        line = "#{line} #{NxBalls::toRunningStatement(nxball)}".green
                    end

                    puts line
                    vspaceleft = vspaceleft - CommonUtils::verticalSize(line)
                }
        end

        nxballs = NxBalls::items()
                    .select{|nxball| !nxballHasAnItemInThere.call(nxball, listingItems) }
        if nxballs.size > 0 then
            puts ""
            vspaceleft = vspaceleft - 1
            nxballs
                .each{|nxball|
                    store.register(nxball, false)
                    puts "#{store.prefixString()} #{NxBalls::toString(nxball)}".green
                    vspaceleft = vspaceleft - 1
                }
        end

        puts ""
        vspaceleft = vspaceleft - 1

        unlockeds
            .each{|item|

                break if vspaceleft <= 0
                store.register(item, true)

                cx22 =  cx22 =  Item2Cx22::getCx22OrNull(item["uuid"])
                cx22Str = cx22 ? " (Cx22: #{cx22["description"]})" : ""
                line = "#{store.prefixString()} #{PolyFunctions::toStringForCatalystListing(item)}#{cx22Str.green}"

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

        Git::updateFromRemoteIfNeeded()

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

            CatalystListing::displayListing()
        }
    end
end
