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

        if Interpreting::match(">fyre", input) then
            return [">fyre", store.getDefault()]
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

        if Interpreting::match("fyre", input) then
            return ["fyre", nil]
        end

        if input.start_with?("fyre:") then
            message = input[5, input.length].strip
            item = TxFyres::interactivelyCreateNewOrNull(message)
            puts JSON.pretty_generate(item)
            return [nil, nil]
        end

        if Interpreting::match("rstream", input) then
            return ["rstream", nil]
        end

       if Interpreting::match("fyres", input) then
            return ["fyres", nil]
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
                    "      universe (set the universe of the dafault item) (<n>)  | >> (switch universe)"
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
            return ["universe", nil]
        end

        if Interpreting::match("universe *", input) then
            _, ordinal = Interpreting::tokenizer(input)
            return outputForCommandAndOrdinal.call("universe", ordinal, store)
        end

        if Interpreting::match("wave", input) then
            return ["wave", nil]
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
        "wave | anniversary | calendar item | float | fyre | today | ondate | ondate: <message> | todo | todo: <description>"
    end

    # Commands::diversCommands()
    def self.diversCommands()
        "waves | anniversaries | calendar | fyres | ondates | todos"
    end
end

class Defaultability
    
    # Defaultability::advance(uuid)
    def self.advance(uuid)
        XCache::set("4de44b69-bbcd-4d0e-9ab8-76880090cae4:#{uuid}", Time.new.to_i)
    end

    # Defaultability::isAdvanced(uuid)
    def self.isAdvanced(uuid)
        unixtime = XCache::getOrNull("4de44b69-bbcd-4d0e-9ab8-76880090cae4:#{uuid}")
        return false if unixtime.nil?
        unixtime = unixtime.to_i
        if (Time.new.to_i - unixtime) < 3600*3 then
            Defaultability::advance(uuid) # to update the timestamp
            true
        else
            false
        end
    end

    # Defaultability::isDefaultable(ns16)
    def self.isDefaultable(ns16)
        return false if ns16["nonListingDefaultable"]
        return false if Defaultability::isAdvanced(ns16["uuid"])
        true
    end
end

class NS16s

    # NS16s::ns16s(universe)
    def self.ns16s(universe)
        [
            Anniversaries::ns16s(),
            JSON.parse(`/Users/pascal/Galaxy/LucilleOS/Binaries/fitness ns16s`),
            Waves::ns16s(universe),
            TxDateds::ns16s(),
            Inbox::ns16s(),
            [UniverseMonitor::switchInvitationNS16OrNull()].compact,
            TxFyres::ns16s(universe),
            TxTodos::ns16s(universe).first(5),
            [ListingDataDriver::rstreamToken()]
        ]
            .flatten
            .select{|item| DoNotShowUntil::isVisible(item["uuid"]) }
            .select{|ns16| InternetStatus::ns16ShouldShow(ns16["uuid"]) }
    end
end

class TerminalDisplayOperator

    # TerminalDisplayOperator::printListing(universe, floats, section2)
    def self.printListing(universe, floats, section2)
        system("clear")

        vspaceleft = DidactUtils::screenHeight()-3

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
                vspaceleft = vspaceleft - DidactUtils::verticalSize(line)
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
                            "uuid"       => nxball["uuid"],
                            "mikuType"   => "NxBallNS16Delegate1" 
                        }
                        store.register(delegate, true)
                        line = "#{store.prefixString()} #{nxball["description"]} (#{NxBallsService::activityStringOrEmptyString("", nxball["uuid"], "")})"
                        puts line
                        vspaceleft = vspaceleft - DidactUtils::verticalSize(line)
                    }
        end


        top = Topping::getText(universe)
        if top and top.strip.size > 0 then
            puts ""
            puts "(top)"
            top = top.lines.first(10).join().strip
            puts top
            vspaceleft = vspaceleft - DidactUtils::verticalSize(top) - 3
        end

        if section2.size > 0 then
            puts ""
            vspaceleft = vspaceleft - 1
            section2
                .each{|ns16|
                    store.register(ns16, Defaultability::isDefaultable(ns16))
                    line = ns16["announce"]
                    line = "#{store.prefixString()} #{line}"
                    break if (vspaceleft - DidactUtils::verticalSize(line)) < 0
                    if NxBallsService::isActive(ns16["uuid"]) then
                        line = "#{line} (#{NxBallsService::activityStringOrEmptyString("", ns16["uuid"], "")})".green
                    end
                    puts line
                    vspaceleft = vspaceleft - DidactUtils::verticalSize(line)
                }
        end

        puts ""
        input = LucilleCore::askQuestionAnswerAsString("> ")

        return if input == ""

        if !input.start_with?("today:") and (unixtime = DidactUtils::codeToUnixtimeOrNull(input.gsub(" ", ""))) then
            if (item = store.getDefault()) then
                DoNotShowUntil::setUnixtime(item["uuid"], unixtime)
                return
            end
        end

        if input == ">>" then
            if (item = store.getDefault()) then
                Defaultability::advance(item["uuid"])
                return
            end
        end

        command, objectOpt = TerminalUtils::inputParser(input, store)
        #puts "parser: command:#{command}, objectOpt: #{objectOpt}"

        if objectOpt and objectOpt["lambda"] then
            objectOpt["lambda"].call()
            return
        end

        LxAction::action(command, objectOpt)
    end
end

class ListingDataDriver

    # Data = Array[NS16]

    # -------------------------------------
    # Basic IO

    # ListingDataDriver::getData()
    def self.getData()
        JSON.parse(XCache::getOrDefaultValue("cf7c57fe-c53d-407b-8a13-b70e3ce48bfb", "[]"))
    end

    # ListingDataDriver::storeData(data)
    def self.storeData(data)
        XCache::set("cf7c57fe-c53d-407b-8a13-b70e3ce48bfb", JSON.generate(data))
    end

    # -------------------------------------
    # Transforms

    # ListingDataDriver::removeDuplicates(data)
    def self.removeDuplicates(data)
        data.reduce([]){|selected, item|
            if selected.map{|i| i["uuid"] }.include?(item["uuid"]) then
                selected
            else
                selected + [ item ]
            end
        }
    end

    # ListingDataDriver::removeDeadItems(data, ns16s)
    def self.removeDeadItems(data, ns16s)
        data.select{|item| ns16s.map{|i| i["uuid"]}.include?(item["uuid"]) }
    end

    # ListingDataDriver::ensureRunningItemsAreFirst(data)
    def self.ensureRunningItemsAreFirst(data)
        running, rest = data.partition{|ns16| NxBallsService::isActive(ns16["uuid"]) }
        running + rest
    end

    # ListingDataDriver::rstreamToken()
    def self.rstreamToken()
        {
            "uuid" => "1ee2805a-f8ee-4a73-a92a-c76d9d45359a",
            "mikuType" => "ADE4F121",
            "announce" => "(rstream)",
            "lambda" => lambda { TxTodos::rstream() }
        }
    end

    # -------------------------------------
    # Update

    # ListingDataDriver::update(universe)
    def self.update(universe)
        data = ListingDataDriver::getData()
        ns16s = NS16s::ns16s(universe)

        # We remove any item that has been deleted
        while (uuid = Mercury::dequeueFirstValueOrNull("2d70b692-49f0-4a11-85a9-c378537f8ef1")) do
            data = data.select{|item| item["uuid"] != uuid}
        end

        # We remove any item that has gone the done message
        while (uuid = Mercury::dequeueFirstValueOrNull("b6156390-059d-446e-ad51-adfc9f91abf1")) do
            data = data.select{|item| item["uuid"] != uuid}
        end

        # We make sure that we have any new item
        data = ListingDataDriver::removeDuplicates(data + ns16s)

        # We remove the items that are alive but no longer occur in ns16s
        data = ListingDataDriver::removeDeadItems(data, ns16s)

        # Ensure that priority waves come first
        section2prioritySelect = lambda {|ns16|
            return true if (ns16["mikuType"] == "NS16:Wave" and ns16["isPriority"])
            false
        }
        p1, p2 = data.partition{|ns16| NxBallsService::isActive(ns16["uuid"]) }
        data = p1 + p2

        # Ensure that overflowing, non running, todos and fyres are last
        selectOverflowingOrDoneForTodayTodosAndFyres = lambda {|ns16|
            return false if NxBallsService::isActive(ns16["uuid"])
            return false if !["NS16:TxFyre", "NS16:TxTodo"].include?(ns16["mikuType"])
            return true if XCache::flagIsTrue("905b-09a30622d2b9:FyreIsDoneForToday:#{DidactUtils::today()}:#{ns16["uuid"]}")
            BankExtended::stdRecoveredDailyTimeInHours(ns16["uuid"]) >= 1
        }

        overflowing, p0 = data.partition{|ns16| selectOverflowingOrDoneForTodayTodosAndFyres.call(ns16) }
        data = p0 + overflowing.sort{|i1, i2| i1["rt"] <=> i2["rt"] }

        # Ensure that running items come first
        data = ListingDataDriver::ensureRunningItemsAreFirst(data)

        ListingDataDriver::storeData(data)
    end
end

class Catalyst

    # Catalyst::program2()
    def self.program2()
        initialCodeTrace = DidactUtils::generalCodeTrace()
        loop {

            if DidactUtils::generalCodeTrace() != initialCodeTrace then
                puts "Code change detected"
                break
            end

            universe = ActiveUniverse::getUniverseOrNull()

            pileFilepath = "/Users/pascal/Desktop/>pile"
            if File.exists?(pileFilepath) then
                LucilleCore::locationsAtFolder(pileFilepath)
                    .each{|location|
                        name1 = File.basename(location)
                        safename = DidactUtils::sanitiseStringForFilenaming(name1)
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

            floats = TxFloats::ns16s(universe)
                        .select{|item| DoNotShowUntil::isVisible(item["uuid"]) }
                        .select{|ns16| InternetStatus::ns16ShouldShow(ns16["uuid"]) }

            ListingDataDriver::update(universe)

            section2 = ListingDataDriver::getData()

            TerminalDisplayOperator::printListing(universe, floats, section2)
        }
    end
end