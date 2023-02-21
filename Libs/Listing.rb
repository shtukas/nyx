# encoding: UTF-8

class SpaceControl

    def initialize(remaining_vertical_space)
        @remaining_vertical_space = remaining_vertical_space
    end

    def putsline(line)
        vspace = CommonUtils::verticalSize(line)
        return if vspace > @remaining_vertical_space
        puts line
        @remaining_vertical_space = @remaining_vertical_space - vspace
    end
end

class Listing

    # Listing::listingCommands()
    def self.listingCommands()
        [
            "[all] .. | <datecode> | access (<n>) | do not show until <n> | done (<n>) | landing (<n>) | expose (<n>) | >> skip default | lock (<n>) | add time <n> | board (<n>) | note (<n>) | destroy <n>",
            "[makers] anniversary | manual countdown | wave | today | ondate | drop | top | desktop | project",
            "[divings] anniversaries | ondates | waves | todos | desktop | open",
            "[NxBalls] start | start * | stop | stop * | pause | pursue",
            "[NxOndate] redate",
            "[NxBoard] holiday <n>",
            "[misc] search | speed | commands | nyx",
        ].join("\n")
    end

    # Listing::listingCommandInterpreter(input, store, board or nil)
    def self.listingCommandInterpreter(input, store, board)

        if input.start_with?("+") and (unixtime = CommonUtils::codeToUnixtimeOrNull(input.gsub(" ", ""))) then
            if (item = store.getDefault()) then
                DoNotShowUntil::setUnixtime(item["uuid"], unixtime)
                return
            end
        end

        if Interpreting::match("..", input) then
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

        if Interpreting::match(">>", input) then
            item = store.getDefault()
            return if item.nil?
            Skips::skip(item["uuid"], Time.new.to_f + 3600*1.5)
            return
        end

        if Interpreting::match("add time *", input) then
            _, _, ordinal = Interpreting::tokenizer(input)
            item = store.get(ordinal.to_i)
            return if item.nil?
            timeInHours = LucilleCore::askQuestionAnswerAsString("time in hours: ").to_f
            PolyActions::addTimeToItem(item, timeInHours*3600)
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

        if Interpreting::match("board", input) then
            item = store.getDefault()
            return if item.nil?
            NonBoardItemToBoardMapping::interactivelyOffersToAttach(item)
            return
        end

        if Interpreting::match("board *", input) then
            _, ordinal = Interpreting::tokenizer(input)
            item = store.get(ordinal.to_i)
            return if item.nil?
            NonBoardItemToBoardMapping::interactivelyOffersToAttach(item)
            return
        end

        if Interpreting::match("commands", input) then
            puts Listing::listingCommands().yellow
            LucilleCore::pressEnterToContinue()
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

        if Interpreting::match("desktop", input) then
            system("open '#{Desktop::filepath()}'")
            return
        end

        if Interpreting::match("destroy *", input) then
            _, ordinal = Interpreting::tokenizer(input)
            item = store.get(ordinal.to_i)
            return if item.nil?
            PolyActions::destroy(item)
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
            unixtime = CommonUtils::interactivelySelectUnixtimeUsingDateCodeOrNull()
            return if unixtime.nil?
            DoNotShowUntil::setUnixtime(item["uuid"], unixtime)
            return
        end

        if Interpreting::match("drop", input) then
            options = ["NxBoard", "NxList"]
            option = LucilleCore::selectEntityFromListOfEntitiesOrNull("option", options)
            return if option.nil?
            if option == "NxBoard" then
                board = NxBoards::interactivelySelectOne()
                NxBoardItems::interactivelyIssueNewOrNull(board)
            end
            if option == "NxList" then
                NxHeads::interactivelyIssueNewOrNull()
            end
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

        if Interpreting::match("holiday *", input) then
            _, ordinal = Interpreting::tokenizer(input)
            item = store.get(ordinal.to_i)
            return if item.nil?
            if item["mikuType"] != "NxBoard" then
                puts "holiday only apply to NxBoards"
                LucilleCore::pressEnterToContinue()
                return
            end
            unixtime = CommonUtils::unixtimeAtComingMidnightAtGivenTimeZone(CommonUtils::getLocalTimeZone()) + 3600*3 # 3 am
            if LucilleCore::askQuestionAnswerAsBoolean("> confirm today holiday for '#{PolyFunctions::toString(item).green}': ") then
                DoNotShowUntil::setUnixtime(item["uuid"], unixtime)
            end
            return
        end

        if Interpreting::match("landing", input) then
            item = store.getDefault()
            return if item.nil?
            PolyActions::landing(item)
            return
        end

        if Interpreting::match("landing *", input) then
            _, ordinal = Interpreting::tokenizer(input)
            item = store.get(ordinal.to_i)
            return if item.nil?
            PolyActions::landing(item)
            return
        end

        if Interpreting::match("lock", input) then
            item = store.getDefault()
            return if item.nil?
            domain = LucilleCore::askQuestionAnswerAsString("domain: ")
            Locks::lock(item["uuid"], domain)
            return
        end

        if Interpreting::match("manual countdown", input) then
            TxManualCountDowns::issueNewOrNull()
            return
        end

        if Interpreting::match("netflix", input) then
            title = LucilleCore::askQuestionAnswerAsString("title: ")
            NxHeads::netflix(title)
        end

        if Interpreting::match("note", input) then
            item = store.getDefault()
            return if item.nil?
            NxNotes::edit(item)
            return
        end

        if Interpreting::match("note *", input) then
            _, ordinal = Interpreting::tokenizer(input)
            item = store.get(ordinal.to_i)
            return if item.nil?
            NxNotes::edit(item)
            return
        end

        if Interpreting::match("nyx", input) then
            Nyx::main()
            return
        end

        if Interpreting::match("ondate", input) then
            item = NxOndates::interactivelyIssueNullOrNull()
            return if item.nil?
            puts JSON.pretty_generate(item)
            NonBoardItemToBoardMapping::interactivelyOffersToAttach(item)
            return
        end

        if Interpreting::match("ondates", input) then
            NxOndates::report()
            return
        end

        if Interpreting::match("open", input) then
            item = NxOpens::interactivelyIssueNullOrNull()
            return if item.nil?
            puts JSON.pretty_generate(item)
            NonBoardItemToBoardMapping::interactivelyOffersToAttach(item)
            return
        end

        if Interpreting::match("pause", input) then
            item = store.getDefault()
            return if item.nil?
            NxBalls::pause(item)
            return
        end

        if Interpreting::match("pause *", input) then
            _, ordinal = Interpreting::tokenizer(input)
            item = store.get(ordinal.to_i)
            return if item.nil?
            NxBalls::pause(item)
            return
        end

        if Interpreting::match("pursue", input) then
            item = store.getDefault()
            return if item.nil?
            PolyActions::pursue(item)
            return
        end

        if Interpreting::match("pursue *", input) then
            _, ordinal = Interpreting::tokenizer(input)
            item = store.get(ordinal.to_i)
            return if item.nil?
            PolyActions::pursue(item)
            return
        end

        if Interpreting::match("project", input) then
            item = NxProjects::interactivelyIssueNewOrNull()
            return if item.nil?
            puts JSON.pretty_generate(item)
            NonBoardItemToBoardMapping::interactivelyOffersToAttach(item)
            return
        end

        if Interpreting::match("redate", input) then
            item = store.getDefault()
            return if item.nil?
            if item["mikuType"] != "NxOndate" then
                puts "redate is reserved for NxOndates"
                LucilleCore::pressEnterToContinue()
                return
            end
            NxOndates::redate(item)
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
            NxBalls::stop(item)
            return
        end

        if Interpreting::match("stop *", input) then
            _, ordinal = Interpreting::tokenizer(input)
            item = store.get(ordinal.to_i)
            return if item.nil?
            NxBalls::stop(item)
            return
        end

        if Interpreting::match("search", input) then
            SearchCatalyst::run()
            return
        end

        if Interpreting::match("speed", input) then
            Listing::speedTest()
            return
        end

        if Interpreting::match("today", input) then
            item = NxOndates::interactivelyIssueNewTodayOrNull()
            return if item.nil?
            puts JSON.pretty_generate(item)
            NonBoardItemToBoardMapping::interactivelyOffersToAttach(item)
            return
        end

        if Interpreting::match("top", input) then
            item = NxTops::interactivelyIssueNullOrNull()
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
            LucilleCore::pressEnterToContinue()
            return
        end
    end

    # Listing::speedTest()
    def self.speedTest()

        tests = [
            {
                "name" => "Anniversaries::listingItems()",
                "lambda" => lambda { Anniversaries::listingItems() }
            },
            {
                "name" => "NxOndates::listingItems()",
                "lambda" => lambda { NxOndates::listingItems(nil) }
            },
            {
                "name" => "Waves::topItems()",
                "lambda" => lambda { Waves::topItems() }
            },
            {
                "name" => "TxManualCountDowns::listingItems()",
                "lambda" => lambda { TxManualCountDowns::listingItems() }
            },
            {
                "name" => "NxBoards::listingItems()",
                "lambda" => lambda { NxBoards::listingItems() }
            },
            {
                "name" => "Waves::itemForPriority(ns:today-or-tomorrow)",
                "lambda" => lambda { Waves::itemForPriority("ns:today-or-tomorrow") }
            },
            {
                "name" => "Waves::leisureItems()",
                "lambda" => lambda { Waves::leisureItems() }
            },
            {
                "name" => "NxHeads::listingItems()",
                "lambda" => lambda { NxHeads::listingItems() }
            },
            {
                "name" => "Waves::itemForPriority(ns:leisure)",
                "lambda" => lambda { Waves::itemForPriority("ns:leisure") }
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

        results1 = tests
                    .map{|test|
                        puts "running: #{test["name"]}"
                        runTest.call(test)
                    }
                    .sort{|r1, r2| r1["runtime"] <=> r2["runtime"] }
                    .reverse

        results2 = [
            {
                "name" => "Listing::printListing()",
                "lambda" => lambda { Listing::printListing(ItemStore.new()) }
            }
        ]
                    .map{|test|
                        puts "running: #{test["name"]}"
                        runTest.call(test)
                    }
                    .sort{|r1, r2| r1["runtime"] <=> r2["runtime"] }
                    .reverse

        puts ""

        (results1 + results2)
            .each{|result|
                printTestResults.call(result, padding)
            }

        LucilleCore::pressEnterToContinue()
    end

    # Listing::scheduler1data()
    def self.scheduler1data()
        [
            {
                "name"      => "wave/leisure",
                "account"   => "d36d653e-80e0-4141-b9ff-f26197bbce2b",
                "generator" => lambda{ Waves::leisureItems() } 
            },
            {
                "name"      => "projects",
                "account"   => "21560980-1162-4293-a7f6-42c666862485",
                "generator" => lambda{ NxProjects::listingItems() } 
            },
            {
                "name"      => "head",
                "account"   => "cfad053c-bb83-4728-a3c5-4fb357845fd9",
                "generator" => lambda{ NxHeads::listingItems() } 
            }
        ]
        .map{|packet|
            packet["rt"] = BankUtils::recoveredAverageHoursPerDay(packet["account"])
            packet
        }
        .sort{|p1, p2| p1["rt"] <=> p2["rt"] }
    end

    # Listing::scheduler1runningItems()
    def self.scheduler1runningItems()
        Waves::leisureRunningItems() + NxProjects::listingRunningItems() + NxHeads::listingRunningItems()
    end

    # Listing::scheduler1line()
    def self.scheduler1line()
        a1 = Listing::scheduler1data().map{|packet| "#{packet["name"]}: #{packet["rt"].round(2)}" }
        "(scheduler1, #{a1.join(", ")})"
    end

    # Listing::sheduler1items()
    def self.sheduler1items()
        items = Listing::scheduler1runningItems() + Listing::scheduler1data().first["generator"].call()
        items.reduce([]){|selected, item|
            if selected.map{|i| i["uuid"] }.include?(item["uuid"]) then
                selected
            else
                selected + [item]
            end
        }
    end

    # Listing::items()
    def self.items()
        [
            Anniversaries::listingItems(),
            NxOndates::listingItems(nil),
            Waves::topItems(),
            TxManualCountDowns::listingItems(),
            NxBoards::listingItems(),
            Waves::timedItems(),
            Listing::sheduler1items(),
        ]
            .flatten
            .select{|item| DoNotShowUntil::isVisible(item["uuid"]) or NxBalls::itemIsActive(item["uuid"]) }
    end

    # Listing::printDesktop(spacecontrol)
    def self.printDesktop(spacecontrol)
        dskt = Desktop::contents()
        if dskt and dskt.size > 0 then
            dskt = dskt.lines.map{|line| "      #{line}" }.join()
            spacecontrol.putsline "(-->) Desktop:".green
            spacecontrol.putsline dskt
        end
    end

    # Listing::itemToListingLine(store or nil, item)
    def self.itemToListingLine(store, item)
        storePrefix = store ? "(#{store.prefixString()})" : "     "
        line = "#{storePrefix} #{PolyFunctions::toString(item)}#{NxBalls::nxballSuffixStatusIfRelevant(item)}#{NonBoardItemToBoardMapping::toStringSuffix(item)}#{NxNotes::toStringSuffix(item)}"
        if Locks::isLocked(item["uuid"]) then
            line = "#{line} [lock: #{Locks::locknameOrNull(item["uuid"])}]".yellow
        end
        if NxBalls::itemIsRunning(item) or NxBalls::itemIsPaused(item) then
            line = line.green
        end
        line
    end

    # Listing::printListing(store)
    def self.printListing(store)
        system("clear")

        spacecontrol = SpaceControl.new(CommonUtils::screenHeight() - 3)

        items = Listing::items()

        lockedItems, items = items.partition{|item| Locks::isLocked(item["uuid"]) }

        spacecontrol.putsline ""

        Listing::printDesktop(spacecontrol)

        NxOpens::itemsBoardFree()
            .each{|item|
                store.register(item, false)
                spacecontrol.putsline "(#{store.prefixString()}) (open) #{item["description"]} #{NonBoardItemToBoardMapping::toStringSuffix(item)}".yellow
            }

        NxTops::itemsInOrder()
            .each{|item|
                bx = Lookups::getValueOrNull("NonBoardItemToBoardMapping", item["uuid"])
                next if !(bx.nil? or NxBalls::itemIsRunning(item))
                store.register(item, true)
                spacecontrol.putsline Listing::itemToListingLine(store, item)
            }

        activeItems, items = items.partition{|item| NxBalls::itemIsActive(item) }

        runningItems, pausedItems = activeItems.partition{|item| NxBalls::itemIsRunning(item) }

        (runningItems + pausedItems + items.take(12))
            .each{|item|

                if item["mikuType"] == "NxBoard" then
                    NxBoards::listingDisplay(store, spacecontrol, item["uuid"])
                    next
                end

                store.register(item, !Skips::isSkipped(item["uuid"]))
                spacecontrol.putsline Listing::itemToListingLine(store, item)
            }

        spacecontrol.putsline ""

        lockedItems
            .each{|item|
                store.register(item, false)
                spacecontrol.putsline Listing::itemToListingLine(store, item)
            }

        NxBoards::bottomItems().each{|item|
            NxBoards::bottomDisplay(store, spacecontrol, item["uuid"])
        }

        spacecontrol.putsline "> #{Listing::scheduler1line()}"
        spacecontrol.putsline The99Percent::line() + " (start zone: #{NxHeads::startZone()}, mid point: #{NxList::midposition()})"
        spacecontrol.putsline "> anniversary | manual countdown | wave | today | ondate | drop | top | desktop".yellow
    end

    # Listing::mainProgram2Pure()
    def self.mainProgram2Pure()

        initialCodeTrace = CommonUtils::stargateTraceCode()

        loop {

            if CommonUtils::stargateTraceCode() != initialCodeTrace then
                puts "Code change detected"
                break
            end

            if ProgrammableBooleans::trueNoMoreOftenThanEveryNSeconds("8fba6ab0-ce92-46af-9e6b-ce86371d643d", 3600*12) then
                if Config::thisInstanceId() == "Lucille20-pascal" then 
                    system("#{File.dirname(__FILE__)}/bin/vienna-import")
                end
            end

            LucilleCore::locationsAtFolder("#{ENV['HOME']}/Galaxy/DataHub/NxTails-FrontElements-BufferIn")
                .each{|location|
                    next if File.basename(location).start_with?(".")
                    item = NxHeads::bufferInImport(location)
                    puts "Picked up from NxTails-FrontElements-BufferIn: #{JSON.pretty_generate(item)}"
                    LucilleCore::removeFileSystemLocation(location)
                }

            NxBoards::timeManagement()
            NxList::dataManagement()

            NxOpenCycles::program()

            store = ItemStore.new()

            Listing::printListing(store)

            puts ""
            input = LucilleCore::askQuestionAnswerAsString("> ")
            next if input == ""

            Listing::listingCommandInterpreter(input, store, nil)
        }
    end
end
