# encoding: UTF-8

# ------------------------------------------------------------------------------------------

class Fitness
    # Fitness::ns16s()
    def self.ns16s()
        ns16s = JSON.parse(`/Users/pascal/Galaxy/LucilleOS/Binaries/fitness ns16s`)
        ns16s.map{|ns16|
            ns16["commands"] = [".."]
            ns16["interpreter"] = lambda {|command|
                if command == ".." then
                    system("/Users/pascal/Galaxy/LucilleOS/Binaries/fitness doing #{ns16["domain"]}") 
                end
            }
            ns16["run"] = lambda {
                system("/Users/pascal/Galaxy/LucilleOS/Binaries/fitness doing #{ns16["domain"]}") 
            }
            ns16
        }
    end
end

class PriorityFiles

    # PriorityFiles::applyNextTransformation(filepath)
    def self.applyNextTransformation(filepath)
        contents = IO.read(filepath)
        return if contents.strip == ""
        contents = SectionsType0141::applyNextTransformationToText(contents)
        File.open(filepath, "w"){|f| f.puts(contents)}
    end

    # PriorityFiles::filepathToBankAccount(filepath)
    def self.filepathToBankAccount(filepath)
        map = {
            "/Users/pascal/Desktop/Eva.txt"  => "Nx50s-14F461E4-9387-4078-9C3A-45AE08205CA7",
            "/Users/pascal/Desktop/Work.txt" => Work::bankaccount()
        }
        raise "9f7add46-eda3-4cfc-92b8-aa057a9e790e: filepath: #{filepath}" if map[filepath].nil?
        map[filepath]
    end

    # PriorityFiles::run(filepath)
    def self.run(filepath)

        nxball = NxBalls::makeNxBall([PriorityFiles::filepathToBankAccount(filepath)])

        thr = Thread.new {
            loop {
                sleep 60

                if (Time.new.to_i - nxball["cursorUnixtime"]) >= 600 then
                    nxball = NxBalls::upgradeNxBall(nxball, false)
                end

                if (Time.new.to_i - nxball["startUnixtime"]) >= 3600 then
                    Utils::onScreenNotification("Catalyst", "Priority file running for more than an hour")
                end
            }
        }

        loop {
            
            system("clear")

            text = IO.read(filepath).strip
            puts ""
            text = text.lines.first(10).join().strip
            puts text.green
            puts ""
            puts "[] | exit (default)".yellow
            command = LucilleCore::askQuestionAnswerAsString("> ")

            if command == "" then
                break
            end

            if command == "exit" then
                break
            end

            if Interpreting::match("[]", command) then
                PriorityFiles::applyNextTransformation(filepath)
                next
            end
        }

        thr.exit

        NxBalls::closeNxBall(nxball, true)
    end

    # PriorityFiles::filepathToNS16(filepath)
    def self.filepathToNS16(filepath)
        {
            "uuid"        => "25533ad6-50ff-463c-908f-ba3ba8858b7e:#{filepath}",
            "announce"    => "[prio] #{File.basename(filepath)}".green,
            "commands"    => [".."],
            "interpreter" => lambda{|command|
                if command == ".." then
                    PriorityFiles::run(filepath)
                end
            },
            "run" => lambda {
                PriorityFiles::run(filepath)
            }
        }
    end

    # PriorityFiles::ns16s()
    def self.ns16s()
        [
            "/Users/pascal/Desktop/Eva.txt",
            "/Users/pascal/Desktop/Work.txt"
        ]
        .select{|filepath|
            IO.read(filepath).strip.size > 0
        }
        .map{|filepath|
            PriorityFiles::filepathToNS16(filepath)
        }
    end
end

class NS16sOperator
    # NS16sOperator::ns16s()
    def self.ns16s()
        [
            DetachedRunning::ns16s(),
            Anniversaries::ns16s(),
            Calendar::ns16s(),
            NxOnDate::ns16s(),
            Fitness::ns16s(),
            Waves::ns16s(),
            DrivesBackups::ns16s(),
            PriorityFiles::ns16s(),
            Nx51s::ns16s(),
            Nx50s::ns16s()
        ]
            .flatten
            .compact
            .select{|item| DoNotShowUntil::isVisible(item["uuid"]) }
            .select{|ns16| InternetStatus::ns16ShouldShow(ns16["uuid"]) }
    end
end

class ItemStore
    def initialize() # : Integer
        @items = []
        @defaultItem = nil
    end
    def register(item)
        cursor = @items.size
        @items << item
        cursor 
    end
    def registerDefault(item)
        @defaultItem = item
    end
    def get(indx)
        @items[indx].clone
    end
    def getDefault()
        @defaultItem.clone
    end
end

class InternetStatus

    # InternetStatus::setInternetOn()
    def self.setInternetOn()
        KeyValueStore::destroy(nil, "099dc001-c211-4e37-b631-8f3cf7ef6f2d")
    end

    # InternetStatus::setInternetOff()
    def self.setInternetOff()
        KeyValueStore::set(nil, "099dc001-c211-4e37-b631-8f3cf7ef6f2d", "off")
    end

    # InternetStatus::internetIsActive()
    def self.internetIsActive()
        KeyValueStore::getOrNull(nil, "099dc001-c211-4e37-b631-8f3cf7ef6f2d").nil?
    end

    # InternetStatus::markIdAsRequiringInternet(id)
    def self.markIdAsRequiringInternet(id)
        KeyValueStore::set(nil, "29f7d6a5-91ed-4623-9f52-543684881f33:#{id}", "require")
    end

    # InternetStatus::trueIfElementRequiresInternet(id)
    def self.trueIfElementRequiresInternet(id)
        KeyValueStore::getOrNull(nil, "29f7d6a5-91ed-4623-9f52-543684881f33:#{id}") == "require"
    end

    # InternetStatus::ns16ShouldShow(id)
    def self.ns16ShouldShow(id)
        InternetStatus::internetIsActive() or !InternetStatus::trueIfElementRequiresInternet(id)
    end

    # InternetStatus::putsInternetCommands()
    def self.putsInternetCommands()
        "[internt] set internet on | set internet off | requires internet"
    end

    # InternetStatus::interpreter(command, store)
    def self.interpreter(command, store)

        if Interpreting::match("set internet on", command) then
            InternetStatus::setInternetOn()
        end

        if Interpreting::match("set internet off", command) then
            InternetStatus::setInternetOff()
        end

        if Interpreting::match("requires internet", command) then
            ns16 = store.getDefault()
            return if ns16.nil?
            InternetStatus::markIdAsRequiringInternet(ns16["uuid"])
        end
    end
end

class UIServices

    # UIServices::mainView(ns16s)
    def self.mainView(ns16s)
        system("clear")

        store = ItemStore.new()

        vspaceleft = Utils::screenHeight()-10

        commandLines = [
            "[info   ]",
            "(ondates: rt: #{BankExtended::stdRecoveredDailyTimeInHours("ONDATES-BE92-5874-85F2-64F140E3B243").round(2)})",
            "(waves: rt: #{BankExtended::stdRecoveredDailyTimeInHours("WAVES-A81E-4726-9F17-B71CAD66D793").round(2)}, cb: #{(100*Beatrice::stdRecoveredHourlyTimeInHours("WAVES-A81E-4726-9F17-B71CAD66D793").to_f/Waves::targetHourlyTimeInHours()).round(2)} %)",
            "(Nx51s: rt: #{BankExtended::stdRecoveredDailyTimeInHours(Work::bankaccount()).round(2)}, cb: #{ (100*BankExtended::stdRecoveredDailyTimeInHours(Work::bankaccount()).to_f/Work::targetDailyRecoveryTimeInHours()).round(2) } %)",
            "(Nx50s: rt: #{BankExtended::stdRecoveredDailyTimeInHours("Nx50s-14F461E4-9387-4078-9C3A-45AE08205CA7").round(2)} ; #{Nx50s::nx50s().size} items)",
        ].join(" ").yellow

        vspaceleft = vspaceleft - Utils::verticalSize(commandLines)

        if !InternetStatus::internetIsActive() then
            puts ""
            puts "INTERNET IS OFF".green
            vspaceleft = vspaceleft - 2
        end

        nxfloats = NxFloats::nxfloats()
        if nxfloats.size > 0 then
            puts ""
            nxfloats
            .map{|float|
                float["run"] = lambda { NxFloats::run(float)}
                float
            }
            .each{|nxfloat|
                line = "(#{store.register(nxfloat).to_s.rjust(3, " ")}) #{NxFloats::toString(nxfloat).gsub("float", "floa").yellow}"
                puts line
                vspaceleft = vspaceleft - Utils::verticalSize(line)
            }
            vspaceleft = vspaceleft - 1
        end

        commandStrWithPrefix = lambda{|ns16, isDefaultItem|
            return "" if !isDefaultItem
            return "" if ns16["commands"].nil?
            return "" if ns16["commands"].empty?
            " (commands: #{ns16["commands"].join(", ")})".yellow
        }

        puts ""

        if ns16s.size > 0 then
            store.registerDefault(ns16s[0])
        end

        ns16s
            .each_with_index{|ns16|
                indx = store.register(ns16)
                isDefaultItem = ns16["uuid"] == (store.getDefault() ? store.getDefault()["uuid"] : "")
                posStr = "(#{"%3d" % indx})"
                announce = "#{posStr} #{ns16["announce"]}#{commandStrWithPrefix.call(ns16, isDefaultItem)}"
                break if ((indx > 0) and ((vspaceleft - Utils::verticalSize(announce)) < 0))
                puts announce
                vspaceleft = vspaceleft - Utils::verticalSize(announce)
            }

        puts ""

        puts Interpreters::listingCommands().yellow
        puts Interpreters::mainMenuCommands().yellow
        puts Work::workMenuCommands().yellow
        puts InternetStatus::putsInternetCommands().yellow

        puts ""

        puts commandLines

        puts ""

        command = LucilleCore::askQuestionAnswerAsString("> ")

        return if command == ""

        # We first interpret the command as an index and call "run"
        # Or interpret it a command and run it by the default element interpreter.
        # Otherwise we try a bunch of generic interpreters.

        if command == ".." and store.getDefault() then
            store.getDefault()["run"].call()
            return
        end

        if (i = Interpreting::readAsIntegerOrNull(command)) then
            item = store.get(i)
            return if item.nil?
            item["run"].call()
            return
        end

        Interpreters::listingInterpreter(store, command, priorityFileHash)
        Interpreters::mainMenuInterpreter(command)
        Work::workMenuInterpreter(command)
        InternetStatus::interpreter(command, store)

        if store.getDefault() then
            item = store.getDefault()
            if item["interpreter"] then
                item["interpreter"].call(command)
            end
        end
    end
end
