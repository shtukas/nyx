# encoding: UTF-8

class Listing

    # Listing::listingCommands()
    def self.listingCommands()
        [
            "[all] .. | <datecode> | access (<n>) | do not show until <n> | done (<n>) | edit (<n>) | expose (<n>) | probe (<n>) | >> skip default | lock (<n>) | destroy",
            "[makers] wave | anniversary | today | ondate | todo | manual countdown | block",
            "[divings] anniversaries | ondates | waves | todos",
            "[NxOndate] redate",
            "[NxTimeDrops] start | stop",
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
            puts Listing::listingCommands().yellow
            LucilleCore::pressEnterToContinue()
            return
        end

        if Interpreting::match("destroy", input) then
            item = store.getDefault()
            return if item.nil?
            if LucilleCore::askQuestionAnswerAsBoolean("confirm destruction of #{item["mikuType"]} '#{PolyFunctions::toString(item).green}' ") then
                TodoDatabase2::destroy(item["uuid"])
            end
            return
        end

        if Interpreting::match("destroy *", input) then
            _, ordinal = Interpreting::tokenizer(input)
            item = store.get(ordinal.to_i)
            return if item.nil?
            if LucilleCore::askQuestionAnswerAsBoolean("confirm destruction of #{item["mikuType"]} '#{PolyFunctions::toString(item).green}' ") then
                TodoDatabase2::destroy(item["uuid"])
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

        if Interpreting::match("edit", input) then
            item = store.getDefault()
            return if item.nil?
            PolyActions::edit(item)
            return
        end

        if Interpreting::match("edit *", input) then
            _, ordinal = Interpreting::tokenizer(input)
            item = store.get(ordinal.to_i)
            return if item.nil?
            PolyActions::edit(item)
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
            NxOndates::report()
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

        if Interpreting::match("redate", input) then
            item = store.getDefault()
            return if item.nil?
            if item["mikuType"] != "NxOndate" then
                puts "command redate is only for NxOndates"
                LucilleCore::pressEnterToContinue
                return
            end
            unixtime = CommonUtils::interactivelySelectUnixtimeUsingDateCodeOrNull()
            item["doNotShowUntil"] = unixtime
            item["datetime"] = Time.at(unixtime).utc.iso8601
            TodoDatabase2::commitItem(item)
            return
        end

        if Interpreting::match("start", input) then
            item = store.getDefault()
            return if item.nil?
            if item["mikuType"] != "NxTimeDrop" then
                puts "> the start command is only available for NxTimeDrops"
                LucilleCore::pressEnterToContinue()
                return
            end
            NxTimeDrops::start(item)
            return
        end

        if Interpreting::match("stop", input) then
            item = store.getDefault()
            return if item.nil?
            if item["mikuType"] != "NxTimeDrop" then
                puts "> the stop command is only available for NxTimeDrops"
                LucilleCore::pressEnterToContinue()
            end
            NxTimeDrops::stop(item)
            return
        end

        if Interpreting::match("search", input) then
            SearchCatalyst::run()
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

    # Listing::isNxTimeDropAndCompleted(item)
    def self.isNxTimeDropAndCompleted(item)
        return false if item["mikuType"] != "NxTimeDrop"
        return false if (item["field2"] and item["field2"] > 0)
        return false if item["field1"] > 0
        true
    end

    # Listing::mainProgram2Pure()
    def self.mainProgram2Pure()

        initialCodeTrace = CommonUtils::stargateTraceCode()

        $SyncConflictInterruptionFilepath = nil

        Database2Engine::activationsForListingOrNothing()

        NxTimeDrops::garbageCollection()

        Thread.new {
            loop {
                sleep 300
                Database2Engine::activationsForListingOrNothing()
            }
        }

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

            system("clear")
            store = ItemStore.new()
            vspaceleft = CommonUtils::screenHeight() - 3

            puts ""
            puts The99Percent::line()
            vspaceleft = vspaceleft - 2

            puts ""
            drops = Database2Data::itemsForMikuType("NxTimeDrop")
            Database2Data::itemsForMikuType("NxTimeCommitment")
                .each{|item|
                    store.register(item, false)
                    hours = drops.select{|drop| drop["field4"] == item["uuid"] }.map{|drop| drop["field1"] }.inject(0, :+)
                    puts "(#{store.prefixString()}) #{item["description"].ljust(10)} (left: #{("%5.2f" % hours).to_s.green} hours, out of #{"%5.2f" % item["hours"]}) reset #{"%5.2f" %  ((Time.new.to_i - item["resetTime"]).to_f/86400)} days ago"
                    vspaceleft = vspaceleft - 1
                }
            vspaceleft = vspaceleft - 3

            puts ""
            puts "> lock | wave | ondate | todo".yellow
            vspaceleft = vspaceleft - 2

            trajectoryToNumber = lambda{|trajectory|
                return 0.8 if trajectory.nil?
                return 0 if Time.new.to_i < trajectory["activationunixtime"]
                [1, (Time.new.to_i - trajectory["activationunixtime"]).to_f/(trajectory["expectedTimeToCompletionInHours"]*3600)].min
            }

            puts ""
            vspaceleft = vspaceleft - 1
            Database2Data::listingItems()
                .select{|item| DoNotShowUntil::isVisible(item) }
                .map{|item|
                    item["listing:position"] = trajectoryToNumber.call(item["field13"])
                    item
                }
                .sort{|i1, i2| i1["listing:position"] <=> i2["listing:position"] }
                .reverse
                .each{|item|
                    next if Listing::isNxTimeDropAndCompleted(item)
                    store.register(item, !Skips::isSkipped(item) && !Locks::isLocked(item))
                    line = "(#{store.prefixString()}) #{PolyFunctions::toStringForListing(item)}"
                    if Locks::isLocked(item) then
                        line = "#{line} [lock: #{item["field8"]}]"
                    end
                    if item["mikuType"] == "NxTimeDrop" then
                        if item["field2"] and item["field2"] > 0 then
                            runningFor = (Time.new.to_i - item["field2"]).to_f/3600
                            line = "#{line} (running for #{runningFor.round(2)} hours)".green
                        end
                    end
                    puts line
                    vspaceleft = vspaceleft - CommonUtils::verticalSize(line)
                    break if vspaceleft <= 0
                }

            puts ""
            input = LucilleCore::askQuestionAnswerAsString("> ")
            next if input == ""

            Listing::listingCommandInterpreter(input, store)
        }
    end
end
