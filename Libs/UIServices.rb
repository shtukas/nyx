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

class NS16sOperator
    # NS16sOperator::ns16s()
    def self.ns16s()
        domain = Domains::getCurrentActiveDomain()
        [
            DetachedRunning::ns16s(),
            Anniversaries::ns16s(),
            Calendar::ns16s(),
            NxOnDate::ns16s(),
            Fitness::ns16s(),
            Waves::ns16s(),
            DrivesBackups::ns16s(),
            DomainPriorityFile::ns16s(),
            Nx50s::ns16s()
        ]
            .flatten
            .compact
            .select{|ns16|
                ns16["domain"].nil? or (ns16["domain"] == domain)
            }
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

        infoLines1 = [
            "[info   ]",
            "(ondates: rt: #{BankExtended::stdRecoveredDailyTimeInHours("ONDATES-BE92-5874-85F2-64F140E3B243").round(2)})",
            "(waves: rt: #{BankExtended::stdRecoveredDailyTimeInHours("WAVES-A81E-4726-9F17-B71CAD66D793").round(2)})",
            "(Nx50s: rt: #{BankExtended::stdRecoveredDailyTimeInHours("Nx50s-14F461E4-9387-4078-9C3A-45AE08205CA7").round(2)} ; #{Nx50s::nx50s().size} items)",
            "(eva: rt: #{BankExtended::stdRecoveredDailyTimeInHours("EVA-60ACA3A8-E1DB-4029-BE95-5ACBFF10316D").round(2)})",
            "(work: rt: #{BankExtended::stdRecoveredDailyTimeInHours(Work::bankaccount()).round(2)})",
        ].join(" ").yellow

        vspaceleft = vspaceleft - Utils::verticalSize(infoLines1)

        puts ""
        puts "Domain: #{Domains::getCurrentActiveDomain().upcase}".green
        vspaceleft = vspaceleft - 2


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

        puts infoLines1

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

        Interpreters::listingInterpreter(store, command)
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
