# encoding: UTF-8

class TerminalDisplayOperator

    # TerminalDisplayOperator::printListing(universe, floats, section2)
    def self.printListing(universe, floats, section2)
        system("clear")

        vspaceleft = CommonUtils::screenHeight()-3

        reference = The99Percent::getReference()
        current   = The99Percent::getCurrentCount()
        ratio     = current.to_f/reference["count"]
        puts ""
        puts "(#{universe}) 👩‍💻 🔥 #{current} #{ratio}, #{reference["count"]} #{reference["datetime"]}"
        vspaceleft = vspaceleft - 2
        if ratio < 0.99 then
            The99Percent::issueNewReference()
            return
        end

        store = ItemStore.new()

        if !InternetStatus::internetIsActive() then
            puts "INTERNET IS OFF".green
            vspaceleft = vspaceleft - 2
        end

        if floats.size>0 then
            puts ""
            vspaceleft = vspaceleft - 1
            floats.each{|item|
                store.register(item, false)
                line = "#{store.prefixString()} [#{Time.at(item["unixtime"]).to_s[0, 10]}] #{LxFunction::function("toString", item)}".yellow
                puts line
                vspaceleft = vspaceleft - CommonUtils::verticalSize(line)
            }
        end

        slots = Slots::getSlots().strip
        if slots.size > 0 then
            puts ""
            puts slots.green
            vspaceleft = vspaceleft - (CommonUtils::verticalSize(slots) + 1)
        end

        running = NxBallsIO::getItems().select{|nxball| !section2.map{|item| item["uuid"] }.include?(nxball["uuid"]) }
        if running.size > 0 then
            puts ""
            vspaceleft = vspaceleft - 1
            running
                    .sort{|t1, t2| t1["unixtime"] <=> t2["unixtime"] } # || 0 because we had some running while updating this
                    .each{|nxball|
                        store.register(nxball, true)
                        line = "#{store.prefixString()} [running] #{nxball["description"]} (#{NxBallsService::activityStringOrEmptyString("", nxball["uuid"], "")})"
                        puts line.green
                        vspaceleft = vspaceleft - CommonUtils::verticalSize(line)
                    }
        end

        printSection = lambda {|section, store|
            section
                .each{|item|
                    store.register(item, true)
                    line = LxFunction::function("toString", item)
                    line = "#{store.prefixString()} #{line}"
                    break if (vspaceleft - CommonUtils::verticalSize(line)) < 0
                    if NxBallsService::isActive(item["uuid"]) then
                        line = "#{line} (#{NxBallsService::activityStringOrEmptyString("", item["uuid"], "")})".green
                    end
                    puts line
                    vspaceleft = vspaceleft - CommonUtils::verticalSize(line)
                }
        }

        if section2.size > 0 then
            puts ""
            vspaceleft = vspaceleft - 1
            printSection.call(section2, store)
        end

        puts ""
        input = LucilleCore::askQuestionAnswerAsString("> ")

        return if input == ""

        if input.start_with?("+") and (unixtime = CommonUtils::codeToUnixtimeOrNull(input.gsub(" ", ""))) then
            if (item = store.getDefault()) then
                DoNotShowUntil::setUnixtime(item["uuid"], unixtime)
                return
            end
        end

        command, objectOpt = Commands::inputParser(input, store)
        #puts "parser: command:#{command}, objectOpt: #{objectOpt}"

        LxAction::action(command, objectOpt)
    end
end

class Catalyst

    # Catalyst::itemsForListing(universe)
    def self.itemsForListing(universe)
        [
            Anniversaries::itemsForListing(),
            TxDateds::itemsForListing(),
            Waves::itemsForListing(universe),
            TxProjects::itemsForUniverse(universe),
            TxTodos::itemsForListing(universe),
        ]
            .flatten
    end

    # Catalyst::program2()
    def self.program2()
        initialCodeTrace = CommonUtils::generalCodeTrace()
        loop {

            if CommonUtils::generalCodeTrace() != initialCodeTrace then
                puts "Code change detected"
                break
            end

            universe = UniverseStored::getUniverseOrNull()

            floats = TxFloats::itemsForListing(universe)
                        .select{|item| DoNotShowUntil::isVisible(item["uuid"]) }
                        .select{|item| InternetStatus::itemShouldShow(item["uuid"]) }

            section2 = Catalyst::itemsForListing(universe)

            filterNotInSection2 = lambda{|item|
                return false if NxBallsService::isRunning(item["uuid"])
                return true if XCache::flagIsTrue("915b-09a30622d2b9:FyreIsDoneForToday:#{CommonUtils::today()}:#{item["uuid"]}")
                return false if !["TxProject", "TxTodo", "(rstream)"].include?(item["mikuType"])
                BankExtended::stdRecoveredDailyTimeInHours(item["uuid"]) > 1
            }

            _, section2 = section2.partition{|item| filterNotInSection2.call(item) }
            section2p1, section2p2 = section2.partition{|item| NxBallsService::isRunning(item["uuid"]) }
            section2 = section2p1 + section2p2
            section2 = section2
                .select{|item| DoNotShowUntil::isVisible(item["uuid"]) }
                .select{|item| InternetStatus::itemShouldShow(item["uuid"]) }

            TerminalDisplayOperator::printListing(universe, floats, section2)
        }
    end
end
