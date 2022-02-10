# encoding: UTF-8

# ------------------------------------------------------------------------------------------

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

class Ordinals

    # Ordinals::getOrdinalForUUIDOrNull(uuid)
    def self.getOrdinalForUUIDOrNull(uuid)
        ordinal = KeyValueStore::getOrNull(nil, "d5c340ae-c9f1-4dfb-961b-71b4d152e271:#{Utils::today()}:#{uuid}")
        return ordinal.to_f if ordinal
        nil
    end

    # Ordinals::setOrdinalForUUID(uuid, ordinal)
    def self.setOrdinalForUUID(uuid, ordinal)
        KeyValueStore::set(nil, "d5c340ae-c9f1-4dfb-961b-71b4d152e271:#{Utils::today()}:#{uuid}", ordinal)
    end
end

class NS16sOperator

    # NS16sOperator::getListingUnixtime(uuid)
    def self.getListingUnixtime(uuid)
        unixtime = KeyValueStore::getOrNull(nil, "d5c340ae-c9f1-4dfb-961b-71b4d152e271:#{uuid}")
        return unixtime.to_f if unixtime
        unixtime = Time.new.to_f
        KeyValueStore::set(nil, "d5c340ae-c9f1-4dfb-961b-71b4d152e271:#{uuid}", unixtime)
        unixtime
    end

    # NS16sOperator::misc()
    def self.misc()
        [
            JSON.parse(`/Users/pascal/Galaxy/LucilleOS/Binaries/amanda-bins`),
            JSON.parse(`/Users/pascal/Galaxy/LucilleOS/Binaries/fitness ns16s`),
        ]
            .flatten
            .compact
            .select{|item| DoNotShowUntil::isVisible(item["uuid"]) }
            .select{|ns16| InternetStatus::ns16ShouldShow(ns16["uuid"]) }
    end

    # NS16sOperator::todoNs16s(focus)
    def self.todoNs16s(focus)
        if focus == "eva" then
            TxTodos::ns16s()
        else
            TxWorkItems::ns16s()
        end
    end

    # NS16sOperator::ns16s(focus)
    def self.ns16s(focus)
        [
            Anniversaries::ns16s(),
            Calendar::ns16s(),
            NS16sOperator::misc(),
            TxDateds::ns16s(),
            Waves::ns16s(),
            TxDrops::ns16s(),
            Inbox::ns16s(),
            TxSpaceships::ns16s(focus),
            NS16sOperator::todoNs16s(focus)
        ]
            .flatten
            .compact
            .select{|item| DoNotShowUntil::isVisible(item["uuid"]) }
            .select{|ns16| InternetStatus::ns16ShouldShow(ns16["uuid"]) }
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

    # TerminalDisplayOperator::display(focus, floats, ns16s)
    def self.display(focus, floats, ns16s)
        system("clear")

        vspaceleft = Utils::screenHeight()-4

        puts ""
        cardinal = TxDateds::items().size + TxTodos::items().size + TxWorkItems::items().size + TxSpaceships::items().size + TxDrops::mikus().size
        puts "(focus: #{focus})".green + " (cardinal: #{cardinal} items)"
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

        top = Topping::getText(focus)
        if top.size > 0 then
            store.setTopActive()
            top = top.lines.first(10).join().strip
            puts "(-->)".green
            puts top
            puts ""
            vspaceleft = vspaceleft - Utils::verticalSize(top) - 2
        end

        ns16s
            .each{|ns16|
                store.register(ns16)
                line = ns16["announce"]
                line = "#{store.prefixString()} #{line}#{TerminalDisplayOperator::commandStrWithPrefix(ns16, store.latestEnteredItemIsDefault())}"
                break if (vspaceleft - Utils::verticalSize(line)) < 0
                puts line + " (#{vspaceleft})"
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

        CommandsOps::operator4(command, focus)
        CommandsOps::operator1(store.getDefault(), command)
    end

    # TerminalDisplayOperator::displayLoop()
    def self.displayLoop()

        filter1 = lambda {|ns16s|
            ns16s            
                .select{|item| DoNotShowUntil::isVisible(item["uuid"]) }
                .select{|ns16| InternetStatus::ns16ShouldShow(ns16["uuid"]) }
        }

        initialCodeTrace = Utils::codeTrace()
        loop {
            if Utils::codeTrace() != initialCodeTrace then
                puts "Code change detected"
                break
            end

            # Every loop maintenance
            TxTodos::importTxTodosRandom()

            focus = DomainsX::focus()
            floats = TxFloats::ns16s(focus)
                        .select{|item| DoNotShowUntil::isVisible(item["uuid"]) }
                        .select{|ns16| InternetStatus::ns16ShouldShow(ns16["uuid"]) }
            ns16s  = NS16sOperator::ns16s(focus)
            TerminalDisplayOperator::display(focus, floats, ns16s)
        }
    end
end
