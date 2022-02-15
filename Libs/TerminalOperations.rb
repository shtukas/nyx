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

    def register(item, canBeDefault)
        cursor = @items.size
        @items << item
        if !@topIsActive and @defaultItem.nil? and canBeDefault then
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

    # NS16sOperator::ns16Overflowing()
    def self.ns16Overflowing()
        [
            TxDrops::ns16sOverflowing(),
            TxTodos::ns16sOverflowing()
        ]
            .flatten
            .select{|item| DoNotShowUntil::isVisible(item["uuid"]) }
            .select{|ns16| InternetStatus::ns16ShouldShow(ns16["uuid"]) }
    end

    # NS16sOperator::ns16s1()
    def self.ns16s1()
        [
            Anniversaries::ns16s(),
            TxCalendarItems::ns16s(),
            JSON.parse(`/Users/pascal/Galaxy/LucilleOS/Binaries/amanda-bins`),
            JSON.parse(`/Users/pascal/Galaxy/LucilleOS/Binaries/fitness ns16s`),
            TxDateds::ns16s(),
            Waves::ns16s(),
            TxDrops::ns16s(),
            TxTodos::ns16sStarted()
        ]
            .flatten
            .select{|item| DoNotShowUntil::isVisible(item["uuid"]) }
            .select{|ns16| InternetStatus::ns16ShouldShow(ns16["uuid"]) }
    end

    # NS16sOperator::ns16s2()
    def self.ns16s2()
        [
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

    # PersonalAssistant::removeDuplicatesOnUuidAttribute(array)
    def self.removeDuplicatesOnUuidAttribute(array)
        array.reduce([]){|selected, element|
            if selected.none?{|x| x["uuid"] == element["uuid"] } then
                selected + [element]
            else
                selected
            end
        }
    end

    # PersonalAssistant::garbageCollectSecondArray(array1, array2)
    def self.garbageCollectSecondArray(array1, array2)
        uuids1 = array1.map{|ns16| ns16["uuid"] }
        array2.select{|ns16| !uuids1.include?(ns16["uuid"]) }
    end

    # PersonalAssistant::getSection3(section2, ns16sp1, ns16sp2)
    def self.getSection3(section2, ns16sp1, ns16sp2)
        lookup = lambda{|uuid, ns16s|
            ns16s.select{|ns16| ns16["uuid"] == uuid }.first
        }

        ns16sp1 = PersonalAssistant::garbageCollectSecondArray(section2, ns16sp1)
        ns16sp2 = PersonalAssistant::garbageCollectSecondArray(section2, ns16sp2)

        section3 = JSON.parse(KeyValueStore::getOrDefaultValue(nil, PersonalAssistant::key(), "[]"))

        # We select only the section3 elements with an alive uuid, meaning which actively appear either in ns16sp1 or ns16sp2
        uuidsStillAlive = (ns16sp1+ns16sp2).map{|ns16| ns16["uuid"] }
        section3 = section3
                        .select{|ns16| uuidsStillAlive.include?(ns16["uuid"]) }

        # We perform a look up to extract the latest version of those elements
        section3 = section3
                        .map{|ns16| lookup.call(ns16["uuid"], ns16sp1+ns16sp2)}
                        .compact

        # We remove those in section 2
        section2Uuids = section2.map{|ns16| ns16["uuid"] }
        section3 = section3
                        .select{|ns16| !section2Uuids.include?(ns16["uuid"]) }

        # We remove those which should not be shown either for having been DoNotDisplayed or InternetStatued
        section3 = section3
                        .select{|item| DoNotShowUntil::isVisible(item["uuid"]) }
                        .select{|ns16| InternetStatus::ns16ShouldShow(ns16["uuid"]) }

        # We make sure that we have all of ns16sp1
        # We want the missing one to come last to implement the section ordering
        section3 = PersonalAssistant::removeDuplicatesOnUuidAttribute(section3 + ns16sp1)

        # We store the current version of section3 before returning it 
        KeyValueStore::set(nil, PersonalAssistant::key(), JSON.generate(section3))
        section3
    end

    # PersonalAssistant::maintainSection3Size(section2, section3, ns16sp2)
    def self.maintainSection3Size(section2, section3, ns16sp2)
        section3 = PersonalAssistant::garbageCollectSecondArray(section2, section3)
        return section3 if (section2+section3).size > 10
        ns16sp2 = PersonalAssistant::garbageCollectSecondArray(section2+section3, ns16sp2)
        section3 = (section3 + ns16sp2).first(10)
        KeyValueStore::set(nil, PersonalAssistant::key(), JSON.generate(section3))
        section3
    end

    # PersonalAssistant::rotate()
    def self.rotate()
        section3 = JSON.parse(KeyValueStore::getOrDefaultValue(nil, PersonalAssistant::key(), "[]"))
        first = section3.shift
        section3 = section3 + [first]
        KeyValueStore::set(nil, PersonalAssistant::key(), JSON.generate(section3))
    end

    # PersonalAssistant::pushThisUuidToLast(uuid)
    def self.pushThisUuidToLast(uuid)
        section3 = JSON.parse(KeyValueStore::getOrDefaultValue(nil, PersonalAssistant::key(), "[]"))
        section3p1, section3p2 = section3.partition{|ns16| ns16["uuid"] != uuid } 
        section3 = section3p1 + section3p2
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

    # TerminalDisplayOperator::display(floats, section2, section3)
    def self.display(floats, section2, section3)
        system("clear")

        vspaceleft = Utils::screenHeight()-3

        puts ""
        cardinal = TxDateds::items().size + TxTodos::items().size + TxDrops::mikus().size
        puts "(cardinal: #{cardinal} items)"
        vspaceleft = vspaceleft - 2

        puts ""
        vspaceleft = vspaceleft - 1

        store = ItemStore.new()

        if !InternetStatus::internetIsActive() then
            puts "INTERNET IS OFF".green
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

        top = Topping::getText()
        if top.size > 0 then
            store.setTopActive()
            top = top.lines.first(10).join().strip
            puts "(-->)".green
            puts top
            puts ""
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

            section2 = NS16sOperator::ns16Overflowing()
            section3 = PersonalAssistant::getSection3(section2, NS16sOperator::ns16s1(), NS16sOperator::ns16s2())
            section3 = PersonalAssistant::maintainSection3Size(section2, section3, NS16sOperator::ns16s2())
            TerminalDisplayOperator::display(floats, section2, section3)
        }
    end
end
