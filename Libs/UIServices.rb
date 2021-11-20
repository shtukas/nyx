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
                    system("/Users/pascal/Galaxy/LucilleOS/Binaries/fitness doing #{ns16["fitness-domain"]}") 
                end
            }
            ns16["start-land"] = lambda {
                system("/Users/pascal/Galaxy/LucilleOS/Binaries/fitness doing #{ns16["fitness-domain"]}") 
            }
            ns16
        }
    end
end

class AmandaBins
    # AmandaBins::ns16s()
    def self.ns16s()
        JSON.parse(`/Users/pascal/Galaxy/LucilleOS/Binaries/amanda-bin-monitor`)
    end
end

class NS16sOperator

    # NS16sOperator::theUnscheduledItemAsArray()
    def self.theUnscheduledItemAsArray()
        item = KeyValueStore::getOrNull(nil, "f05fe844-128b-4e80-b13e-e0756c84204c")
        return [] if item.nil?
        item = JSON.parse(item)
        item["interpreter"] = lambda {|command|
            if command == "done" then
                NxBallsService::close("04b8932b-986a-4f25-8320-5fc00c076dc1", true)
                KeyValueStore::destroy(nil, "f05fe844-128b-4e80-b13e-e0756c84204c")
                return true
            end
        }
        item
    end

    # NS16sOperator::ns16s(domain)
    def self.ns16s(domain)
        [
            NS16sOperator::theUnscheduledItemAsArray(),
            Anniversaries::ns16s(),
            Top::ns16(),
            Calendar::ns16s(),
            AmandaBins::ns16s(),
            Fitness::ns16s(),
            DrivesBackups::ns16s(),
            Waves::ns16s(domain),
            Inbox::ns16s(),
            Dated::ns16s(),
            Nx50s::ns16sCommunications(domain),
            Nx50s::ns16s(domain),
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
        "internet on | internet off | requires internet"
    end

    # InternetStatus::interpreter(command, store)
    def self.interpreter(command, store)

        if Interpreting::match("internet on", command) then
            InternetStatus::setInternetOn()
        end

        if Interpreting::match("internet off", command) then
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

    # UIServices::mainView(domain, ns16s)
    def self.mainView(domain, ns16s)

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
            "      " + Interpreters::listingCommands(),
            "      " + Interpreters::makersCommands(),
            "      " + Interpreters::diversCommands(),
            "      " + Domain::domainsMenuCommands(),
            "      " + Nx50s::dx(),
            "      " + InternetStatus::putsInternetCommands()
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

        puts ""
        puts "floats:"
        vspaceleft = vspaceleft - 2
        Floats::items(domain)
            .each{|object|
                line = "(#{store.register(object).to_s.rjust(3, " ")}) #{object["announce"]}"
                puts line
                vspaceleft = vspaceleft - Utils::verticalSize(line)
            }

        running = BTreeSets::values(nil, "a69583a5-8a13-46d9-a965-86f95feb6f68")
        if running.size > 0 then
            puts ""
            puts "running:"
            vspaceleft = vspaceleft - 2
            running.each{|nxball|
                indx = store.register(nxball)
                announce = "(#{"%3d" % indx}) #{nxball["description"]}".green
                puts announce
                vspaceleft = vspaceleft - Utils::verticalSize(announce)
            }
        end

        puts ""
        puts "todo:"
        vspaceleft = vspaceleft - 2
        collection
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

        puts ""
        command = LucilleCore::askQuestionAnswerAsString("> ")

        return if command == ""

        # We first interpret the command as an index and call "start-land"
        # Or interpret it a command and run it by the default element interpreter.
        # Otherwise we try a bunch of generic interpreters.

        if command == ".." and store.getDefault() and store.getDefault()["start-land"] then
            store.getDefault()["start-land"].call()
            return
        end

        if (i = Interpreting::readAsIntegerOrNull(command)) then
            item = store.get(i)
            return if item.nil?
            item["start-land"].call()
            return
        end

        Interpreters::listingInterpreter(store, command)
        Interpreters::makersAndDiversInterpreter(command)
        Domain::domainsCommandInterpreter(command)
        InternetStatus::interpreter(command, store)

        if store.getDefault() then
            item = store.getDefault()
            if item["interpreter"] then
                item["interpreter"].call(command)
            end
        end
    end
end

class Fsck
    # Fsck::fsck()
    def self.fsck()

        Anniversaries::anniversaries().each{|item|
            puts JSON.pretty_generate(item)
        }

        puts "Fsck Completed!".green
        LucilleCore::pressEnterToContinue()
    end
end
