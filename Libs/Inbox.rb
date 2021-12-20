# encoding: UTF-8

class Inbox

    # Inbox::repository()
    def self.repository()
        "/Users/pascal/Desktop/Inbox"
    end

    # Inbox::getLocationUUID(location)
    def self.getLocationUUID(location)
        uuid = KeyValueStore::getOrNull(nil, "54226eda-9437-4f64-9ab9-7e5141a15471:#{location}")
        return uuid.to_f if uuid
        uuid = SecureRandom.uuid
        KeyValueStore::set(nil, "54226eda-9437-4f64-9ab9-7e5141a15471:#{location}", uuid)
        uuid
    end

    # Inbox::probe(location) : "EXIT" | "POSTPONE" | "DISPATCH" | "DESTROYED"
    def self.probe(location)
        loop {
            if File.file?(location) then
                action = LucilleCore::selectEntityFromListOfEntitiesOrNull("action", ["open", "copy to desktop", "dispatch (default)", "postpone", "destroy", "exit"])
                if action.nil? or action == "dispatch (default)" then
                    return "DISPATCH" 
                end
                if action == "open" then
                    system("open '#{location}'")
                end
                if action == "postpone" then
                    return "POSTPONE"
                end
                if action == "copy to desktop" then
                    FileUtils.cp(location, "/Users/pascal/Desktop")
                end
                if action == "destroy" then
                    LucilleCore::removeFileSystemLocation(location)
                    return "DESTROYED"
                end
                if action == "exit" then
                    return "EXIT"
                end
            else
                system("open '#{location}'")
                action = LucilleCore::selectEntityFromListOfEntitiesOrNull("action", ["dispatch (default)", "postpone", "destroy", "exit"])
                if action.nil? or action == "dispatch (default)" then
                    return "DISPATCH" 
                end
                if action == "postpone" then
                    return "POSTPONE"
                end
                if action == "destroy" then
                    LucilleCore::removeFileSystemLocation(location)
                    return "DESTROYED"
                end
                if action == "exit" then
                    return "EXIT"
                end
            end
        }
    end

    # Inbox::dispatch(location)
    def self.dispatch(location)
        locationToDescription = lambda{|location|
            description = File.basename(location)
            puts "description: #{description}"
            d = LucilleCore::askQuestionAnswerAsString("description (empty to ignore step) : ")
            if d.size > 0 then
                description = d
            end
            description
        }
        description = locationToDescription.call(location)
        listing = Listings::interactivelySelectListing()
        Nx50s::issueInboxItemUsingLocation(location, listing, description)
        LucilleCore::removeFileSystemLocation(location)
        listing
    end

    # Inbox::run(location)
    def self.run(location)
        time1 = Time.new.to_f

        close = lambda{|time1, listing|
            account = Listings::listingToBankAccount(listing)
            time2 = Time.new.to_f
            timespan = time2 - time1
            puts "Putting #{timespan} seconds into #{account}"
            Bank::put(account, timespan)
        }

        selectListingInteractivelyOrDefaultIfSmallTime = lambda{|time1|
            return "EVA" if (Time.new.to_f - time1) < 120
            Listings::interactivelySelectListing()
        }

        system("clear")
        puts location.green

        command = Inbox::probe(location) # "EXIT" | "POSTPONE" | "DISPATCH" | "DESTROYED"

        if command == "EXIT" then
            close.call(time1, selectListingInteractivelyOrDefaultIfSmallTime.call(time1))
            return
        end

        if command == "POSTPONE" then
            if (unixtime = Utils::interactivelySelectAUnixtimeOrNull()) then
                DoNotShowUntil::setUnixtime(Inbox::getLocationUUID(location), unixtime)
                return
            end
        end

        if command == "DISPATCH" then
            listing = Inbox::dispatch(location)
            close.call(time1, listing)
            return
        end

        if command == "DESTROYED" then
            close.call(time1, selectListingInteractivelyOrDefaultIfSmallTime.call(time1))
            return
        end

        listing = Inbox::dispatch(location)
        close.call(time1, listing)
    end

    # Inbox::ns16s()
    def self.ns16s()

        getLocationUnixtime = lambda{|location|
            unixtime = KeyValueStore::getOrNull(nil, "54226eda-9437-4f64-9ab9-7e5141a15471:#{location}")
            return unixtime.to_f if unixtime
            unixtime = Time.new.to_f
            KeyValueStore::set(nil, "54226eda-9437-4f64-9ab9-7e5141a15471:#{location}", unixtime)
            unixtime
        }

        getOrdinal = lambda {|location|
            ordinal = KeyValueStore::getOrNull(nil, "c22e3e76-d3af-4b69-aa45-24e4a2d6ebec:#{location}")
            return ordinal.to_f if ordinal
            ordinal = Nx50s::ordinalBetween10thAnd20th()
            KeyValueStore::set(nil, "c22e3e76-d3af-4b69-aa45-24e4a2d6ebec:#{location}", ordinal)
            ordinal
        }

        LucilleCore::locationsAtFolder(Inbox::repository())
            .map{|location|
                if File.basename(location).include?("'") then
                    location2 = "#{File.dirname(location)}/#{File.basename(location).gsub("'", "")}"
                    puts "Inbox renaming:"
                    puts "    #{location}"
                    puts "    #{location2}"
                    FileUtils.mv(location, location2)
                    location = location2
                end
                announce = "[inbx] #{File.basename(location)}"
                {
                    "uuid"         => Inbox::getLocationUUID(location),
                    "NS198"        => "ns16:inbox1",
                    "unixtime"     => getLocationUnixtime.call(location),
                    "announce"     => announce,
                    "ordinal"      => getOrdinal.call(location),
                    "commands"     => ["..", ">> (dispatch)"],
                    "location"     => location
                }
            }
            .sort{|i1, i2| i1["unixtime"] <=> i2["unixtime"] }
    end

    # Inbox::nx19s()
    def self.nx19s()
        Inbox::ns16s().map{|item|
            {
                "uuid"     => item["uuid"],
                "announce" => item["announce"],
                "lambda"   => lambda { Inbox::run(item) }
            }
        }
    end
end
