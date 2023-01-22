# encoding: UTF-8

class CatalystListing

    # CatalystListing::listingCommands()
    def self.listingCommands()
        [
            "[listing interaction] .. | <datecode> | access (<n>) | do not show until <n> | done (<n>) | edit (<n>) | expose (<n>) | probe (<n>) | >> skip default | destroy",
            "[makers] wave | anniversary | today | ondate | todo | one time commitment | wave time commitment | manual countdown | top",
            "[nxballs] start (<n>) | stop <n> | pause <n> | pursue <n>",
            "[divings] anniversaries | ondates | waves | wave time commitments | todos | float",
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

        if Interpreting::match("lock", input) then
            item = store.getDefault()
            return if item.nil?
            domain = LucilleCore::askQuestionAnswerAsString("domain: ")
            Locks::lock(domain, item["uuid"])
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

        if Interpreting::match("one time commitment", input) then
            NxOTimeCommitments::interactivelyIssueNewOrNull()
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

        if Interpreting::match(">>", input) then
            item = store.getDefault()
            return if item.nil?
            Skips::skip(item["uuid"], Time.new.to_f + 3600*1.5)
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

        if Interpreting::match("top", input) then
            item = NsTopLines::interactivelyIssueNewOrNull()
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

        if Interpreting::match("wave time commitment", input) then
            NxWTimeCommitments::interactivelyIssueNewOrNull()
            return
        end

        if Interpreting::match("wave time commitments", input) then
            NxWTimeCommitments::mainprobe()
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
                "name" => "Anniversaries::listingItems()",
                "lambda" => lambda { Anniversaries::listingItems() }
            },
            {
                "name" => "GeneralTimeCommitments::reportItemsX()",
                "lambda" => lambda { GeneralTimeCommitments::reportItemsX() }
            },
            {
                "name" => "NxOndates::listingItems()",
                "lambda" => lambda { NxOndates::listingItems() }
            },
            {
                "name" => "NxTriages::items()",
                "lambda" => lambda { NxTriages::items() }
            },
            {
                "name" => "NxOTimeCommitments::listingItems()",
                "lambda" => lambda { NxOTimeCommitments::listingItems() }
            },
            {
                "name" => "source code trace generation",
                "lambda" => lambda { CommonUtils::stargateTraceCode() }
            },
            {
                "name" => "The99Percent::getCurrentCount()",
                "lambda" => lambda { The99Percent::getCurrentCount() }
            },
            {
                "name" => "TxManualCountDowns::listingItems()",
                "lambda" => lambda { TxManualCountDowns::listingItems() }
            },
            {
                "name" => "Waves::listingItems(ns:beach)",
                "lambda" => lambda { Waves::listingItems("ns:beach") }
            },
            {
                "name" => "Waves::listingItems(ns:mandatory-today)",
                "lambda" => lambda { Waves::listingItems("ns:mandatory-today") }
            },
            {
                "name" => "Waves::listingItems(ns:time-important)",
                "lambda" => lambda { Waves::listingItems("ns:time-important") }
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
            "name" => "CatalystListing::listingItems()",
            "lambda" => lambda { CatalystListing::listingItems() }
        }), padding)
    end

    # CatalystListing::listingItems()
    def self.listingItems()
        items = [
            NxTriages::items(),
            Anniversaries::listingItems(),
            Waves::listingItems("ns:mandatory-today").take(1),
            NxOndates::listingItems(),
            TxManualCountDowns::listingItems(),
            Waves::listingItems("ns:time-important").take(1),
            GeneralTimeCommitments::listingItems(),
            Waves::listingItems("ns:beach").take(1)
        ]
            .flatten
            .select{|item| DoNotShowUntil::isVisible(item["uuid"]) }
            .select{|item| InternetStatus::itemShouldShow(item["uuid"]) }
    end

    # CatalystListing::displayListing(listingItems)
    def self.displayListing(listingItems)

        nxballHasAnItemInThere = lambda {|nxball, listingItems|
            itemuuid = nxball["itemuuid"]
            return false if itemuuid.nil?
            listingItems.any?{|item| item["uuid"] == itemuuid }
        }

        printItem = lambda {|store, item, canBeDefault|

            store.register(item, canBeDefault)

            tc = NxWTimeCommitments::getOrNull(item["tcId"])
            tcStr = tc ? " (NxWTimeCommitment: #{tc["description"]})" : ""
            line = "(#{store.prefixString()}) #{PolyFunctions::toStringForCatalystListing(item)}#{tcStr.green}"

            nxball = NxBalls::getNxBallForItemOrNull(item)

            if nxball then
                line = "#{line} #{NxBalls::toRunningStatement(nxball)}".green
            end

            puts line
            return CommonUtils::verticalSize(line)
        }

        getItemFromListingItemsOrNull = lambda {|items, uuid|
            items.select{|item| item["uuid"] == uuid }.first
        }

        system("clear")
        store = ItemStore.new()
        vspaceleft = CommonUtils::screenHeight() - 3

        puts ""
        vspaceleft = vspaceleft - 1

        # TimeCommitment total
        puts GeneralTimeCommitments::summaryLine()
        vspaceleft = vspaceleft - 1

        # The99 Percent
        line = The99Percent::lineOrNull()
        if line then
            puts The99Percent::lineOrNull()
            vspaceleft = vspaceleft - 1
        end

        # TimeCommitment report
        timecommitments = GeneralTimeCommitments::reportItemsX()
        if timecommitments.size > 0 then
            puts ""
            puts "time commitments".green
            vspaceleft = vspaceleft - 1
            timecommitments.each{|item|
                store.register(item, false)
                line = "(#{store.prefixString()}) #{GeneralTimeCommitments::toString(item)}"
                nxball = NxBalls::getNxBallForItemOrNull(item)
                if nxball then
                    line = "#{line} #{NxBalls::toRunningStatement(nxball)}".green
                end
                puts line
                vspaceleft = vspaceleft - 1
            }
        end

        if !InternetStatus::internetIsActive() then
            puts ""
            puts "INTERNET IS OFF".green
            vspaceleft = vspaceleft - 2
        end

        floats = TxFloats::listingItems()
        if floats.size > 0 then
            puts ""
            puts "floats".yellow
            vspaceleft = vspaceleft - 2
            floats.each{|item|
                linecount = printItem.call(store, item, false)
                vspaceleft = vspaceleft - linecount
            }
        end

        shelves = Locks::shelves()
        domains = shelves.map{|datum| datum["domain"] }.uniq
        domains.each{|domain|
            items = shelves
                        .select{|datum| datum["domain"] == domain }
                        .map{|datum| getItemFromListingItemsOrNull.call(listingItems, datum["uuid"]) }
                        .compact
            next if items.empty?
            puts ""
            puts "#{domain}".yellow
            vspaceleft = vspaceleft - 2
            items.each{|item|
                linecount = printItem.call(store, item, false)
                vspaceleft = vspaceleft - linecount
            }
        }

        tops = NsTopLines::listingItems()

        nxballs = NxBalls::items()
                    .select{|nxball| !nxballHasAnItemInThere.call(nxball, timecommitments + listingItems + tops) }

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

        tops = NsTopLines::listingItems()
        if tops.size > 0 then
            puts ""
            puts "tops".green
            vspaceleft = vspaceleft - 2
            tops.each{|item|
                store.register(item, !Skips::isSkipped(item["uuid"]))
                line = "(#{store.prefixString()}) (line) #{item["line"]}"
                nxball = NxBalls::getNxBallForItemOrNull(item)
                if nxball then
                    line = "#{line} #{NxBalls::toRunningStatement(nxball)}".green
                end
                puts line
                vspaceleft = vspaceleft - 1
            }
        end

        puts ""
        vspaceleft = vspaceleft - 1

        items1, items2 = listingItems.partition{|item| NxBalls::getNxBallForItemOrNull(item) }
        (items1 + items2)
            .each{|item|
                next if Locks::isLocked(item["uuid"])
                cbdf = (item["mikuType"] != "TxFloat") and !Skips::isSkipped(item["uuid"])
                linecount = printItem.call(store, item, cbdf)
                vspaceleft = vspaceleft - linecount
                break if vspaceleft <= 0
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

            listingItems = CatalystListing::listingItems()

            TheSpeedOfLight::manageSpeedOfLight()

            CatalystListing::displayListing(listingItems)
        }
    end
end
