# encoding: UTF-8

class Listing

    # Listing::listingCommands()
    def self.listingCommands()
        [
            "[all] .. | <datecode> | access (<n>) | do not show until <n> | done (<n>) | landing (<n>) | expose (<n>) | >> skip default | lock (<n>) | add time (<n>) | board (<n>) | destroy",
            "[makers] anniversary | manual countdown | wave | today | ondate | drop | top",
            "[divings] anniversaries | ondates | waves | todos | desktop | open",
            "[NxBalls] start | start * | stop | stop * | pause | pursue",
            "[NxOndate] redate",
            "[misc] search | speed | commands",
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

        if Interpreting::match("add time", input) then
            item = store.getDefault()
            return if item.nil?
            timeInHours = LucilleCore::askQuestionAnswerAsString("time in hours: ").to_f
            PolyFunctions::itemsToBankingAccounts(item).each{|account|
                puts "Adding #{timeInHours*3600} seconds to item: #{account["description"]}"
                BankCore::put(account["number"], timeInHours*3600)
            }
        end

        if Interpreting::match("add time *", input) then
            _, _, ordinal = Interpreting::tokenizer(input)
            item = store.get(ordinal.to_i)
            return if item.nil?
            timeInHours = LucilleCore::askQuestionAnswerAsString("time in hours: ").to_f
            PolyFunctions::itemsToBankingAccounts(item).each{|account|
                puts "Adding #{timeInHours*3600} seconds to item: #{account["description"]}"
                BankCore::put(account["number"], timeInHours*3600)
            }
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
            NxBoards::interactivelyOffersToAttachBoard(item)
            return
        end

        if Interpreting::match("board *", input) then
            _, ordinal = Interpreting::tokenizer(input)
            item = store.get(ordinal.to_i)
            return if item.nil?
            NxBoards::interactivelyOffersToAttachBoard(item)
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
            puts "edit description:"
            item["description"] = CommonUtils::editTextSynchronously(item["description"])
            raise "not implemented"
            return
        end

        if Interpreting::match("description *", input) then
            _, ordinal = Interpreting::tokenizer(input)
            item = store.get(ordinal.to_i)
            return if item.nil?
            puts "edit description:"
            item["description"] = CommonUtils::editTextSynchronously(item["description"])
            raise "not implemented"
            return
        end

        if Interpreting::match("desktop", input) then
            system("open '#{Desktop::desktopFolderPath()}'")
            return
        end

        if Interpreting::match("destroy", input) then
            item = store.getDefault()
            return if item.nil?
            raise "not implemented"
            if LucilleCore::askQuestionAnswerAsBoolean("confirm destruction of #{item["mikuType"]} '#{PolyFunctions::toString(item).green}' ") then
                
            end
            return
        end

        if Interpreting::match("destroy *", input) then
            _, ordinal = Interpreting::tokenizer(input)
            item = store.get(ordinal.to_i)
            return if item.nil?
            raise "not implemented"
            if LucilleCore::askQuestionAnswerAsBoolean("confirm destruction of #{item["mikuType"]} '#{PolyFunctions::toString(item).green}' ") then
                
            end
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
            if board then
                NxBoardItems::interactivelyIssueNewOrNull(board)
            else
                NxTopStreams::interactivelyIssueNewOrNull()
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

        if Interpreting::match("ondate", input) then
            item = NxOndates::interactivelyIssueNullOrNull()
            return if item.nil?
            puts JSON.pretty_generate(item)
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

        if Interpreting::match("today", input) then
            item = NxOndates::interactivelyIssueNewTodayOrNull()
            return if item.nil?
            puts JSON.pretty_generate(item)
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

    # Listing::items()
    def self.items()
        [
            Anniversaries::listingItems(),
            NxOndates::listingItems(),
            Waves::topItems(),
            NxBoards::listingItems(),
            Waves::listingItems("ns:today-or-tomorrow"),
            Waves::leisureItemsWithCircuitBreaker(),
            NxTopStreams::listingItems()
        ]
            .flatten
            .select{|item| DoNotShowUntil::isVisible(item["uuid"]) }
    end

    # Listing::printDesktop()
    def self.printDesktop()
        linecount = 0
        dskt = Desktop::contentsOrNull()
        if dskt and dskt.size > 0 then
            dskt = dskt.lines.map{|line| "      #{line}" }.join()
            puts "(-->) Desktop:".green
            puts dskt
            linecount = linecount + (CommonUtils::verticalSize(dskt) + 1)
        end
        linecount
    end

    # Listing::itemToListingLine(store or nil, item)
    def self.itemToListingLine(store, item)
        storePrefix = store ? "(#{store.prefixString()})" : "     "
        line = "#{storePrefix} #{PolyFunctions::toString(item)}#{NxBalls::nxballSuffixStatusIfRelevant(item)}#{NxBoards::toStringSuffix(item)}"
        if Locks::isLocked(item["uuid"]) then
            line = "#{line} [lock: #{Locks::locknameOrNull(item["uuid"])}]".yellow
        end
        if NxBalls::itemIsRunning(item) or NxBalls::itemIsPaused(item) then
            line = line.green
        end
        line
    end

    # Listing::itemsToVerticalSpace(items)
    def self.itemsToVerticalSpace(items)
        items
            .map{|item|
                line = Listing::itemToListingLine(nil, item)
                CommonUtils::verticalSize(line)
            }
            .inject(0, :+)
    end

    # Listing::printBottomBoards(store, isSimulation)
    def self.printBottomBoards(store, isSimulation)
        linecount = 0
        NxBoards::bottomItems().each{|item|
            store.register(item, false)
            line = "#{Listing::itemToListingLine(store, item)}"
            if !isSimulation then
                if NxBalls::itemIsRunning(item) or NxBalls::itemIsPaused(item) then
                    puts line.green
                else
                    puts line.yellow
                end
            end
            linecount = linecount + CommonUtils::verticalSize(line)
        }
        linecount
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

            LucilleCore::locationsAtFolder("#{ENV['HOME']}/Galaxy/DataHub/NxTailStreams-FrontElements-BufferIn")
                .each{|location|
                    next if File.basename(location).start_with?(".")
                    item = NxTailStreams::bufferInImport(location)
                    puts "Picked up from NxTailStreams-FrontElements-BufferIn: #{JSON.pretty_generate(item)}"
                    LucilleCore::removeFileSystemLocation(location)
                }

            NxBoards::timeManagement()
            NxStreamsCommon::dataManagement()

            system("clear")
            store = ItemStore.new()
            vspaceleft = CommonUtils::screenHeight() - 3

            puts ""
            vspaceleft = vspaceleft - 1

            puts The99Percent::line()
            vspaceleft = vspaceleft - 1

            items = Listing::items()

            NxBoards::boardsOrdered().each{|board|
                store.register(board, false)
                puts "(#{store.prefixString()}) #{NxBoards::toString(board)}".yellow
                vspaceleft = vspaceleft - 1
            }

            lockedItems, items = items.partition{|item| Locks::isLocked(item["uuid"]) }

            lockedItems
                .each{|item|
                    store.register(item, false)
                    line = Listing::itemToListingLine(store, item)
                    puts line
                    vspaceleft = vspaceleft - CommonUtils::verticalSize(line)
                }


            puts ""
            vspaceleft = vspaceleft - 1

            NxOpens::items().each{|o|
                store.register(o, false)
                puts "(#{store.prefixString()}) (open) #{o["description"]}".yellow
                vspaceleft = vspaceleft - 1
            }

            NxTops::itemsInOrder().each{|item|
                store.register(item, true)
                puts Listing::itemToListingLine(store, item)
                vspaceleft = vspaceleft - 1
            }

            linecount = Listing::printDesktop()
            vspaceleft = vspaceleft - linecount

            vspaceleft = vspaceleft - NxBoards::bottomItems().size

            runningItems, items = items.partition{|item| NxBalls::itemIsRunning(item) }

            (runningItems + items)
                .each{|item|
                    store.register(item, !Skips::isSkipped(item["uuid"]))
                    line = Listing::itemToListingLine(store, item)
                    puts line
                    vspaceleft = vspaceleft - CommonUtils::verticalSize(line)
                    break if vspaceleft <= 0
                }

            NxBoards::bottomItems().each{|item|
                store.register(item, false)
                line = "#{Listing::itemToListingLine(store, item)}"
                if !isSimulation then
                    if NxBalls::itemIsRunning(item) or NxBalls::itemIsPaused(item) then
                        puts line.green
                    else
                        puts line.yellow
                    end
                end
            }

            puts ""
            input = LucilleCore::askQuestionAnswerAsString("> ")
            next if input == ""

            Listing::listingCommandInterpreter(input, store, nil)
        }
    end
end
