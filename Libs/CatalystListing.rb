# encoding: UTF-8

class CatalystListing

    # CatalystListing::listingCommands()
    def self.listingCommands()
        [
            ".. | <datecode> | <n> | access (<n>) | description (<n>) | name (<n>) | datetime (<n>) | engine (<n>) | group (<n>) | landing (<n>) | pause (<n>) | pursue (<n>) | do not show until <n> | redate (<n>) | done (<n>) | edit (<n>) | expose (<n>) | destroy",
            "update start date (<n>)",
            "start | stop",
            "wave | anniversary | hot | today | ondate | todo | Cx22 | pointer-line",
            "pointer (<n>) | ordinal (<n>) | staging (<n>) | re-ordinal <n>",
            "anniversaries | ondates | waves | groups | todos | todos-latest-first",
            "require internet",
            "search | nyx | speed | nxballs | commands",
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
            PolyActions::done(item, true)
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

        if Interpreting::match("commands", input) then
            puts CatalystListing::listingCommands().yellow
            LucilleCore::pressEnterToContinue()
            return
        end

        if Interpreting::match("group", input) then
            item = store.getDefault()
            return if item.nil?
            Cx23::interactivelyIssueCx23ForItemOrNull(item)
            return
        end

        if Interpreting::match("group *", input) then
            _, ordinal = Interpreting::tokenizer(input)
            item = store.get(ordinal.to_i)
            return if item.nil?
            Cx23::interactivelyIssueCx23ForItemOrNull(item)
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

        if Interpreting::match("engine", input) then
            item = store.getDefault()
            return if item.nil?
            item = Nx11E::interactivelySetANewEngineForItemOrNothing(item)
            Cx23::interactivelyIssueCx23ForItemOrNull(item)
            return
        end

        if Interpreting::match("engine *", input) then
            _, ordinal = Interpreting::tokenizer(input)
            item = store.get(ordinal.to_i)
            return if item.nil?
            item = Nx11E::interactivelySetANewEngineForItemOrNothing(item)
            Cx23::interactivelyIssueCx23ForItemOrNull(item)
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

        if Interpreting::match("hot", input) then
            description = LucilleCore::askQuestionAnswerAsString("hot: ")
            item = NxTodos::interactivelyIssueNewHot(description)
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
            PolyActions::landing(store.getDefault())
            return
        end

        if Interpreting::match("landing *", input) then
            _, ordinal = Interpreting::tokenizer(input)
            item = store.get(ordinal.to_i)
            return if item.nil?
            PolyActions::landing(item)
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
            NxTodos::diveOndates()
            return
        end

        if Interpreting::match("ordinal", input) then
            item = store.getDefault()
            return if item.nil?
            puts "setting ordinal for #{PolyFunctions::toString(item)}"
            TxListingPointer::interactivelyIssueNewOrdinal(item)
            return
        end

        if Interpreting::match("ordinal *", input) then
            _, ordinal = Interpreting::tokenizer(input)
            item = store.get(ordinal.to_i)
            return if item.nil?
            puts "setting ordinal for #{PolyFunctions::toString(item)}"
            TxListingPointer::interactivelyIssueNewOrdinal(item)
            return
        end

        if Interpreting::match("pointer", input) then
            item = store.getDefault()
            return if item.nil?
            puts "setting pointer for #{JSON.pretty_generate(item)}"
            TxListingPointer::interactivelyIssueNewTxListingPointerToItem(item)
            return
        end

        if Interpreting::match("pointer *", input) then
            _, ordinal = Interpreting::tokenizer(input)
            item = store.get(ordinal.to_i)
            return if item.nil?
            puts "setting pointer for #{JSON.pretty_generate(item)}"
            TxListingPointer::interactivelyIssueNewTxListingPointerToItem(item)
            return
        end

        if Interpreting::match("pointer-line", input) then
            item = NxCatalistLine1::interactivelyIssueNewOrNull()
            TxListingPointer::interactivelyIssueNewTxListingPointerToItem(item)
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

        if Interpreting::match("re-ordinal *", input) then
            _, ordinal = Interpreting::tokenizer(input)
            item = store.get(ordinal.to_i)
            return if item.nil?
            if item["mikuType"] != "TxListingPointer" then
                puts "You can only send the re-ordinal command to TxListingPointers. Given #{item["mikuType"]}."
                LucilleCore::pressEnterToContinue()
                return
            end
            pointer = item
            ordinal = LucilleCore::askQuestionAnswerAsString("ordinal: ").to_f
            pointer["listingCoordinates"]["ordinal"] = ordinal
            TxListingPointer::commit(pointer)

            return
        end

        if Interpreting::match("search", input) then
            SearchCatalyst::catalyst()
            return
        end

        if Interpreting::match("staging", input) then
            item = store.getDefault()
            return if item.nil?
            puts "setting stagingfor #{PolyFunctions::toString(item)}"
            TxListingPointer::interactivelyIssueNewStaged(item)
            return
        end

        if Interpreting::match("staging *", input) then
            _, ordinal = Interpreting::tokenizer(input)
            item = store.get(ordinal.to_i)
            return if item.nil?
            puts "setting staging for #{PolyFunctions::toString(item)}"
            TxListingPointer::interactivelyIssueNewStaged(item)
            return
        end

        if Interpreting::match("start", input) then
            NxBall::interactivelyIssueNewNxBallOrNothing()
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

        if Interpreting::match("todos-latest-first", input) then
            NxTodos::todosLatestFirst()
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
                "name" => "CatalystListing::listingItemsInPriorityOrderDesc()",
                "lambda" => lambda { CatalystListing::listingItemsInPriorityOrderDesc() }
            }), padding)

            LucilleCore::pressEnterToContinue()
            return
        end
    end

    # CatalystListing::listingItemsInPriorityOrderDesc()
    def self.listingItemsInPriorityOrderDesc()
        [
            Anniversaries::listingItems(),
            TxManualCountDowns::listingItems(),
            #Waves::items(),
            Cx22::listingItems(),
            NxTodos::listingItems(),
            NxCatalistLine1::items(),
            Lx01s::listingItems()
        ]
            .flatten
            .select{|item| DoNotShowUntil::isVisible(item["uuid"]) }
            .select{|item| InternetStatus::itemShouldShow(item["uuid"]) }
            .map{|item|
                {
                    "item"     => item,
                    "priority" => PolyFunctions::listingPriorityOrNull(item) || -1,
                }
            }
            .sort{|p1, p2| p1["priority"] <=> p2["priority"] }
            .map{|packet| packet["item"] }
            .reverse
    end

    # CatalystListing::displayListing()
    def self.displayListing()

        system("clear")

        vspaceleft = CommonUtils::screenHeight() - 4

        if Config::isAlexandra() then
            line = The99Percent::displayLineFromCache()
            puts ""
            puts line
            vspaceleft = vspaceleft - 2
        end

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
                puts "#{store.prefixString()} running: #{nxball["announce"]}".green
            }
        end

        pointersItemsUuids = []

        packets = TxListingPointer::stagedPackets()
        if packets.size > 0 then
            puts ""
            puts "staged:"
            vspaceleft = vspaceleft - 2
            packets
                .each{|packet|
                    pointer = packet["pointer"]
                    item    = packet["item"]
                    pointersItemsUuids << item["uuid"]
                    store.register(item, false)
                    line = "#{store.prefixString()} #{PolyFunctions::toStringForListing(item)}"
                    puts line
                    vspaceleft = vspaceleft - CommonUtils::verticalSize(line)
                }
        end

        packets = TxListingPointer::ordinalPacketOrdered()
        hasOrdinals = packets.size > 0
        if packets.size > 0 then
            puts ""
            puts "ordinal:"
            vspaceleft = vspaceleft - 2
            packets
                .each{|packet|
                    pointer = packet["pointer"]
                    item    = packet["item"]
                    ordinal = packet["ordinal"]
                    pointersItemsUuids << item["uuid"]
                    store.register(pointer, true)
                    line = "#{store.prefixString()} (#{"%7.3f" % ordinal}) #{PolyFunctions::toStringForListing(pointer)}"
                    puts line
                    vspaceleft = vspaceleft - CommonUtils::verticalSize(line)
                }
        end

        puts ""
        vspaceleft = vspaceleft - 1

        CatalystListing::listingItemsInPriorityOrderDesc()
            .each{|item|
                next if pointersItemsUuids.include?(item["uuid"])
                break if vspaceleft <= 0
                store.register(item, true)
                line = "#{store.prefixString()} #{PolyFunctions::toStringForListing(item)}"
                if hasOrdinals then
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
