# encoding: UTF-8

# ------------------------------------------------------------------------------------------

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

class Commands

    # Commands::terminalDisplayCommand()
    def self.terminalDisplayCommand()
        ".. | <n> | <datecode> | expose"
    end

    # Commands::makersCommands()
    def self.makersCommands()
        "wave | anniversary | monitor | today | ondate | todo"
    end

    # Commands::diversCommands()
    def self.diversCommands()
        "calendar | waves | anniversaries | ondates | todos | work on | work off | search | nyx"
    end

    # Commands::makersAndDiversCommands()
    def self.makersAndDiversCommands()
        [
            Commands::makersCommands(),
            Commands::diversCommands()
        ].join(" | ")
    end
end

class NS16sOperator

    # NS16sOperator::isWorkTime()
    def self.isWorkTime()
        instruction = KeyValueStore::getOrNull(nil, "dcef329c-a1eb-4fc5-b151-e94460fe280c")
        if instruction then
            instruction = JSON.parse(instruction)
            if Time.new.to_i < instruction["expiryTime"] then
                return true  if instruction["mode"] == "work-on"
                return false if instruction["mode"] == "work-off"
            end
        end
        return false if (Time.new.wday == 6 or Time.new.wday == 0)
        return false if Time.new.hour < 8
        return false if Time.new.hour >= 17
        true
    end

    # NS16sOperator::ns16s()
    def self.ns16s()
        [
            Anniversaries::ns16s(),
            Calendar::ns16s(),
            JSON.parse(`/Users/pascal/Galaxy/LucilleOS/Binaries/amanda-bin-monitor`),
            JSON.parse(`/Users/pascal/Galaxy/LucilleOS/Binaries/fitness ns16s`),
            Waves::ns16s(),
            Inbox::ns16s(),
            Mx49s::ns16s(),
            Mx51s::ns16s(),
            Nx50s::ns16s()
        ]
            .flatten
            .compact
            .select{|item| DoNotShowUntil::isVisible(item["uuid"]) }
            .select{|ns16| InternetStatus::ns16ShouldShow(ns16["uuid"]) }
    end
end

class TerminalDisplayOperator

    # TerminalDisplayOperator::display(monitor2, ns16s)
    def self.display(monitor2, ns16s)

        commandStrWithPrefix = lambda{|ns16, isDefaultItem|
            return "" if !isDefaultItem
            return "" if ns16["commands"].nil?
            return "" if ns16["commands"].empty?
            " (commands: #{ns16["commands"].join(", ")})".yellow
        }

        system("clear")

        vspaceleft = Utils::screenHeight()-4

        puts ""
        puts "(today: #{(Bank::valueAtDate("GLOBAL-4852-9FCE-C8D43B85A4AC", Utils::today()).to_f/3600).round(2)} hours, rt: #{BankExtended::stdRecoveredDailyTimeInHours("GLOBAL-4852-9FCE-C8D43B85A4AC").round(2)}, Nx50: #{Nx50s::nx50s().size} items)"
        vspaceleft = vspaceleft - 2

        puts ""

        store = ItemStore.new()

        if !InternetStatus::internetIsActive() then
            puts "INTERNET IS OFF".green
            vspaceleft = vspaceleft - 1
        end

        monitor2.each{|ns16|
            line = "(#{store.register(ns16).to_s.rjust(3, " ")}) [#{Time.at(ns16["Mx48"]["unixtime"]).to_s[0, 10]}] #{ns16["announce"]}".yellow
            puts line
            vspaceleft = vspaceleft - Utils::verticalSize(line)
        }

        running = BTreeSets::values(nil, "a69583a5-8a13-46d9-a965-86f95feb6f68")
        running
                .sort{|t1, t2| t1["unixtime"] <=> t2["unixtime"] } # || 0 because we had some running while updating this
                .each{|nxball|
                    delegate = {
                        "uuid"  => nxball["uuid"],
                        "NS198" => "NxBallDelegate1" 
                    }
                    indx = store.register(delegate)
                    announce = "(#{"%3d" % indx}) #{nxball["description"]} (#{NxBallsService::runningStringOrEmptyString("", nxball["uuid"], "")})".green
                    puts announce
                    vspaceleft = vspaceleft - Utils::verticalSize(announce)
                }
        runningUUIDs = running.map{|item| item["uuid"] }

        catalyst = IO.read("/Users/pascal/Desktop/Catalyst.txt").strip
        if catalyst.size > 0 then
            puts "Catalyst.txt is not empty".green
            vspaceleft = vspaceleft - 1
        end

        ns16s
            .each{|ns16|
                indx = store.register(ns16)
                isDefaultable = !KeyValueStore::flagIsTrue(nil, "NOT-DEFAULTABLE-4B2B-9856-95F8C25828FD:#{Utils::today()}:#{ns16["uuid"]}")
                isDefaultItem = (isDefaultable and store.getDefault().nil?) # the default item is the first element, unless it's not defaultable
                if isDefaultItem then
                    store.registerDefault(ns16)
                end
                announce = ns16["announce"]
                if !isDefaultItem and store.getDefault().nil? then
                    announce = announce.yellow
                end
                posStr = isDefaultItem ? "(-->)".green : "(#{"%3d" % indx})"
                announce = "#{posStr} #{announce}#{commandStrWithPrefix.call(ns16, isDefaultItem)}"
                if runningUUIDs.include?(ns16["uuid"]) then
                    announce = announce.green
                end
                break if (!isDefaultItem and store.getDefault() and ((vspaceleft - Utils::verticalSize(announce)) < 0))
                puts announce
                vspaceleft = vspaceleft - Utils::verticalSize(announce)
            }

        puts ""

        command = LucilleCore::askQuestionAnswerAsString("> ")

        return if command == ""

        if (unixtime = Utils::codeToUnixtimeOrNull(command.gsub(" ", ""))) then
            if (item = store.getDefault()) then
                DoNotShowUntil::setUnixtime(item["uuid"], unixtime)
                return
            end
        end

        if (i = Interpreting::readAsIntegerOrNull(command)) then
            item = store.get(i)
            return if item.nil?
            CommandsOps::operator1(item, "..")
            return
        end

        if command == "expose" and (item = store.getDefault()) then
            puts JSON.pretty_generate(item)
            LucilleCore::pressEnterToContinue()
            return
        end

        if command == "''" and (item = store.getDefault()) then
            KeyValueStore::setFlagTrue(nil, "NOT-DEFAULTABLE-4B2B-9856-95F8C25828FD:#{Utils::today()}:#{item["uuid"]}")
            return
        end

        CommandsOps::operator4(command)
        CommandsOps::operator1(store.getDefault(), command)
    end

    # TerminalDisplayOperator::displayLoop()
    def self.displayLoop()
        initialCodeTrace = Utils::codeTrace()
        loop {
            if Utils::codeTrace() != initialCodeTrace then
                puts "Code change detected"
                break
            end
            monitor = Mx48s::ns16s()
            ns16s = NS16sOperator::ns16s()
            TerminalDisplayOperator::display(monitor, ns16s)
        }
    end
end
