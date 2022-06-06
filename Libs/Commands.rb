
# encoding: UTF-8

class Commands

    # Commands::terminalDisplayCommand()
    def self.terminalDisplayCommand()
        "<datecode> | <n> | .. (<n>) | expose (<n>) | transmute (<n>) | start (<n>) | search | nyx | >nyx | streaming"
    end

    # Commands::makersCommands()
    def self.makersCommands()
        "wave | anniversary | calendar item | float | project | project: <line> | today | ondate | ondate: <line> | todo | todo: <line>"
    end

    # Commands::diversCommands()
    def self.diversCommands()
        "waves | anniversaries | calendar | projects | ondates | todos | slots"
    end

    # Commands::inputParser(input, store)
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

        if Interpreting::match("..", input) then
            return ["..", store.getDefault()]
        end

        if Interpreting::match(".. *", input) then
            _, ordinal = Interpreting::tokenizer(input)
            return outputForCommandAndOrdinal.call("..", ordinal, store)
        end

        if Interpreting::match(">>", input) then
            system("clear")
            Streaming::stream(Streaming::items())
            return [nil, nil]
        end

        if Interpreting::match(">project", input) then
            return [">project", store.getDefault()]
        end

        if Interpreting::match(">todo", input) then
            return [">todo", store.getDefault()]
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

        if Interpreting::match("slots", input) then
            Slots::editSlots()
            return [nil, nil]
        end

        if Interpreting::match("stop *", input) then
            _, ordinal = Interpreting::tokenizer(input)
            return outputForCommandAndOrdinal.call("stop", ordinal, store)
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
            UniverseStored::interactivelySetUniverse()
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
