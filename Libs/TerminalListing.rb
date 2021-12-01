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
        "start # unscheduled | monitor | today | ondate | todo | wave | anniversary"
    end

    # Commands::diversCommands()
    def self.diversCommands()
        "calendar | waves | ondates | Nx50s | anniversaries | search | nyx"
    end

    # Commands::makersAndDiversCommands()
    def self.makersAndDiversCommands()
        [
            Commands::makersCommands(),
            Commands::diversCommands()
        ].join(" | ")
    end
end

$nx77 = nil

class DisplayListingParameters

    # DisplayListingParameters::ns16sNonNx50s(listing)
    def self.ns16sNonNx50s(listing)
        [
            Anniversaries::ns16s(),
            Calendar::ns16s(),
            JSON.parse(`/Users/pascal/Galaxy/LucilleOS/Binaries/amanda-bin-monitor`),
            JSON.parse(`/Users/pascal/Galaxy/LucilleOS/Binaries/fitness ns16s`),
            DrivesBackups::ns16s(),
            Waves::ns16s(listing),
            Inbox::ns16s()
        ]
            .flatten
            .compact
            .select{|item| DoNotShowUntil::isVisible(item["uuid"]) }
            .select{|ns16| InternetStatus::ns16ShouldShow(ns16["uuid"]) }
    end

    # DisplayListingParameters::removeDuplicates(ns16s)
    def self.removeDuplicates(ns16s)
        ns16s.reduce([]){|elements, ns16|
            if elements.none?{|x| x["uuid"] == ns16["uuid"]} then
                elements << ns16
            end
            elements
        }
    end

    # DisplayListingParameters::getTerminalDisplayParametersForListing(listing)
    def self.getTerminalDisplayParametersForListing(listing)
        ns16sNonNx50s = DisplayListingParameters::ns16sNonNx50s(listing)
        structure = Nx50s::structureForDomain(listing)
        {
            "listing"  => listing,
            "monitor2" => structure["Monitor"],
            "ns16s"    => ns16sNonNx50s + structure["Dated"] + structure["Tail"]
        }
    end

    # DisplayListingParameters::getTerminalDisplayParametersForListingUseCache(listing)
    def self.getTerminalDisplayParametersForListingUseCache(listing)
        computeNewNx77 = lambda {|listing|
            {
                "unixtime"   => Time.new.to_i,
                "parameters" => DisplayListingParameters::getTerminalDisplayParametersForListing(listing)
            }
        }
        nx77 = KeyValueStore::getOrNull(nil, "d0a7cd44-2309-4263-8dd3-997ac657aebe:#{listing}")
        if nx77.nil? then
            nx77 = computeNewNx77.call(listing)
        else
            nx77 = JSON.parse(nx77)
        end
        if (Time.new.to_f - nx77["unixtime"]) > 36400*2 then # We expire after 2 hours
            nx77 = computeNewNx77.call(listing)
        end
        if nx77["parameters"]["ns16s"].empty? then
            nx77 = computeNewNx77.call(listing)
        end
        while uuid = Mercury::dequeueFirstValueOrNull("A4EC3B4B-NATHALIE-COLLECTION-REMOVE") do
            puts "[Nx77] removing uuid: #{uuid}"
            nx77["parameters"]["ns16s"] = nx77["parameters"]["ns16s"].select{|ns16| ns16["uuid"] != uuid }
        end
        KeyValueStore::set(nil, "d0a7cd44-2309-4263-8dd3-997ac657aebe:#{listing}", JSON.generate(nx77))
        nx77["parameters"]
    end
end

class DisplayOperator

    # DisplayOperator::listing(listing or null, monitor2, ns16s)
    def self.listing(listing, monitor2, ns16s)

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
            "      " + Commands::terminalDisplayCommand(),
            "      " + Commands::makersCommands(),
            "      " + Commands::diversCommands(),
            "      internet on | internet off | require internet"
        ].join("\n").yellow

        vspaceleft = vspaceleft - Utils::verticalSize(infolines)

        store = ItemStore.new()

        puts ""
        puts "--> #{listing} #{Listings::dx()}".green
        vspaceleft = vspaceleft - 2

        if !InternetStatus::internetIsActive() then
            puts ""
            puts "INTERNET IS OFF".green
            vspaceleft = vspaceleft - 2
        end

        puts ""
        puts "commands:"
        puts infolines

        if !monitor2.empty? then
            puts ""
            vspaceleft = vspaceleft - 1
            puts "monitor:".yellow
            monitor2.each{|ns16|
                line = "(#{store.register(ns16).to_s.rjust(3, " ")}) [#{Time.at(ns16["Nx50"]["unixtime"]).to_s[0, 10]}] #{ns16["announce"]}".yellow
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

        catalyst = IO.read("/Users/pascal/Desktop/Catalyst.txt").strip
        if catalyst.size > 0 then
            puts ""
            puts "Catalyst.txt is not empty".green
            vspaceleft = vspaceleft - 2
        end

        puts ""
        puts "todo:"
        vspaceleft = vspaceleft - 2
        collection
            .select{|ns16| !runningUUIDs.include?(ns16["uuid"]) }
            .each{|ns16|
                indx = store.register(ns16)
                isDefaultItem = ((ns16["defaultable"].nil? or ns16["defaultable"]) and store.getDefault().nil?) # the default item is the first element, unless it's defaultable
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

    # DisplayOperator::displayLoop()
    def self.displayLoop()
        loop {
            listing = Listings::getListingForTerminalDisplay()
            parameters = DisplayListingParameters::getTerminalDisplayParametersForListingUseCache(listing)
            DisplayOperator::listing(parameters["listing"], parameters["monitor2"], parameters["ns16s"])
        }
    end
end
