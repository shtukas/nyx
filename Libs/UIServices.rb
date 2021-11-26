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

class UIServices

    # UIServices::domainsMenuCommands()
    def self.domainsMenuCommands()
        today = Time.new.to_s[0, 10]
        Domain::domains()
            .map{|domain|
                account = Domain::domainToBankAccount(domain)
                value = Bank::valueAtDate(account, today).to_f/3600
                d = domain.gsub("(", "").gsub(")", "")
                "(#{d}: #{value.round(2)} hours today)"
            }
            .join(" ")
    end

    # UIServices::listingCommands()
    def self.listingCommands()
        ".. | <n> | <datecode> | expose"
    end

    # UIServices::makersCommands()
    def self.makersCommands()
        "start # unscheduled | monitor | today | ondate | todo | wave | anniversary"
    end

    # UIServices::diversCommands()
    def self.diversCommands()
        "calendar | waves | ondates | Nx50s | anniversaries | search | nyx"
    end

    # UIServices::makersAndDiversCommands()
    def self.makersAndDiversCommands()
        [
            UIServices::makersCommands(),
            UIServices::diversCommands()
        ].join(" | ")
    end

    # UIServices::mainView(domain, floats, overflow, ns16s)
    def self.mainView(domain, floats, overflow, ns16s)

        collection = ns16s.clone

        commandStrWithPrefix = lambda{|ns16, isDefaultItem|
            return "" if !isDefaultItem
            return "" if ns16["commands"].nil?
            return "" if ns16["commands"].empty?
            " (commands: #{ns16["commands"].join(", ")})".yellow
        }

        system("clear")

        vspaceleft = Utils::screenHeight()-5

        infolines = [
            "      " + UIServices::listingCommands(),
            "      " + UIServices::makersCommands(),
            "      " + UIServices::diversCommands(),
            "      " + UIServices::domainsMenuCommands(),
            "      internet on | internet off | require internet"
        ].join("\n").yellow

        vspaceleft = vspaceleft - Utils::verticalSize(infolines)

        store = ItemStore.new()

        puts ""
        puts "--> #{domain}".green
        vspaceleft = vspaceleft - 2

        if !InternetStatus::internetIsActive() then
            puts ""
            puts "INTERNET IS OFF".green
            vspaceleft = vspaceleft - 2
        end

        puts ""
        puts "commands:"
        puts infolines

        # This blank run is only to reserve screen space
        if overflow.size > 0 then
            vspaceleft = vspaceleft - 2
            overflow.each{|ns16|
                announce = "(#{"%3d" % 0}) #{ns16["announce"]}"
                #puts announce
                vspaceleft = vspaceleft - Utils::verticalSize(announce)
            }
        end

        if floats.size > 0 then
            puts ""
            puts "monitor:"
            vspaceleft = vspaceleft - 2
            floats
                .each{|object|
                    line = "(#{store.register(object).to_s.rjust(3, " ")}) #{object["announce"]}"
                    puts line
                    vspaceleft = vspaceleft - Utils::verticalSize(line)
                }
        end

        running = BTreeSets::values(nil, "a69583a5-8a13-46d9-a965-86f95feb6f68")
        if running.size > 0 then
            puts ""
            puts "running:"
            vspaceleft = vspaceleft - 2
            running
                .sort{|t1, t2| t1["uuid"]<=>t2["uuid"] }
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
        end
        runningUUIDs = running.map{|item| item["uuid"] }
        collection
            .select{|ns16| runningUUIDs.include?(ns16["uuid"]) }
            .sort{|t1, t2| t1["uuid"]<=>t2["uuid"] }
            .each{|ns16|
                indx = store.register(ns16)
                announce = "(#{"%3d" % indx}) #{ns16["announce"]}#{commandStrWithPrefix.call(ns16, false)}"
                puts announce
                vspaceleft = vspaceleft - Utils::verticalSize(announce)
            }

        puts ""
        puts "todo:"
        vspaceleft = vspaceleft - 2
        collection
            .select{|ns16| !runningUUIDs.include?(ns16["uuid"]) }
            .each{|ns16|
                indx = store.register(ns16)
                isDefaultItem = store.getDefault().nil? # the default item is the first element
                if isDefaultItem then
                    store.registerDefault(ns16)
                end
                posStr = isDefaultItem ? "(-->)".green : "(#{"%3d" % indx})"
                announce = "#{posStr} #{ns16["announce"]}#{commandStrWithPrefix.call(ns16, isDefaultItem)}"
                break if (!isDefaultItem and ((vspaceleft - Utils::verticalSize(announce)) < 0))
                puts announce
                vspaceleft = vspaceleft - Utils::verticalSize(announce)
            }

        if overflow.size > 0 then
            puts ""
            puts "overflow:"
            overflow.each{|ns16|
                indx = store.register(ns16)
                puts "(#{"%3d" % indx}) #{ns16["announce"]}"
            }
        end

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
            CentralDispatch::operator1(item, "..")
            return
        end

        CentralDispatch::operator4(command)
        CentralDispatch::operator5(store, command)

        if store.getDefault() then
            item = store.getDefault()
            CentralDispatch::operator1(item, command)
        end
    end

    # UIServices::mainViewDomainOptimization(ns16s)
    def self.mainViewDomainOptimization(ns16s)

        collection = ns16s.clone

        commandStrWithPrefix = lambda{|ns16, isDefaultItem|
            return "" if !isDefaultItem
            return "" if ns16["commands"].nil?
            return "" if ns16["commands"].empty?
            " (commands: #{ns16["commands"].join(", ")})".yellow
        }

        system("clear")

        vspaceleft = Utils::screenHeight()-5

        puts ""
        puts Domain::dx().yellow
        vspaceleft = vspaceleft - 2

        store = ItemStore.new()

        running = BTreeSets::values(nil, "a69583a5-8a13-46d9-a965-86f95feb6f68")
        if running.size > 0 then
            puts ""
            puts "running:"
            vspaceleft = vspaceleft - 2
            running
                .sort{|t1, t2| t1["uuid"]<=>t2["uuid"] }
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
        end
        runningUUIDs = running.map{|item| item["uuid"] }
        collection
            .select{|ns16| runningUUIDs.include?(ns16["uuid"]) }
            .sort{|t1, t2| t1["uuid"]<=>t2["uuid"] }
            .each{|ns16|
                indx = store.register(ns16)
                announce = "(#{"%3d" % indx}) #{ns16["announce"]}#{commandStrWithPrefix.call(ns16, false)}"
                puts announce
                vspaceleft = vspaceleft - Utils::verticalSize(announce)
            }

        puts ""
        collection
            .select{|ns16| !runningUUIDs.include?(ns16["uuid"]) }
            .each{|ns16|
                indx = store.register(ns16)
                isDefaultItem = store.getDefault().nil? # the default item is the first element
                if isDefaultItem then
                    store.registerDefault(ns16)
                end
                posStr = isDefaultItem ? "(-->)".green : "(#{"%3d" % indx})"
                announce = "#{ns16["x-domain"].ljust(7, " ")} #{posStr} #{ns16["announce"]}#{commandStrWithPrefix.call(ns16, isDefaultItem)}"
                break if (!isDefaultItem and ((vspaceleft - Utils::verticalSize(announce)) < 0))
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
            CentralDispatch::operator1(item, "..")
            return
        end

        CentralDispatch::operator4(command)
        CentralDispatch::operator5(store, command)

        if store.getDefault() then
            item = store.getDefault()
            CentralDispatch::operator1(item, command)
        end
    end

    # UIServices::displayLoop()
    def self.displayLoop()
        loop {
            domain = Domain::getDomain()
            structure = Nx50s::structure(domain)
            ns16s = NS16sOperator::ns16s(domain, structure)
            UIServices::mainView(domain, structure["Monitor"], structure["overflow"], ns16s)
        }
    end

    # UIServices::displayLoopDomainOptimization()
    def self.displayLoopDomainOptimization()
        loop {
            UIServices::mainViewDomainOptimization(Nathalie::getNS16sFromCollection())
        }
    end

end
