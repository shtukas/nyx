# encoding: UTF-8

class Listing

    # Listing::listingCommands()
    def self.listingCommands()
        [
            "[all] .. | <datecode> | access (<n>) | do not show until <n> | done (<n>) | touch (<n>) | expose (<n>) | >> skip default | lock (<n>) | push | destroy",
            "[makers] anniversary | manual countdown | wave | today | ondate | todo",
            "[divings] anniversaries | ondates | waves | todos",
            "[NxTodo] redate",
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

        if Interpreting::match("description", input) then
            item = store.getDefault()
            return if item.nil?
            puts "edit description:"
            item["description"] = CommonUtils::editTextSynchronously(item["description"])
            TodoDatabase2::commitItem(item)
            return
        end

        if Interpreting::match("description *", input) then
            _, ordinal = Interpreting::tokenizer(input)
            item = store.get(ordinal.to_i)
            return if item.nil?
            puts "edit description:"
            item["description"] = CommonUtils::editTextSynchronously(item["description"])
            TodoDatabase2::commitItem(item)
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
            item = NxTodos::interactivelyIssueNewOndateOrNull()
            return if item.nil?
            puts JSON.pretty_generate(item)
            return
        end

        if Interpreting::match("ondates", input) then
            NxTodos::ondateReport()
            return
        end

        if Interpreting::match("push", input) then
            item = store.getDefault()
            return if item.nil?
            trajectory = Database2Engine::trajectory(Time.new.to_f + 3600*6, 24)
            TodoDatabase2::set(item["uuid"], "field13", JSON.generate(trajectory))
            return
        end

        if Interpreting::match("redate", input) then
            item = store.getDefault()
            return if item.nil?
            if item["mikuType"] != "NxTodo" then
                puts "redate is reserved for NxTodos"
                LucilleCore::pressEnterToContinue()
                return
            end
            if item["field2"] != "ondate" then
                puts "redate is reserved for NxTodos with ondate"
                LucilleCore::pressEnterToContinue()
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

        if Interpreting::match("start *", input) then
            _, ordinal = Interpreting::tokenizer(input)
            item = store.get(ordinal.to_i)
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

        if Interpreting::match("stop *", input) then
            _, ordinal = Interpreting::tokenizer(input)
            item = store.get(ordinal.to_i)
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

        if Interpreting::match("touch", input) then
            item = store.getDefault()
            return if item.nil?
            PolyActions::touch(item)
            return
        end

        if Interpreting::match("touch *", input) then
            _, ordinal = Interpreting::tokenizer(input)
            item = store.get(ordinal.to_i)
            return if item.nil?
            PolyActions::touch(item)
            return
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

    # Listing::isNxTimeDropStoppedAndCompleted(item)
    def self.isNxTimeDropStoppedAndCompleted(item)
        return false if item["mikuType"] != "NxTimeDrop"
        return false if item["field2"]     # we are running
        return false if item["field1"] > 0 # we are still positive
        true
    end

    # Listing::mainProgram2Pure()
    def self.mainProgram2Pure()

        initialCodeTrace = CommonUtils::stargateTraceCode()

        $SyncConflictInterruptionFilepath = nil

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
                    item = NxTodos::bufferInImport(location)
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
            vspaceleft = vspaceleft - 1
            drops = Database2Data::itemsForMikuType("NxTimeDrop")
            Database2Data::itemsForMikuType("NxTimeCommitment")
                .each{|item|
                    store.register(item, false)
                    hours = drops.select{|drop| drop["field4"] == item["uuid"] }.map{|drop| drop["field1"] }.inject(0, :+)
                    sinceResetInSeconds = Time.new.to_i - item["resetTime"]
                    sinceResetInDays = sinceResetInSeconds.to_f/86400
                    str1 = 
                        if sinceResetInDays < 7 then
                            " (#{(7 - sinceResetInDays).round(2)} days left)"
                        else
                            " (late by #{(7 - sinceResetInDays).round(2)} days)"
                        end
                    puts "(#{store.prefixString()}) #{item["description"].ljust(10)} (left: #{("%5.2f" % hours).to_s.green} hours, out of #{"%5.2f" % item["hours"]})#{str1}"
                    vspaceleft = vspaceleft - 1
                }

            puts ""
            puts "> access | done | touch | todo | today | ondate | wave | lock | >>".yellow
            vspaceleft = vspaceleft - 2

            trajectoryToNumber = lambda{|trajectory|
                return 0.8 if trajectory.nil?
                (Time.new.to_i - trajectory["activationunixtime"]).to_f/(trajectory["expectedTimeToCompletionInHours"]*3600)
            }

            puts ""
            vspaceleft = vspaceleft - 1
            Database2Data::listingItems()
                .select{|item| DoNotShowUntil::isVisible(item) }
                .map{|item|
                    item["listing:position"] = trajectoryToNumber.call(item["field13"])
                    item
                }
                .select{|item| item["listing:position"] > 0 }
                .sort{|i1, i2| i1["listing:position"] <=> i2["listing:position"] }
                .reverse
                .each{|item|
                    next if Listing::isNxTimeDropStoppedAndCompleted(item)
                    store.register(item, !Skips::isSkipped(item) && !Locks::isLocked(item))
                    line = "(#{"%5.2f" % item["listing:position"]}) (#{store.prefixString()}) #{PolyFunctions::toStringForListing(item)}"
                    if Locks::isLocked(item) then
                        line = "#{line} [lock: #{item["field8"]}]"
                    end
                    if item["mikuType"] == "NxTimeDrop" then
                        if item["field2"] then
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
