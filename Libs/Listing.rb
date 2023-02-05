# encoding: UTF-8

class Listing

    # Listing::listingCommands()
    def self.listingCommands()
        [
            "[all] .. | <datecode> | access (<n>) | do not show until <n> | done (<n>) | landing (<n>) | expose (<n>) | >> skip default | lock (<n>) | set time commitment (<n>) | destroy",
            "[makers] anniversary | manual countdown | wave | today | ondate | todo | drop | top | capsule",
            "[divings] anniversaries | ondates | waves | todos | desktop",
            "[NxBalls] start | start * | stop | stop * | pause | pursue",
            "[NxTodo] redate",
            "[misc] search | speed | commands",
        ].join("\n")
    end

    # Listing::listingCommandInterpreter(input, store)
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
            datecode = LucilleCore::askQuestionAnswerAsString("datecode: ")
            return if datecode == ""
            unixtime = CommonUtils::codeToUnixtimeOrNull(datecode.gsub(" ", ""))
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
            ObjectStore2::commit("NxOndates", item)
            DoNotShowUntil::setUnixtime(item["uuid"], unixtime)
            return
        end

        if Interpreting::match("set time commitment", input) then
            item = store.getDefault()
            return if item.nil?
            tc = NxTimeCommitments::interactivelySelectOneOrNull()
            return if tc.nil?
            ItemToTimeCommitmentMapping::set(item["uuid"], tc["uuid"])
            return
        end

        if Interpreting::match("set time commitment *", input) then
            _, ordinal = Interpreting::tokenizer(input)
            item = store.get(ordinal.to_i)
            return if item.nil?
            tc = NxTimeCommitments::interactivelySelectOneOrNull()
            return if tc.nil?
            ItemToTimeCommitmentMapping::set(item["uuid"], tc["uuid"])
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
            item = NxTodos::interactivelyIssueNewTodayOrNull()
            return if item.nil?
            puts JSON.pretty_generate(item)
            return
        end

        if Interpreting::match("todo", input) then
            item = NxTodos::interactivelyIssueNewRegularOrNull()
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
            NxDrops::items(),
            NxOndates::listingItems(),
            NxTimeCommitments::items(),
            NxTodos::listingItems(),
            NxTops::items(),
            NxTriages::items(),
            Waves::listingItems(),
        ]
            .flatten
            .select{|item| DoNotShowUntil::isVisible(item["uuid"]) }
    end

    # Listing::listingVelocity(item)
    def self.listingVelocity(item)
        trajectory = Lookups::getValueOrNull("ListingTrajectories", item["uuid"])
        return trajectory if trajectory
        trajectory = {
            "unixtime"        => Time.new.to_f,
            "position1"       => 0,
            "position2"       => 1,
            "timespanInHours" => 24
        }
        Lookups::commit("ListingTrajectories", item["uuid"], trajectory)
        trajectory
    end

    # Listing::trajectoryToPosition(trajectory)
    def self.trajectoryToPosition(trajectory)
        position = trajectory["position1"] + (Time.new.to_f - trajectory["unixtime"]).to_f/(trajectory["timespanInHours"]*3600)
        [position, trajectory["position2"]].min
    end

    # Listing::mainProgram2Pure()
    def self.mainProgram2Pure()

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

            trajectoryToNumber = lambda{|trajectory|
                return 0.8 if trajectory.nil?
                value = (Time.new.to_i - trajectory["activationunixtime"]).to_f/(trajectory["expectedTimeToCompletionInHours"]*3600)
                [value, 9.99].min
            }

            itemToLine = lambda {|store, item|
                line = "(#{store.prefixString()}) #{PolyFunctions::toStringForListing(item)}#{ItemToTimeCommitmentMapping::toStringSuffix(item)}#{NxBalls::nxballSuffixStatusIfRelevant(item)}"
                if Locks::isLocked(item["uuid"]) then
                    line = "#{line} [lock: #{Locks::locknameOrNull(item["uuid"])}]".yellow
                end
                if NxBalls::itemIsRunning(item) or NxBalls::itemIsPaused(item) then
                    line = line.green
                end
                line
            }

            system("clear")
            store = ItemStore.new()
            vspaceleft = CommonUtils::screenHeight() - 4

            puts ""

            dskt = Desktop::contentsOrNull()
            if dskt and dskt.size > 0 then
                puts "Desktop:".green
                vspaceleft = vspaceleft - 2
                puts dskt
                vspaceleft = vspaceleft - CommonUtils::verticalSize(dskt)
            end

            tops = NxTops::items()
            if tops.size > 0 then
                tops.each{|item|
                    store.register(item, true)
                    line = "(#{store.prefixString()})         #{NxTops::toString(item)}#{NxBalls::nxballSuffixStatusIfRelevant(item)}"
                    if line. include?("running") then
                        line = line.green
                    end
                    puts line
                    vspaceleft = vspaceleft - 1
                }
            end
            timecommitments = NxTimeCommitments::items()
            vspaceleft = vspaceleft - timecommitments.size

            items = Listing::items()
                        .map{|item|
                            trajectory = Listing::listingVelocity(item)
                            item["listing:position"] = Listing::trajectoryToPosition(trajectory)
                            item
                        }
                        .sort{|i1, i2| i1["listing:position"] <=> i2["listing:position"] }
                        .reverse

            lockedItems, items = items.partition{|item| Locks::isLocked(item["uuid"]) }
            lockedItems.each{|item|
                vspaceleft = vspaceleft - CommonUtils::verticalSize(PolyFunctions::toStringForListing(item))
            }

            items
                .each{|item|
                    store.register(item, !Skips::isSkipped(item["uuid"]))
                    line = itemToLine.call(store, item)
                    puts line
                    vspaceleft = vspaceleft - CommonUtils::verticalSize(line)
                    break if vspaceleft <= 0
                }

            lockedItems
                .each{|item|
                    store.register(item, false)
                    line = itemToLine.call(store, item)
                    puts line
                    vspaceleft = vspaceleft - CommonUtils::verticalSize(line)
                    break if vspaceleft <= 0
                }

            timecommitments
                .each{|item|
                    store.register(item, false)
                    line = "(#{store.prefixString()}) #{NxTimeCommitments::toStringForListing(item)}#{NxBalls::nxballSuffixStatusIfRelevant(item)}"
                    if NxBalls::itemIsRunning(item) or NxBalls::itemIsPaused(item) then
                        line = line.green
                    end
                    puts line
                }

            puts The99Percent::line()

            puts ""
            input = LucilleCore::askQuestionAnswerAsString("> ")
            next if input == ""

            Listing::listingCommandInterpreter(input, store)
        }
    end
end
