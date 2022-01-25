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

class NS16sOperator

    # NS16sOperator::getFocusUnixtimeSortingTime(uuid)
    def self.getFocusUnixtimeSortingTime(uuid)
        unixtime = KeyValueStore::getOrNull(nil, "d5c340ae-c9f1-4dfb-961b-71b4d152e271:#{uuid}")
        return unixtime.to_f if unixtime
        unixtime = Time.new.to_f
        KeyValueStore::set(nil, "d5c340ae-c9f1-4dfb-961b-71b4d152e271:#{uuid}", unixtime)
        unixtime
    end

    # NS16sOperator::focus()
    def self.focus()
        [
            Mx49s::ns16s(),
            Nx70s::ns16s(),
            CatalystTxt::catalystTxtNs16s()
        ]
            .flatten
            .compact
            .select{|item| DoNotShowUntil::isVisible(item["uuid"]) }
            .select{|ns16| InternetStatus::ns16ShouldShow(ns16["uuid"]) }
            .sort{|i1, i2| NS16sOperator::getFocusUnixtimeSortingTime(i1["uuid"]) <=> NS16sOperator::getFocusUnixtimeSortingTime(i2["uuid"]) }
    end

    # NS16sOperator::ns16s()
    def self.ns16s()

        LucilleCore::locationsAtFolder("/Users/pascal/Desktop/Nx50s (Random)")
            .map{|location|
                puts "Importing Nx50s (Random): #{location}"
                nx50 = {
                    "uuid"        => SecureRandom.uuid,
                    "unixtime"    => Time.new.to_i,
                    "ordinal"     => Nx50s::ordinalBetweenN1thAndN2th(30, 50),
                    "description" => File.basename(location),
                    "atom"        => CoreData5::issueAionPointAtomUsingLocation(location),
                }
                Nx50s::commit(nx50)
                LucilleCore::removeFileSystemLocation(location)
            }

        [
            Anniversaries::ns16s(),
            Calendar::ns16s(),
            JSON.parse(`/Users/pascal/Galaxy/LucilleOS/Binaries/amanda-bins`),
            JSON.parse(`/Users/pascal/Galaxy/LucilleOS/Binaries/fitness ns16s`),
            Waves::ns16s(),
            Inbox::ns16s(),
            TwentyTwo::ns16s()
        ]
            .flatten
            .compact
            .select{|item| DoNotShowUntil::isVisible(item["uuid"]) }
            .select{|ns16| InternetStatus::ns16ShouldShow(ns16["uuid"]) }
    end
end

class TerminalDisplayOperator

    # TerminalDisplayOperator::display(floats, spaceships, focus, ns16s)
    def self.display(floats, spaceships, focus, ns16s)

        commandStrWithPrefix = lambda{|ns16, isDefaultItem|
            return "" if !isDefaultItem
            return "" if ns16["commands"].nil?
            return "" if ns16["commands"].empty?
            " (commands: #{ns16["commands"].join(", ")})".yellow
        }

        system("clear")

        vspaceleft = Utils::screenHeight()-4

        puts ""
        puts "#{TwentyTwo::dx()} (Nx50: #{Nx50s::nx50s().size} items)"
        vspaceleft = vspaceleft - 2

        puts ""

        store = ItemStore.new()

        if !InternetStatus::internetIsActive() then
            puts "INTERNET IS OFF".green
            vspaceleft = vspaceleft - 1
        end

        floats.each{|ns16|
            line = "(#{store.register(ns16).to_s.rjust(3, " ")}) [#{Time.at(ns16["Mx48"]["unixtime"]).to_s[0, 10]}] #{ns16["announce"]}".yellow
            puts line
            vspaceleft = vspaceleft - Utils::verticalSize(line)
        }
        if floats.size>0 then
            puts ""
            vspaceleft = vspaceleft - 1
        end

        spaceships.each{|ns16|
            line = "(#{store.register(ns16).to_s.rjust(3, " ")}) [#{Time.at(ns16["Nx60"]["unixtime"]).to_s[0, 10]}] #{ns16["announce"]}"
            puts line
            vspaceleft = vspaceleft - Utils::verticalSize(line)
        }
        if spaceships.size>0 then
            puts ""
            vspaceleft = vspaceleft - 1
        end

        focus.each{|ns16|
            line = "(#{store.register(ns16).to_s.rjust(3, " ")}) #{ns16["announce"]}"
            puts line
            vspaceleft = vspaceleft - Utils::verticalSize(line)
        }
        if focus.size>0 then
            puts ""
            vspaceleft = vspaceleft - 1
        end

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
        if running.size>0 then
            puts ""
            vspaceleft = vspaceleft - 1
        end
        runningUUIDs = running.map{|item| item["uuid"] }

        ns16s
            .each{|ns16|
                indx = store.register(ns16)
                isDefaultItem = store.getDefault().nil?
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
            floats = Mx48s::ns16s()
            spaceships = Nx60s::ns16s()
            focus = NS16sOperator::focus()
            ns16s = NS16sOperator::ns16s()
            TerminalDisplayOperator::display(floats, spaceships, focus, ns16s)
        }
    end
end
