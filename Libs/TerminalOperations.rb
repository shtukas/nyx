# encoding: UTF-8

class ItemStore

    def initialize() # : Integer
        @items = []
        @defaultItem = nil
        @topIsActive = false
    end

    def setTopActive()
        @topIsActive =  true
    end

    def register(item)
        cursor = @items.size
        @items << item
        if !@topIsActive and @defaultItem.nil? and item["NS198"] != "NS16:TxFloat" then
            @defaultItem = item
        end
    end

    def latestEnteredItemIsDefault()
        return false if @defaultItem.nil?
        @items.last["uuid"] == @defaultItem["uuid"]
    end

    def prefixString()
        indx = @items.size-1
        latestEnteredItemIsDefault() ? "(-->)".green : "(#{"%3d" % indx})"
    end

    def get(indx)
        @items[indx].clone
    end

    def getDefault()
        @defaultItem.clone
    end
end

class NS16sOperator

    # NS16sOperator::ns16s()
    def self.ns16s()
        [
            Anniversaries::ns16s(),
            Calendar::ns16s(),
            JSON.parse(`/Users/pascal/Galaxy/LucilleOS/Binaries/amanda-bins`),
            JSON.parse(`/Users/pascal/Galaxy/LucilleOS/Binaries/fitness ns16s`),
            TxDateds::ns16s(),
            Waves::ns16s(),
            TxDrops::ns16s(),
            Inbox::ns16s(),
            TxTodos::ns16s()
        ]
            .flatten
            .select{|item| DoNotShowUntil::isVisible(item["uuid"]) }
            .select{|ns16| InternetStatus::ns16ShouldShow(ns16["uuid"]) }
    end
end

class PersonalAssistant

    # PersonalAssistant::key()
    def self.key()
        "b1439fa6-bf4f-9d55-401d-aa508358bbac"
    end

    # PersonalAssistant::garbageCollectSecondArray(array1, array2)
    def self.garbageCollectSecondArray(array1, array2)
        uuids1 = array1.map{|ns16| ns16["uuid"] }
        array2 = array2.select{|ns16| !uuids1.include?(ns16["uuid"]) }
        [array1, array2]
    end

    # PersonalAssistant::getSection3(ns16s)
    def self.getSection3(ns16s)
        ns16sUuids = ns16s.map{|ns16| ns16["uuid"] }
        getNS16ByUUIDOrNull = lambda{|uuid, ns16s|
            ns16s.select{|ns16| ns16["uuid"] == uuid }.first
        }
        section3 = JSON.parse(KeyValueStore::getOrDefaultValue(nil, PersonalAssistant::key(), "[]"))
                    .select{|ns16| ns16sUuids.include?(ns16["uuid"]) }
                    .map{|ns16| getNS16ByUUIDOrNull.call(ns16["uuid"], ns16s)}
                    .compact
                    .select{|item| DoNotShowUntil::isVisible(item["uuid"]) }
                    .select{|ns16| InternetStatus::ns16ShouldShow(ns16["uuid"]) }
        KeyValueStore::set(nil, PersonalAssistant::key(), JSON.generate(section3))
        PersonalAssistant::garbageCollectSecondArray(section3, ns16s)
    end

    # PersonalAssistant::maintainSection3Size(section3, ns16s)
    def self.maintainSection3Size(section3, ns16s)
        shouldBeInSection3L = lambda {|ns16|
            return true if (ns16["NS198"] == "NS16:Wave" and Waves::isPriorityWave(ns16["wave"]))
            return true if (ns16["NS198"] == "NS16:TxDrop")
            return true if (ns16["NS198"] == "NS16:TxDated")
            false
        }
        shouldBeInSection3 = ns16s.select{|ns16| shouldBeInSection3L.call(ns16)}
        if shouldBeInSection3.size > 0 then
            section3 = section3 + shouldBeInSection3
            KeyValueStore::set(nil, PersonalAssistant::key(), JSON.generate(section3))
            section3, ns16s = PersonalAssistant::garbageCollectSecondArray(section3, ns16s)
        end
        if section3.size < 10 then
            section3 = (section3 + ns16s).first(10)
            KeyValueStore::set(nil, PersonalAssistant::key(), JSON.generate(section3))
            section3, ns16s = PersonalAssistant::garbageCollectSecondArray(section3, ns16s)
        end
        [section3, ns16s]
    end

    # PersonalAssistant::rotate()
    def self.rotate()
        section3 = JSON.parse(KeyValueStore::getOrDefaultValue(nil, PersonalAssistant::key(), "[]"))
        first = section3.shift
        section3 = section3 + [first]
        KeyValueStore::set(nil, PersonalAssistant::key(), JSON.generate(section3))
    end
end

class TerminalDisplayOperator

    # TerminalDisplayOperator::commandStrWithPrefix(ns16, isDefaultItem)
    def self.commandStrWithPrefix(ns16, isDefaultItem)
        return "" if !isDefaultItem
        return "" if ns16["commands"].nil?
        return "" if ns16["commands"].empty?
        " (commands: #{ns16["commands"].join(", ")})".yellow
    end

    # TerminalDisplayOperator::display(floats, section3, section4)
    def self.display(floats, section3, section4)
        system("clear")

        vspaceleft = Utils::screenHeight()-3

        puts ""
        cardinal = TxDateds::items().size + TxTodos::items().size + TxDrops::mikus().size
        puts "(cardinal: #{cardinal} items)"
        vspaceleft = vspaceleft - 2

        puts ""

        store = ItemStore.new()

        if !InternetStatus::internetIsActive() then
            puts "INTERNET IS OFF".green
            vspaceleft = vspaceleft - 1
        end

        floats.each{|ns16|
            store.register(ns16)
            line = "#{store.prefixString()} [#{Time.at(ns16["TxFloat"]["unixtime"]).to_s[0, 10]}] #{ns16["announce"]}".yellow
            break if (!store.latestEnteredItemIsDefault() and store.getDefault() and ((vspaceleft - Utils::verticalSize(line)) < 0))
            puts line
            vspaceleft = vspaceleft - Utils::verticalSize(line)
        }
        if floats.size>0 then
            puts ""
            vspaceleft = vspaceleft - 1
        end

        running = BTreeSets::values(nil, "a69583a5-8a13-46d9-a965-86f95feb6f68")
        running
                .sort{|t1, t2| t1["unixtime"] <=> t2["unixtime"] } # || 0 because we had some running while updating this
                .each{|nxball|
                    delegate = {
                        "uuid"       => "84FF58F7-6607-4E32:#{nxball["uuid"]}",
                        "NxBallUUID" => nxball["uuid"],
                        "NS198"      => "NxBallDelegate1" 
                    }
                    store.register(delegate)
                    line = "#{store.prefixString()} #{nxball["description"]} (#{NxBallsService::runningStringOrEmptyString("", nxball["uuid"], "")})".green
                    puts line
                    vspaceleft = vspaceleft - Utils::verticalSize(line)
                }
        if running.size>0 then
            puts ""
            vspaceleft = vspaceleft - 1
        end

        top = Topping::getText()
        if top.size > 0 then
            store.setTopActive()
            top = top.lines.first(10).join().strip
            puts "(-->)".green
            puts top
            puts ""
            vspaceleft = vspaceleft - Utils::verticalSize(top) - 2
        end

        section3
            .each{|ns16|
                store.register(ns16)
                line = ns16["announce"]
                line = "#{store.prefixString()} #{line}#{TerminalDisplayOperator::commandStrWithPrefix(ns16, store.latestEnteredItemIsDefault())}"
                break if (vspaceleft - Utils::verticalSize(line)) < 0
                puts line
                vspaceleft = vspaceleft - Utils::verticalSize(line)
            }

        puts ""
        vspaceleft = vspaceleft - 1

        section4
            .each{|ns16|
                store.register(ns16)
                line = ns16["announce"]
                line = "#{store.prefixString()} #{line}#{TerminalDisplayOperator::commandStrWithPrefix(ns16, store.latestEnteredItemIsDefault())}"
                break if (vspaceleft - Utils::verticalSize(line)) < 0
                puts line
                vspaceleft = vspaceleft - Utils::verticalSize(line)
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

        if command == "delay" then
            i = LucilleCore::askQuestionAnswerAsString("index ? : ").to_i
            return if i == 0
            item = store.get(i)
            puts "item: #{item["announce"]}"
            unixtime = Utils::interactivelySelectUnixtimeOrNull()
            return if unixtime.nil?
            DoNotShowUntil::setUnixtime(item["uuid"], unixtime)
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

            # Every loop maintenance
            TxTodos::importTxTodosRandom()
            floats = TxFloats::ns16s()
                        .select{|item| DoNotShowUntil::isVisible(item["uuid"]) }
                        .select{|ns16| InternetStatus::ns16ShouldShow(ns16["uuid"]) }
            ns16s = NS16sOperator::ns16s()
            section3, ns16s = PersonalAssistant::getSection3(ns16s)
            section3, ns16s = PersonalAssistant::maintainSection3Size(section3, ns16s)
            TerminalDisplayOperator::display(floats, section3, [])
        }
    end
end
