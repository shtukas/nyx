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

    # Commands::listingCommands()
    def self.listingCommands()
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

class DisplayListingParameters

    # DisplayListingParameters::ns16sNonNx50s(domain)
    def self.ns16sNonNx50s(domain)
        [
            Anniversaries::ns16s(),
            Calendar::ns16s(),
            JSON.parse(`/Users/pascal/Galaxy/LucilleOS/Binaries/amanda-bin-monitor`),
            JSON.parse(`/Users/pascal/Galaxy/LucilleOS/Binaries/fitness ns16s`),
            DrivesBackups::ns16s(),
            Waves::ns16s(domain),
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

    # DisplayListingParameters::getListingParametersForDomain(domain)
    def self.getListingParametersForDomain(domain)
        ns16sNonNx50s = DisplayListingParameters::ns16sNonNx50s(domain)
        structure = Nx50s::structureForDomain(domain)
        {
            "domain"   => domain,
            "monitor2" => [
                {
                    "domain" => domain,
                    "ns16s"  => structure["Monitor"]
                }
            ],
            "overflow" => structure["overflow"],
            "ns16s"    => ns16sNonNx50s + structure["Dated"] + structure["Tail"]
        }
    end
end

class DisplayOperator

    # DisplayOperator::listing(domain or null, monitor2, overflow, ns16s)
    def self.listing(domain, monitor2, overflow, ns16s)

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
            "      " + Commands::listingCommands(),
            "      " + Commands::makersCommands(),
            "      " + Commands::diversCommands(),
            "      internet on | internet off | require internet"
        ].join("\n").yellow

        vspaceleft = vspaceleft - Utils::verticalSize(infolines)

        store = ItemStore.new()

        puts ""
        puts "--> #{domain || "Nathalie"} #{Nathalie::dx()}".green
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

        puts ""
        vspaceleft = vspaceleft - 1

        monitor2.each{|item|
            puts "monitor: #{item["domain"]}".yellow
            vspaceleft = vspaceleft - 1
            item["ns16s"].each{|ns16|
                line = "(#{store.register(ns16).to_s.rjust(3, " ")}) [#{Time.at(ns16["Nx50"]["unixtime"]).to_s[0, 10]}] #{ns16["announce"]}".yellow
                puts line
                vspaceleft = vspaceleft - Utils::verticalSize(line)
            }
        }

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

    # DisplayOperator::displayLoop()
    def self.displayLoop()
        loop {
            domain = Domain::getContextualDomainOrNull()
            if domain then
                parameters = DisplayListingParameters::getListingParametersForDomain(domain)
            else
                parameters = Nathalie::listingParameters()
            end
            DisplayOperator::listing(parameters["domain"], parameters["monitor2"], parameters["overflow"], parameters["ns16s"])
        }
    end
end
