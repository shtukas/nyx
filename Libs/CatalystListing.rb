# encoding: UTF-8

class CatalystListing

    # CatalystListing::listingCommands()
    def self.listingCommands()
        [
            "[listing interaction] .. | <datecode> | <n> | access (<n>) | description (<n>) | datetime (<n>) | set group (<n>) | do not show until <n> | redate (<n>) | done (<n>) | edit (<n>) | expose (<n>) | float | destroy",
            "[makers] wave | anniversary | today | ondate | todo | Cx22",
            "[nxballs] start or start * | stop",
            "[divings] anniversaries | ondates | waves | groups | todos",
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
            PolyActions::access(item)
            PolyActions::postDoubleAccess(item)
            return
        end

        if Interpreting::match(".. *", input) then
            _, ordinal = Interpreting::tokenizer(input)
            item = store.get(ordinal.to_i)
            return if item.nil?
            PolyActions::access(item)
            PolyActions::done(item, true)
            return
        end

        if Interpreting::match(">todo", input) then
            item = store.getDefault()
            return if item.nil?
            Catalyst::transmuteTo(item, "NxTodo")
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
            Anniversaries::dive()
            return
        end

        if Interpreting::match("commands", input) then
            puts CatalystListing::listingCommands().yellow
            LucilleCore::pressEnterToContinue()
            return
        end

        if Interpreting::match("set group", input) then
            item = store.getDefault()
            return if item.nil?
            Cx22::addItemToInteractivelySelectedCx22OrNothing(item["uuid"])
            return
        end

        if Interpreting::match("set group *", input) then
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

        if Interpreting::match("groups", input) then
            Cx22::maindive()
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
            SearchCatalyst::catalyst()
            return
        end

        if Interpreting::match("start", input) then
            item = store.getDefault()
            if item and item["mikuType"] == "Cx22" then
                NxBall::issue(item)
                return
            end
            NxBall::interactivelyIssueNewNxBallOrNothing()
            return
        end

        if Interpreting::match("start *", input) then
            _, ordinal = Interpreting::tokenizer(input)
            item = store.get(ordinal.to_i)
            return if item.nil?
            if item["mikuType"] == "Cx22" then
                NxBall::issue(item)
            end
            return
        end

        if Interpreting::match("stop", input) then
            nxballs = NxBall::items()
            if nxballs.size == 0 then
                return
            end
            if nxballs.size == 1 then
                nxball = nxballs.first
                NxBall::commitTimeAndDestroy(nxball)
            end
            if nxballs.size > 1 then
                nxball = LucilleCore::selectEntityFromListOfEntitiesOrNull("nxball", nxballs, lambda{|nxball| nxball["announce"] })
                return if nxball.nil?
                NxBall::commitTimeAndDestroy(nxball)
            end
            return
        end

        if Interpreting::match("today", input) then
            item = NxTodos::interactivelyIssueNewTodayOrNull()
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
                    "name" => "Cx22::listingItems()",
                    "lambda" => lambda { Cx22::listingItems() }
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
        # }
        packets = [
            Anniversaries::listingItems(),
            TxManualCountDowns::listingItems(),
            Waves::items(),
            Cx22::listingItems(),
            NxTodos::listingItems(),
            Lx01s::listingItems(),
            NxTriages::listingItems()
        ]
            .flatten
            .select{|item| true or DoNotShowUntil::isVisible(item["uuid"]) }
            .select{|item| true or InternetStatus::itemShouldShow(item["uuid"]) }
            .map{|item|
                {
                    "item"     => item,
                    "priority" => PolyFunctions::listingPriorityOrNull(item) || -1,
                }
            }
            .select{|packet| packet["priority"] > 0 }
        if packets.any?{|packet| packet["priority"] > 0.5 } then
            packets = packets.select{|packet| packet["priority"] > 0.5 }
        end
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

        nxballs = NxBall::items()
        if nxballs.size > 0 then
            puts ""
            puts "nxballs:"
            vspaceleft = vspaceleft - 2
            nxballs.each{|nxball|
                store.register(nxball, false)
                puts "#{store.prefixString()} #{NxBall::toString(nxball)}".green
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
                line = "#{store.prefixString()} #{PolyFunctions::toStringForListing(item)}"
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
                    item = NxTodos::bufferInImport(location)
                    puts "Picked up from NxTodos-BufferIn: #{JSON.pretty_generate(item)}"
                    LucilleCore::removeFileSystemLocation(location)
                }

            CatalystListing::displayListing()
        }
    end
end
