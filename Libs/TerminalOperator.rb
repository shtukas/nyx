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

class Nx77

    # Nx77::nx77ExpiryInSeconds()
    def self.nx77ExpiryInSeconds()
        3600
    end

    # Nx77::ns16sNonNx50s(listing)
    def self.ns16sNonNx50s(listing)
        if listing == "(eva)" then
            ns16s = [
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
        else
            ns16s = [
                JSON.parse(`/Users/pascal/Galaxy/LucilleOS/Binaries/fitness ns16s`),
                Waves::ns16s(listing)
            ]
                .flatten
                .compact
        end
        ns16s
            .select{|item| DoNotShowUntil::isVisible(item["uuid"]) }
            .select{|ns16| InternetStatus::ns16ShouldShow(ns16["uuid"]) }
    end

    # Nx77::makeNx76(listings, displayMode)
    def self.makeNx76(listings, displayMode)
        if displayMode == "SCREEN" then
            listing = listings.first
            ns16sNonNx50s = Nx77::ns16sNonNx50s(listing)
            structure = Nx50s::structureForDomain(listing)
            return {
                "monitor2" => structure["Monitor"],
                "ns16s"    => (ns16sNonNx50s + structure["Dated"] + structure["Tail"]).first(20)
            }
        end
        if displayMode == "STREAM" then
            null = {
                "monitor2" => [],
                "ns16s"    => []
            }
            return listings.reduce(null){|built, listing|
                ns16sNonNx50s = Nx77::ns16sNonNx50s(listing)
                structure = Nx50s::structureForDomain(listing)
                built["ns16s"] = built["ns16s"] + (ns16sNonNx50s + structure["Dated"] + structure["Tail"]).first(5)
                built
            }
        end
    end

    # Nx77::getNx77(listings, displayMode, nx77)
    def self.getNx77(listings, displayMode, nx77)
        if nx77 and (Time.new.to_i - nx77["unixtime"]) < Nx77::nx77ExpiryInSeconds() and nx77["nx76"]["ns16s"].size > 0 then
            return nx77
        end
        puts "Compute Nx77 from scratch..."
        { # Nx77
            "unixtime" => Time.new.to_i,
            "nx76"     => Nx77::makeNx76(listings, displayMode)
        }
    end
end

class TerminalDisplayOperator

    # TerminalDisplayOperator::display(displayMode, listings, monitor2, ns16s, nx77)
    def self.display(displayMode, listings, monitor2, ns16s, nx77)

        commandStrWithPrefix = lambda{|ns16, isDefaultItem|
            return "" if !isDefaultItem
            return "" if ns16["commands"].nil?
            return "" if ns16["commands"].empty?
            " (commands: #{ns16["commands"].join(", ")})".yellow
        }

        removeNS16FromNx77 = lambda{|nx77, ns16|
            nx77["nx76"]["ns16s"] = nx77["nx76"]["ns16s"].select{|x| x["uuid"] != ns16["uuid"] }
            nx77
        }

        ns16Originals = ns16s.clone

        system("clear")

        if displayMode == "STREAM" then
            puts "-" * (Utils::screenWidth()-1)
        end

        vspaceleft = Utils::screenHeight()-4

        infolines = [
            "      " + Commands::terminalDisplayCommand(),
            "      " + Commands::makersCommands(),
            "      " + Commands::diversCommands(),
            "      internet on | internet off | require internet"
        ].join("\n").yellow

        vspaceleft = vspaceleft - Utils::verticalSize(infolines)

        store = ItemStore.new()

        if displayMode == "SCREEN" then
            puts ""
            puts Listings::dx(listings).green
            vspaceleft = vspaceleft - 2
        end

        if displayMode == "STREAM" then
            puts Listings::dx(listings).yellow
        end

        if displayMode == "SCREEN" then
            if !InternetStatus::internetIsActive() then
                puts ""
                puts "INTERNET IS OFF".green
                vspaceleft = vspaceleft - 2
            end
        end

        if displayMode == "STREAM" then
            if !InternetStatus::internetIsActive() then
                puts "INTERNET IS OFF".green
            end
        end

        if displayMode == "SCREEN" then
            puts ""
            puts "commands:"
            vspaceleft = vspaceleft - 2
            puts infolines
        end

        if displayMode == "SCREEN" then
            if !monitor2.empty? then
                puts ""
                vspaceleft = vspaceleft - 1
                puts "monitor:"
                monitor2.each{|ns16|
                    line = "(#{store.register(ns16).to_s.rjust(3, " ")}) [#{Time.at(ns16["Nx50"]["unixtime"]).to_s[0, 10]}] #{ns16["announce"]}".yellow
                    puts line
                    vspaceleft = vspaceleft - Utils::verticalSize(line)
                }
            end
        end

        if displayMode == "STREAM" then
            monitor2.each{|ns16|
                puts "monitor: (#{store.register(ns16).to_s.rjust(3, " ")}) [#{Time.at(ns16["Nx50"]["unixtime"]).to_s[0, 10]}] #{ns16["announce"]}".yellow
            }
        end

        if displayMode == "SCREEN" then
            running = BTreeSets::values(nil, "a69583a5-8a13-46d9-a965-86f95feb6f68")
            if running.size > 0 then
                puts ""
                puts "running:"
                vspaceleft = vspaceleft - 2
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
            end
            runningUUIDs = running.map{|item| item["uuid"] }
            ns16Originals
                .select{|ns16| runningUUIDs.include?(ns16["uuid"]) }
                .sort{|t1, t2| t1["uuid"]<=>t2["uuid"] }
                .each{|ns16|
                    indx = store.register(ns16)
                    announce = "(#{"%3d" % indx}) #{ns16["announce"]}#{commandStrWithPrefix.call(ns16, false)}"
                    puts announce
                    vspaceleft = vspaceleft - Utils::verticalSize(announce)
                }
        end

        if displayMode == "STREAM" then
            BTreeSets::values(nil, "a69583a5-8a13-46d9-a965-86f95feb6f68")
                .sort{|t1, t2| t1["unixtime"] <=> t2["unixtime"] } # || 0 because we had some running while updating this
                .each{|nxball|
                    delegate = {
                        "uuid"  => nxball["uuid"],
                        "NS198" => "NxBallDelegate1" 
                    }
                    indx = store.register(delegate)
                    puts "running: (#{"%3d" % indx}) #{nxball["description"]} (#{NxBallsService::runningStringOrEmptyString("", nxball["uuid"], "")})".green
                }
        end

        if displayMode == "SCREEN" then
            catalyst = IO.read("/Users/pascal/Desktop/Catalyst.txt").strip
            if catalyst.size > 0 then
                puts ""
                puts "Catalyst.txt is not empty".green
                vspaceleft = vspaceleft - 2
            end
        end

        if displayMode == "STREAM" then
            if IO.read("/Users/pascal/Desktop/Catalyst.txt").strip.size > 0 then
                puts "Catalyst.txt is not empty".green
            end
        end

        if displayMode == "SCREEN" then
            puts ""
            puts "todo:"
            vspaceleft = vspaceleft - 2
            ns16Originals
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
        end

        if displayMode == "STREAM" then
            ns16Originals
                .each{|ns16|
                    indx = store.register(ns16)
                    isDefaultItem = ((ns16["defaultable"].nil? or ns16["defaultable"]) and store.getDefault().nil?) # the default item is the first element, unless it's defaultable
                    if isDefaultItem then
                        store.registerDefault(ns16)
                    end
                    posStr = isDefaultItem ? "(-->)".green : "(#{"%3d" % indx})"
                    announce = "#{posStr} #{ns16["announce"]}#{commandStrWithPrefix.call(ns16, isDefaultItem)}"
                    puts announce
                }
        end

        if displayMode == "SCREEN" then
            puts ""
        end

        command = LucilleCore::askQuestionAnswerAsString("> ")

        return nx77 if command == ""

        if (unixtime = Utils::codeToUnixtimeOrNull(command.gsub(" ", ""))) then
            if (item = store.getDefault()) then
                DoNotShowUntil::setUnixtime(item["uuid"], unixtime)
                return removeNS16FromNx77.call(nx77, item)
            end
        end

        if (i = Interpreting::readAsIntegerOrNull(command)) then
            item = store.get(i)
            return nx77 if item.nil?
            CentralDispatch::operator1(item, "..")
            return removeNS16FromNx77.call(nx77, item)
        end

        CentralDispatch::operator4(command)
        CentralDispatch::operator5(store.getDefault(), command)
        CentralDispatch::operator1(store.getDefault(), command)

        removeNS16FromNx77.call(nx77, store.getDefault())
    end

    # TerminalDisplayOperator::displayLoop()
    def self.displayLoop()
        initialCodeTrace = Utils::codeTrace()
        nx77 = nil
        loop {
            if Utils::codeTrace() != initialCodeTrace then
                puts "Code change detected"
                break
            end
            displayMode = Listings::getStoredListingOrNull() ? "SCREEN" : "STREAM"
            listings = Listings::getOrderedListingsForTerminalDisplay()
            nx77 = Nx77::getNx77(listings, displayMode, nx77)
            nx77 = TerminalDisplayOperator::display(displayMode, listings, nx77["nx76"]["monitor2"], nx77["nx76"]["ns16s"], nx77)
        }
    end
end
