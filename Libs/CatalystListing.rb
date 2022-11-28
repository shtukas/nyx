# encoding: UTF-8

class CatalystListing

    # CatalystListing::listingCommands()
    def self.listingCommands()
        [
            "[listing interaction] .. | <datecode> | access (<n>) | group (<n>) | do not show until <n> | done (<n>) | edit (<n>) | expose (<n>) | destroy",
            "[makers] wave | anniversary | today | ondate | todo | Cx22 | project | manual countdown",
            "[nxballs] start | stop",
            "[divings] anniversaries | ondates | waves | groups | todos | float",
            "[transmutations] >todo",
            "[misc] require internet",
            "[misc] search | nyx | speed | commands",
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
            Cx22::addItemToInteractivelySelectedCx22OrNothing(item["uuid"])
            return
        end

        if Interpreting::match("group *", input) then
            _, ordinal = Interpreting::tokenizer(input)
            item = store.get(ordinal.to_i)
            return if item.nil?
            Cx22::addItemToInteractivelySelectedCx22OrNothing(item["uuid"])
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

        if Interpreting::match("project", input) then
            item = TxProjects::interactivelyIssueNewOrNull()
            return if item.nil?
            puts JSON.pretty_generate(item)
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
            NxBalls::start()
            return
        end

        if Interpreting::match("stop", input) then
            NxBalls::stop()
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
                    "name" => "NxTodos::listingItems()",
                    "lambda" => lambda { NxTodos::listingItems() }
                },
                {
                    "name" => "TxManualCountDowns::listingItems()",
                    "lambda" => lambda { TxManualCountDowns::listingItems() }
                },
                {
                    "name" => "Waves::items()",
                    "lambda" => lambda { Waves::items() }
                },
                {
                    "name" => "NxTodos::items()",
                    "lambda" => lambda { NxTodos::items() }
                },
                {
                    "name" => "NxTriages::listingItems()",
                    "lambda" => lambda { NxTriages::listingItems() }
                },

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
                "name" => "CatalystListing::txListingItemsInPriorityOrderDesc()",
                "lambda" => lambda { CatalystListing::txListingItemsInPriorityOrderDesc() }
            }), padding)

            LucilleCore::pressEnterToContinue()
            return
        end
    end

    # CatalystListing::txListingItemsInPriorityOrderDesc()
    def self.txListingItemsInPriorityOrderDesc()
        # TxListingItem {
        #     "item"     => item,
        #     "priority" => PolyFunctions::listingPriorityOrNull(item) || -1,
        #     "group"    => Cx22 or null
        # }
        packets = [
            Anniversaries::listingItems(),
            TxManualCountDowns::listingItems(),
            Waves::items(),
            NxTodos::listingItems(),
            LambdX1s::listingItems(),
            NxTriages::listingItems(),
            TxProjects::listingItems()
        ]
            .flatten
            .select{|item| DoNotShowUntil::isVisible(item["uuid"]) }
            .select{|item| InternetStatus::itemShouldShow(item["uuid"]) }
            .map{|item|
                {
                    "item"     => item,
                    "priority" => PolyFunctions::listingPriorityOrNull(item) || -1,
                    "cx22"     => Cx22::itemuuid2ToCx22OrNull(item["uuid"])
                }
            }
            .select{|packet| packet["priority"] > 0 }
        packets
            .sort{|p1, p2| p1["priority"] <=> p2["priority"] }
            .reverse
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

        floats = TxFloats::listingItems()
        if floats.size > 0 then
            puts ""
            vspaceleft = vspaceleft - 1
            floats.each{|float|
                    store.register(float, false)
                    puts "#{store.prefixString()} #{TxFloats::toString(float)}"
                    vspaceleft = vspaceleft - 1
                }
        end

        puts ""
        vspaceleft = vspaceleft - 1
        Cx22::itemsInCompletionOrder()
            .each{|cx22|
                next if !DoNotShowUntil::isVisible(cx22["uuid"])
                next if Ax39::completionRatio(cx22["uuid"], cx22["ax39"]) >= 1
                store.register(cx22, false)
                puts "#{store.prefixString()} #{Cx22::toStringWithDetailsFormatted(cx22)}".yellow
                vspaceleft = vspaceleft - 1
            }

        nxballs = NxBalls::items()
        if nxballs.size > 0 then
            puts ""
            vspaceleft = vspaceleft - 1
            nxballs.each{|nxball|
                puts "> #{NxBalls::toString(nxball)}".green
                vspaceleft = vspaceleft - 1
            }
        end

        puts ""
        vspaceleft = vspaceleft - 1
        CatalystListing::txListingItemsInPriorityOrderDesc()
            .each{|packet|
                item = packet["item"]
                priority = packet["priority"]
                break if vspaceleft <= 0
                store.register(item, true)
                cx22 =  packet["cx22"]
                cx22Str = cx22 ? " (#{Cx22::toString(cx22)})" : ""
                line = "#{store.prefixString()} #{PolyFunctions::toString(item)}#{cx22Str.green}"
                if priority < 0.5 then
                    line = line.yellow
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
