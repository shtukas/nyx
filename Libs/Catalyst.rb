# encoding: UTF-8

class TerminalDisplayOperator

    # TerminalDisplayOperator::printListing(universe, floats, section2, section3)
    def self.printListing(universe, floats, section2, section3)
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
            floats.each{|ns16|
                store.register(ns16, false)
                line = "#{store.prefixString()} [#{Time.at(ns16["TxFloat"]["unixtime"]).to_s[0, 10]}] #{ns16["announce"]}".yellow
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
                        delegate = {
                            "uuid"     => nxball["uuid"],
                            "mikuType" => "NxBallNS16Delegate1" 
                        }
                        store.register(delegate, true)
                        line = "#{store.prefixString()} [running] #{nxball["description"]} (#{NxBallsService::activityStringOrEmptyString("", nxball["uuid"], "")})"
                        puts line.green
                        vspaceleft = vspaceleft - CommonUtils::verticalSize(line)
                    }
        end

        printSection = lambda {|section, store|
            section
                .each{|ns16|
                    store.register(ns16, true)
                    line = ns16["announce"]
                    line = "#{store.prefixString()} #{line}"
                    break if (vspaceleft - CommonUtils::verticalSize(line)) < 0
                    if NxBallsService::isActive(ns16["uuid"]) then
                        line = "#{line} (#{NxBallsService::activityStringOrEmptyString("", ns16["uuid"], "")})".green
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

        if section3.size > 0 and vspaceleft > 3 then
            puts "-" * 60
            vspaceleft = vspaceleft - 1
            printSection.call(section3, store)
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

        if input == ">>" then
            item = store.getDefault()
            XCache::set("a0e861a0-bb18-48fc-962d-e9d3367b7802:#{CommonUtils::today()}:#{item["uuid"]}", Time.new.to_f)
            return
        end

        command, objectOpt = Commands::inputParser(input, store)
        #puts "parser: command:#{command}, objectOpt: #{objectOpt}"

        LxAction::action(command, objectOpt)
    end
end

class Catalyst

    # Catalyst::program2()
    def self.program2()
        initialCodeTrace = CommonUtils::generalCodeTrace()
        loop {

            if CommonUtils::generalCodeTrace() != initialCodeTrace then
                puts "Code change detected"
                break
            end

            universe = nil # UniverseStored::getUniverseOrNull()

            floats = TxFloats::ns16s(universe)
                        .select{|item| DoNotShowUntil::isVisible(item["uuid"]) }
                        .select{|ns16| InternetStatus::ns16ShouldShow(ns16["uuid"]) }

            section2 = NS16s::ns16s(universe)

            filterSection3 = lambda{|ns16|
                return false if NxBallsService::isRunning(ns16["uuid"])
                return true if XCache::flagIsTrue("915b-09a30622d2b9:FyreIsDoneForToday:#{CommonUtils::today()}:#{ns16["uuid"]}")
                return false if !["NS16:TxProject", "NS16:TxTodo", "ADE4F121"].include?(ns16["mikuType"])
                ns16["rt"] > 1
            }

            section3, section2 = section2.partition{|ns16| filterSection3.call(ns16) }

            section2p1, section2p2 = section2.partition{|ns16| NxBallsService::isRunning(ns16["uuid"]) }

            section2 = section2p1 + section2p2

            TerminalDisplayOperator::printListing(universe, floats, section2, section3)
        }
    end
end
