# encoding: UTF-8

class TerminalUtils

    # TerminalUtils::removeDuplicatesOnAttribute(array, attribute)
    def self.removeDuplicatesOnAttribute(array, attribute)
        array.reduce([]){|selected, element|
            if selected.none?{|x| x[attribute] == element[attribute] } then
                selected + [element]
            else
                selected
            end
        }
    end

    # TerminalUtils::removeRedundanciesInSecondArrayRelativelyToFirstArray(array1, array2)
    def self.removeRedundanciesInSecondArrayRelativelyToFirstArray(array1, array2)
        uuids1 = array1.map{|ns16| ns16["uuid"] }
        array2.select{|ns16| !uuids1.include?(ns16["uuid"]) }
    end

    # TerminalUtils::inputParser(input, store)
    def self.inputParser(input, store) # [command or null, ns16 or null]
        # This function take an input from the prompt and 
        # attempt to retrieve a command and optionaly an object (from the store)
        # Note that the command can also be null if a command could not be extrated

        outputForCommandAndOrdinal = lambda {|command, ordinal, store|
            ordinal = ordinal.to_i
            ns16 = store.get(ordinal)
            if ns16 then
                return [command, ns16]
            else
                return [nil, nil]
            end
        }

        if Interpreting::match("[]", input) then
            return ["[]", nil]
        end

        if Interpreting::match("..", input) then
            return ["..", store.getDefault()]
        end

        if Interpreting::match(".. *", input) then
            _, ordinal = Interpreting::tokenizer(input)
            return outputForCommandAndOrdinal.call("..", ordinal, store)
        end

        if Interpreting::match(">project", input) then
            return [">project", store.getDefault()]
        end

        if Interpreting::match(">todo", input) then
            return [">todo", store.getDefault()]
        end

        if Interpreting::match(">pile", input) then
            return [">pile", store.getDefault()]
        end

        if Interpreting::match(">nyx", input) then
            return [">nyx", store.getDefault()]
        end

        if Interpreting::match("access", input) then
            return ["access", store.getDefault()]
        end

        if Interpreting::match("access *", input) then
            _, ordinal = Interpreting::tokenizer(input)
            return outputForCommandAndOrdinal.call("access", ordinal, store)
        end

        if Interpreting::match("anniversary", input) then
            return ["anniversary", nil]
        end

        if Interpreting::match("anniversaries", input) then
            return ["anniversaries", nil]
        end

        if Interpreting::match("calendar item", input) then
            return ["calendar item", nil]
        end

        if Interpreting::match("calendar", input) then
            return ["calendar", nil]
        end

        if Interpreting::match("done", input) then
            return ["done", store.getDefault()]
        end

        if Interpreting::match("done *", input) then
            _, ordinal = Interpreting::tokenizer(input)
            return outputForCommandAndOrdinal.call("done", ordinal, store)
        end

        if Interpreting::match("exit", input) then
            exit
        end

        if Interpreting::match("expose", input) then
            return ["expose", store.getDefault()]
        end

        if Interpreting::match("expose *", input) then
            _, ordinal = Interpreting::tokenizer(input)
            return outputForCommandAndOrdinal.call("expose", ordinal, store)
        end

        if Interpreting::match("project", input) then
            return ["project", nil]
        end

        if input.start_with?("project:") then
            message = input[5, input.length].strip
            item = TxProjects::interactivelyCreateNewOrNull(message)
            puts JSON.pretty_generate(item)
            return [nil, nil]
        end

        if Interpreting::match("rstream", input) then
            return ["rstream", nil]
        end

       if Interpreting::match("projects", input) then
            return ["projects", nil]
        end

        if Interpreting::match("float", input) then
            return ["float", nil]
        end

        if Interpreting::match("help", input) then
            puts [
                    "      " + Commands::terminalDisplayCommand(),
                    "      " + Commands::makersCommands(),
                    "      " + Commands::diversCommands(),
                    "      internet on | internet off | require internet",
                    "      universe",
                    "      work: off today"
                 ].join("\n").yellow
            LucilleCore::pressEnterToContinue()
            return [nil, nil]
        end

        if Interpreting::match("inbox", input) then
            return ["inbox", nil]
        end

        if Interpreting::match("internet off", input) then
            return ["internet off", nil]
        end

        if Interpreting::match("internet on", input) then
            return ["internet on", nil]
        end

        if Interpreting::match("landing", input) then
            return ["landing", store.getDefault()]
        end

        if Interpreting::match("landing *", input) then
            _, ordinal = Interpreting::tokenizer(input)
            return outputForCommandAndOrdinal.call("landing", ordinal, store)
        end

        if Interpreting::match("nyx", input) then
            return ["nyx", nil]
        end

        if Interpreting::match("ondate", input) then
            return ["ondate", nil]
        end

        if input.start_with?("ondate:") then
            message = input[7, input.length].strip
            item = TxDateds::interactivelyCreateNewOrNull(message)
            puts JSON.pretty_generate(item)
            return [nil, nil]
        end

        if Interpreting::match("ondates", input) then
            return ["ondates", nil]
        end

        if Interpreting::match("pause", input) then
            return ["pause", store.getDefault()]
        end

        if Interpreting::match("pause *", input) then
            _, ordinal = Interpreting::tokenizer(input)
            return outputForCommandAndOrdinal.call("pause", ordinal, store)
        end

        if Interpreting::match("pursue", input) then
            return ["pursue", store.getDefault()]
        end

        if Interpreting::match("pursue *", input) then
            _, ordinal = Interpreting::tokenizer(input)
            return outputForCommandAndOrdinal.call("pursue", ordinal, store)
        end

        if Interpreting::match("redate", input) then
            return ["redate", store.getDefault()]
        end

        if Interpreting::match("redate *", input) then
            _, ordinal = Interpreting::tokenizer(input)
            return outputForCommandAndOrdinal.call("redate", ordinal, store)
        end

        if Interpreting::match("require internet", input) then
            return ["require internet", store.getDefault()]
        end

        if Interpreting::match("start something", input) then
            return ["start something", nil]
        end

        if Interpreting::match("search", input) then
            return ["search", store.getDefault()]
        end

        if Interpreting::match("start", input) then
            return ["start", store.getDefault()]
        end

        if Interpreting::match("start *", input) then
            _, ordinal = Interpreting::tokenizer(input)
            return outputForCommandAndOrdinal.call("start", ordinal, store)
        end

        if Interpreting::match("stop", input) then
            return ["stop", store.getDefault()]
        end

        if Interpreting::match("stop *", input) then
            _, ordinal = Interpreting::tokenizer(input)
            return outputForCommandAndOrdinal.call("stop", ordinal, store)
        end

        if Interpreting::match("top", input) then
            return ["top", nil]
        end

        if Interpreting::match("today", input) then
            return ["today", nil]
        end

        if Interpreting::match("time * *", input) then
            _, ordinal, timenHours = Interpreting::tokenizer(input)
            ns16 = store.get(ordinal.to_i)
            return if ns16.nil?
            object = {
                "mikuType"    => "TimeInstructionAdd",
                "ns16"        => ns16,
                "timeInHours" => timenHours.to_f
            }
            return ["time", object]
        end

        if input.start_with?("today:") then
            message = input[6, input.length].strip
            item = TxDateds::interactivelyCreateNewTodayOrNull(message)
            puts JSON.pretty_generate(item)
            return [nil, nil]
        end

        if Interpreting::match("todo", input) then
            return ["todo", store.getDefault()]
        end

        if input.start_with?("todo:") then
            message = input[5, input.length].strip
            item = TxTodos::interactivelyCreateNewOrNull(message)
            puts JSON.pretty_generate(item)
            return [nil, nil]
        end

        if Interpreting::match("todos", input) then
            return ["todos", nil]
        end

        if Interpreting::match("transmute", input) then
            return ["transmute", store.getDefault()]
        end

        if Interpreting::match("transmute *", input) then
            _, ordinal = Interpreting::tokenizer(input)
            return outputForCommandAndOrdinal.call("transmute", ordinal, store)
        end

        if Interpreting::match("universe", input) then
            if NxBallsService::somethingIsRunning() then
                puts "Operation not permitted while something is running"
                LucilleCore::pressEnterToContinue()
                return
            end
            UniverseStorage::interactivelySetUniverse()
            return [nil, nil]
        end

        if Interpreting::match("wave", input) then
            return ["wave", nil]
        end

        if Interpreting::match("work: off today", input) then
            XCache::set("multiverse-monitor-mode-1b16115590a1:#{CommonUtils::today()}", "work-off")
            return [nil, nil]
        end

        [nil, nil]
    end
end

class Commands

    # Commands::terminalDisplayCommand()
    def self.terminalDisplayCommand()
        "<datecode> | <n> | .. (<n>) | expose (<n>) | transmute (<n>) | start (<n>) | search | nyx | >nyx"
    end

    # Commands::makersCommands()
    def self.makersCommands()
        "wave | anniversary | calendar item | float | project | project: <line> | today | ondate | ondate: <line> | todo | todo: <line>"
    end

    # Commands::diversCommands()
    def self.diversCommands()
        "waves | anniversaries | calendar | projects | ondates | todos"
    end
end

class NS16s

    # NS16s::rstreamToken()
    def self.rstreamToken()
        uuid = "1ee2805a-f8ee-4a73-a92a-c76d9d45359a" # uuid also used in TxTodos
        {
            "uuid"     => uuid,
            "mikuType" => "ADE4F121",
            "announce" => "(rstream)",
            "lambda"   => lambda { TxTodos::rstream() },
            "rt"       => BankExtended::stdRecoveredDailyTimeInHours(uuid)
        }
    end

    # NS16s::ns16s(universe)
    def self.ns16s(universe)
        [
            Anniversaries::ns16s(),
            JSON.parse(`/Users/pascal/Galaxy/LucilleOS/Binaries/fitness ns16s`),
            TxDateds::ns16s(),
            Waves::ns16s(universe),
            TxProjects::ns16s(universe),
            Inbox::ns16s(),
            [NS16s::rstreamToken()],
            TxTodos::ns16s(universe),
        ]
            .flatten
            .select{|item| DoNotShowUntil::isVisible(item["uuid"]) }
            .select{|ns16| InternetStatus::ns16ShouldShow(ns16["uuid"]) }
    end
end

class TerminalDisplayOperator

    # TerminalDisplayOperator::printListing(universe, floats, section2, section3)
    def self.printListing(universe, floats, section2, section3)
        system("clear")

        vspaceleft = CommonUtils::screenHeight()-3

        reference = The99Percent::getReference()
        current   = The99Percent::getCurrentCount()
        ratio     = current.to_f/reference["count"]
        puts ""
        puts "(#{universe}) 👩‍💻 🔥 #{current}, #{ratio}, #{reference["datetime"]}"
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

        running = XCacheSets::values("a69583a5-8a13-46d9-a965-86f95feb6f68")
        running = running.select{|nxball| !section2.map{|item| item["uuid"] }.include?(nxball["uuid"]) }
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
                        line = "#{store.prefixString()} #{nxball["description"]} (#{NxBallsService::activityStringOrEmptyString("", nxball["uuid"], "")})"
                        puts line
                        vspaceleft = vspaceleft - CommonUtils::verticalSize(line)
                    }
        end

        top = Topping::getText(universe)
        if top and top.strip.size > 0 then
            puts ""
            puts "(top)"
            top = top.lines.first(10).join().strip
            puts top
            vspaceleft = vspaceleft - CommonUtils::verticalSize(top) - 3
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

        if section3.size > 0 then
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
            XCache::set("a0e861a0-bb18-48fc-962d-e9d3367b7801:#{CommonUtils::today()}:#{item["uuid"]}", Time.new.to_f)
            return
        end

        command, objectOpt = TerminalUtils::inputParser(input, store)
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

            pileFilepath = "/Users/pascal/Desktop/>pile"
            if File.exists?(pileFilepath) then
                LucilleCore::locationsAtFolder(pileFilepath)
                    .each{|location|
                        name1 = File.basename(location)
                        safename = CommonUtils::sanitiseStringForFilenaming(name1)
                        if safename != name1 then
                            location2 = "#{File.dirname(location)}/#{safename}"
                            FileUtils.mv(location, location2)
                            location = location2
                        end
                        puts "Issuing todo item from pile: #{File.basename(location)}"
                        item = TxTodos::issuePile(location)
                        puts JSON.pretty_generate(item)
                        LucilleCore::removeFileSystemLocation(location)
                    }
            end

            UniverseMonitor::switchProcessor()

            universe = UniverseStorage::getUniverseOrNull()

            floats = TxFloats::ns16s(universe)
                        .select{|item| DoNotShowUntil::isVisible(item["uuid"]) }
                        .select{|ns16| InternetStatus::ns16ShouldShow(ns16["uuid"]) }

            section2 = NS16s::ns16s(universe)

            getOrderingValue = lambda {|uuid|
                value = XCache::getOrNull("a0e861a0-bb18-48fc-962d-e9d3367b7801:#{CommonUtils::today()}:#{uuid}")
                return value.to_f if value
                sleep 0.01
                value = Time.new.to_f
                XCache::set("a0e861a0-bb18-48fc-962d-e9d3367b7801:#{CommonUtils::today()}:#{uuid}", value)
                value
            }

            section2 = section2.sort{|n1, n2| getOrderingValue.call(n1["uuid"]) <=> getOrderingValue.call(n2["uuid"]) }

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
