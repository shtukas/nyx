# encoding: UTF-8

class ItemStore

    def initialize() # : Integer
        @items = []
        @defaultItem = nil
    end

    def register(item, canBeDefault)
        cursor = @items.size
        @items << item
        if @defaultItem.nil? and canBeDefault then
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

    # NS16sOperator::section2(universe)
    def self.section2(universe)
        [
            TxDrops::ns16sOverflowing(universe),
            TxTodos::ns16sOverflowing(universe)
        ]
            .flatten
            .select{|item| DoNotShowUntil::isVisible(item["uuid"]) }
            .select{|ns16| InternetStatus::ns16ShouldShow(ns16["uuid"]) }
    end

    # NS16sOperator::section3(universe)
    def self.section3(universe)
        [
            (universe == "lucille") ? Anniversaries::ns16s() : [],
            TxCalendarItems::ns16s(),
            JSON.parse(`/Users/pascal/Galaxy/LucilleOS/Binaries/amanda-bins`),
            JSON.parse(`/Users/pascal/Galaxy/LucilleOS/Binaries/fitness ns16s`),
            TxDateds::ns16s(),
            Waves::ns16s(universe),
            (universe == "lucille") ? Inbox::ns16s() : [],
            PersonalAssistant::removeRedundanciesInSecondArrayRelativelyToFirstArray(TxDrops::ns16sOverflowing(universe), TxDrops::ns16s(universe)),
            PersonalAssistant::removeRedundanciesInSecondArrayRelativelyToFirstArray(TxTodos::ns16sOverflowing(universe), TxTodos::ns16s(universe))
        ]
            .flatten
            .select{|item| DoNotShowUntil::isVisible(item["uuid"]) }
            .select{|ns16| InternetStatus::ns16ShouldShow(ns16["uuid"]) }
    end
end

class PersonalAssistant

    # PersonalAssistant::removeDuplicatesOnAttribute(array, attribute)
    def self.removeDuplicatesOnAttribute(array, attribute)
        array.reduce([]){|selected, element|
            if selected.none?{|x| x[attribute] == element[attribute] } then
                selected + [element]
            else
                selected
            end
        }
    end

    # PersonalAssistant::removeRedundanciesInSecondArrayRelativelyToFirstArray(array1, array2)
    def self.removeRedundanciesInSecondArrayRelativelyToFirstArray(array1, array2)
        uuids1 = array1.map{|ns16| ns16["uuid"] }
        array2.select{|ns16| !uuids1.include?(ns16["uuid"]) }
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

    # TerminalDisplayOperator::display(universe, floats, section2, section3)
    def self.display(universe, floats, section2, section3)
        system("clear")

        vspaceleft = Utils::screenHeight()-3

        puts ""
        cardinal = TxDateds::items().size + TxTodos::items().size + TxDrops::mikus().size
        puts "(universe: #{universe}, cardinal: #{cardinal} items)"
        vspaceleft = vspaceleft - 2

        puts ""
        Multiverse::universes()
            .select{|universe|
                UniverseAccounting::universeExpectationOrNull(universe)
            }
            .sort{|u1, u2| UniverseAccounting::universeRatioOrNull(u1) <=> UniverseAccounting::universeRatioOrNull(u2) }
            .each{|uni|
                expectation = UniverseAccounting::universeExpectationOrNull(uni)
                uniRatio = UniverseAccounting::universeRatioOrNull(uni)
                line = "#{uni.ljust(10)}: #{"%6.2f" % (100 * UniverseAccounting::universeRT(uni))} % of #{"%.2f" % expectation} hours"
                if uni == universe then
                    line = line.green
                end
                puts line
                vspaceleft = vspaceleft - 1
            }

        store = ItemStore.new()

        if !InternetStatus::internetIsActive() then
            puts ""
            puts "INTERNET IS OFF".green
            vspaceleft = vspaceleft - 2
        end

        if floats.size>0 then
            puts ""
            vspaceleft = vspaceleft - 1
        end
        floats.each{|ns16|
            store.register(ns16, false)
            line = "#{store.prefixString()} [#{Time.at(ns16["TxFloat"]["unixtime"]).to_s[0, 10]}] #{ns16["announce"]}".yellow
            puts line
            vspaceleft = vspaceleft - Utils::verticalSize(line)
        }

        running = BTreeSets::values(nil, "a69583a5-8a13-46d9-a965-86f95feb6f68")
        if running.size>0 then
            puts ""
            vspaceleft = vspaceleft - 1
        end
        running
                .sort{|t1, t2| t1["unixtime"] <=> t2["unixtime"] } # || 0 because we had some running while updating this
                .each{|nxball|
                    delegate = {
                        "uuid"       => "84FF58F7-6607-4E32:#{nxball["uuid"]}",
                        "NxBallUUID" => nxball["uuid"],
                        "NS198"      => "NxBallDelegate1" 
                    }
                    store.register(delegate, true)
                    line = "#{store.prefixString()} #{nxball["description"]} (#{NxBallsService::runningStringOrEmptyString("", nxball["uuid"], "")})".green
                    puts line
                    vspaceleft = vspaceleft - Utils::verticalSize(line)
                }

        if section2.size>0 then
            puts ""
            vspaceleft = vspaceleft - 1
        end
        section2
            .each{|ns16|
                store.register(ns16, false)
                line = ns16["announce"]
                line = "#{store.prefixString()} #{line}#{TerminalDisplayOperator::commandStrWithPrefix(ns16, store.latestEnteredItemIsDefault())}"
                break if (vspaceleft - Utils::verticalSize(line)) < 0
                puts line
                vspaceleft = vspaceleft - Utils::verticalSize(line)
            }

        top = Topping::getText(universe)
        if top.strip.size > 0 then
            puts ""
            puts "(-->)".green
            top = top.lines.first(10).join().strip.lines.map{|line| "      #{line}" }.join()
            puts top
            vspaceleft = vspaceleft - Utils::verticalSize(top) - 2
        end

        if section3.size>0 then
            puts ""
            vspaceleft = vspaceleft - 1
        end
        section3
            .each{|ns16|
                store.register(ns16, true)
                line = ns16["announce"]
                line = "#{store.prefixString()} #{line}#{TerminalDisplayOperator::commandStrWithPrefix(ns16, store.latestEnteredItemIsDefault())}"
                break if (vspaceleft - Utils::verticalSize(line)) < 0
                puts line
                vspaceleft = vspaceleft - Utils::verticalSize(line)
            }

        puts ""

        input = LucilleCore::askQuestionAnswerAsString("> ")

        return if input == ""

        if (unixtime = Utils::codeToUnixtimeOrNull(input.gsub(" ", ""))) then
            if (item = store.getDefault()) then
                DoNotShowUntil::setUnixtime(item["uuid"], unixtime)
                return
            end
        end

        CommandsOps::operator4(universe, input)
        CommandsOps::operator5(universe, input, store.getDefault())
        command, objectOpt = CommandsOps::inputParser(input, store)
        #puts "parser: command:#{command}, objectOpt: #{objectOpt}"
        CommandsOps::operator6(universe, command, objectOpt)
    end

    # TerminalDisplayOperator::displayLoop()
    def self.displayLoop()
        initialCodeTrace = Utils::codeTrace()
        loop {
            if Utils::codeTrace() != initialCodeTrace then
                puts "Code change detected"
                break
            end

            universe = StoredUniverse::getStoredFocusUniverse()
            floats = TxFloats::ns16s(universe)
                        .select{|item| DoNotShowUntil::isVisible(item["uuid"]) }
                        .select{|ns16| InternetStatus::ns16ShouldShow(ns16["uuid"]) }

            section2 = NS16sOperator::section2(universe)
            section3 = NS16sOperator::section3(universe)
            section3 = PersonalAssistant::removeRedundanciesInSecondArrayRelativelyToFirstArray(section2, section3)
            TerminalDisplayOperator::display(universe, floats, section2, section3)
        }
    end
end
