# encoding: UTF-8

class Listing

    # Listing::listingCommands()
    def self.listingCommands()
        [
            "[all] .. | <datecode> | access (<n>) | do not show until <n> | done (<n>) | landing (<n>) | expose (<n>) | >> skip default | lock (<n>) | set tc (<n>) | destroy",
            "[makers] anniversary | manual countdown | wave | today | ondate | todo | drop | top | capsule",
            "[divings] anniversaries | ondates | waves | todos | desktop",
            "[NxBalls] start | start * | stop | stop * | pause | pursue",
            "[NxOndate] redate",
            "[misc] search | speed | commands",
        ].join("\n")
    end

    # Listing::listingCommandInterpreter(input, store, contextualBoardOpt or nil)
    def self.listingCommandInterpreter(input, store, contextualBoardOpt)

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
            puts Listing::listingCommands().yellow
            LucilleCore::pressEnterToContinue()
            return
        end

        if Interpreting::match("capsule", input) then

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
            NxDrops::interactivelyIssueNewOrNull()
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
            NxTodos::ondateReport()
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
            unixtime = CommonUtils::interactivelySelectUnixtimeUsingDateCodeOrNull()
            item["datetime"] = Time.at(unixtime).utc.iso8601
            NxOndates::commit(item)
            DoNotShowUntil::setUnixtime(item["uuid"], unixtime)
            return
        end

        if Interpreting::match("set tc", input) then
            item = store.getDefault()
            return if item.nil?
            ItemToTimeCommitmentMapping::interactiveProposalToSetMapping(item)
            return
        end

        if Interpreting::match("set tc *", input) then
            _, _, ordinal = Interpreting::tokenizer(input)
            item = store.get(ordinal.to_i)
            return if item.nil?
            ItemToTimeCommitmentMapping::interactiveProposalToSetMapping(item)
            return
        end

        if Interpreting::match("start", input) then
            item = store.getDefault()
            return if item.nil?
            NxBalls::start(item)
            return
        end

        if Interpreting::match("start *", input) then
            _, ordinal = Interpreting::tokenizer(input)
            item = store.get(ordinal.to_i)
            return if item.nil?
            NxBalls::start(item)
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

        if Interpreting::match("top", input) then
            NxTops::interactivelyIssueNullOrNull()
        end

        if Interpreting::match("today", input) then
            item = NxOndates::interactivelyIssueNewTodayOrNull()
            return if item.nil?
            puts JSON.pretty_generate(item)
            return
        end

        if Interpreting::match("todo", input) then
            item = NxTodos::interactivelyIssueNewOrNull(contextualBoardOpt)
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
            NxBoards::listingItems(),
            NxDrops::items(),
            NxOndates::listingItems(),
            NxTimeCommitments::items(),
            NxTriages::items(),
            Waves::listingItems(),
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

    # Listing::itemListingPosition(item)
    def self.itemListingPosition(item)

        trajectory = nil
        
        return 1 if NxBalls::itemIsRunning(item)
        return 1 if PolyFunctions::toStringForListing(item).include?("sticky")

        if item["mikuType"] == "NxAnniversary" then
            return 0.9
        end

        if item["mikuType"] == "NxTop" then
            return 0.9
        end

        if item["mikuType"] == "NxTriage" then
            return 0.7
        end

        if item["mikuType"] == "NxTimeCommitment" then
            return 0.7 + NxTimeCommitments::differentialForListingPosition(item)
        end

        if item["mikuType"] == "NxBoard" then
            return 0.6 + NxBoards::differentialForListingPosition(item)
        end

        if item["mikuType"] == "NxBoardFirstItem" then
            return 0.6 + NxBoards::differentialForListingPosition(item["board"])
        end

        if item["mikuType"] == "NxOndate" then
            trajectory = Lookups::getValueOrNull("ListingTrajectories", item["uuid"])
            if trajectory.nil? then
                trajectory = {
                    "unixtime"        => Time.new.to_f,
                    "position1"       => 0.5,
                    "position2"       => 1,
                    "timespanInHours" => 12
                }
                Lookups::commit("ListingTrajectories", item["uuid"], trajectory)
            end
        end

        if item["mikuType"] == "NxDrop" then
            trajectory = Lookups::getValueOrNull("ListingTrajectories", item["uuid"])
            if trajectory.nil? then
                trajectory = {
                    "unixtime"        => Time.new.to_f,
                    "position1"       => 0,
                    "position2"       => 1,
                    "timespanInHours" => 48
                }
                Lookups::commit("ListingTrajectories", item["uuid"], trajectory)
            end
        end

        if item["mikuType"] == "Wave" then
            trajectory = Lookups::getValueOrNull("ListingTrajectories", item["uuid"])
            if trajectory.nil? then
                mapping1 = {
                    "ns:high"   => 0.7,
                    "ns:medium" => 0.4,
                    "ns:low"    => 0.2
                }
                mapping2 = {
                    "ns:high"   => 2,
                    "ns:medium" => 24,
                    "ns:low"    => 72
                }
                trajectory = {
                    "unixtime"        => Time.new.to_f,
                    "position1"       => mapping1[item["priority"]],
                    "position2"       => 0.8,
                    "timespanInHours" => mapping2[item["priority"]]
                }
                Lookups::commit("ListingTrajectories", item["uuid"], trajectory)
            end
        end

        if trajectory.nil? then
            raise "missing trajectory for item: #{item}"
        end

        ratio = (Time.new.to_f - trajectory["unixtime"]).to_f/(trajectory["timespanInHours"]*3600)
        position = trajectory["position1"] + ratio*(trajectory["position2"]-trajectory["position1"])
        [position, trajectory["position2"]].min
    end

    # Listing::itemToListingLine(store, item, afterOrdinalFragment)
    def self.itemToListingLine(store, item, afterOrdinalFragment)
        listingposition = item["listing:position"] ? " (#{"%5.2f" % item["listing:position"]})" : ""
        line = "(#{store.prefixString()})#{listingposition} #{PolyFunctions::toStringForListing(item)}#{ItemToTimeCommitmentMapping::toStringSuffix(item)}#{NxBalls::nxballSuffixStatusIfRelevant(item)}"
        if Locks::isLocked(item["uuid"]) then
            line = "#{line} [lock: #{Locks::locknameOrNull(item["uuid"])}]".yellow
        end
        if NxBalls::itemIsRunning(item) or NxBalls::itemIsPaused(item) then
            line = line.green
        end
        line
    end

    # Listing::printTops(store)
    def self.printTops(store)
        linecount = 0
        NxTops::items()
        .sort{|i1, i2| i1["ordinal"] <=> i2["ordinal"] }
        .each{|item|
            store.register(item, true)
            line = Listing::itemToListingLine(store, item, nil)
            puts line
            linecount = linecount + CommonUtils::verticalSize(line)
        }
        linecount
    end

    # Listing::printProcesses(store, isSimulation)
    def self.printProcesses(store, isSimulation)
        linecount = 0
        (NxTimeCommitments::items() + NxBoards::items()).each{|item|
            store.register(item, false)
            line = "#{Listing::itemToListingLine(store, item, nil)}"
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

            LucilleCore::locationsAtFolder("#{ENV['HOME']}/Galaxy/DataHub/NxTodos-BufferIn")
                .each{|location|
                    next if File.basename(location).start_with?(".")
                    item = NxTriages::bufferInImport(location)
                    puts "Picked up from NxTodos-BufferIn: #{JSON.pretty_generate(item)}"
                    LucilleCore::removeFileSystemLocation(location)
                }

            NxTimeCommitments::timeManagement()
            NxBoards::dataMaintenance()

            system("clear")
            store = ItemStore.new()
            vspaceleft = CommonUtils::screenHeight() - 3

            puts ""
            vspaceleft = vspaceleft - 1

            vspaceleft = vspaceleft - 1 # The99Percent::line()

            linecount = Listing::printDesktop()
            vspaceleft = vspaceleft - linecount

            linecount = Listing::printTops(store)
            vspaceleft = vspaceleft - linecount

            linecount = Listing::printProcesses(store, true)
            vspaceleft = vspaceleft - linecount

            items = Listing::items()
                        .map{|item|
                            item["listing:position"] = Listing::itemListingPosition(item)
                            item
                        }
                        .sort{|i1, i2| i1["listing:position"] <=> i2["listing:position"] }
                        .reverse

            lockedItems, items = items.partition{|item| Locks::isLocked(item["uuid"]) }
            lockedItems.each{|item|
                vspaceleft = vspaceleft - CommonUtils::verticalSize(PolyFunctions::toStringForListing(item))
            }

            lockedItems
                .each{|item|
                    store.register(item, false)
                    line = Listing::itemToListingLine(store, item, nil)
                    puts line
                    vspaceleft = vspaceleft - CommonUtils::verticalSize(line)
                }

            runningItems, items = items.partition{|item| NxBalls::itemIsRunning(item) }

            (runningItems + items)
                .each{|item|
                    store.register(item, !Skips::isSkipped(item["uuid"]))
                    line = Listing::itemToListingLine(store, item, nil)
                    puts line
                    vspaceleft = vspaceleft - CommonUtils::verticalSize(line)
                    break if vspaceleft <= 0
                }

            Listing::printProcesses(store, false)
            puts The99Percent::line()

            puts ""
            input = LucilleCore::askQuestionAnswerAsString("> ")
            next if input == ""

            Listing::listingCommandInterpreter(input, store, nil)
        }
    end
end
