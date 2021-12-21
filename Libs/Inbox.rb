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

    # Inbox::probe(location) : "EXIT" | "POSTPONE" | "DESTROYED"
    def self.probe(location)
        loop {
            if File.file?(location) then
                action = LucilleCore::selectEntityFromListOfEntitiesOrNull("action", ["open", "copy to desktop", "postpone", "destroy", "exit (default)"])
                if action.nil? or action == "exit (default)" then
                    return "EXIT" 
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
            else
                system("open '#{location}'")
                action = LucilleCore::selectEntityFromListOfEntitiesOrNull("action", ["dispatch (default)", "postpone", "destroy", "exit (default)"])
                if action.nil? or action == "exit (default)" then
                    return "EXIT" 
                end
                if action == "postpone" then
                    return "POSTPONE"
                end
                if action == "destroy" then
                    LucilleCore::removeFileSystemLocation(location)
                    return "DESTROYED"
                end
            end
        }
    end

    # Inbox::run(location)
    def self.run(location)
        system("clear")
        puts location.green
        command = Inbox::probe(location) # "EXIT" | "POSTPONE" | "DESTROYED"
        if command == "POSTPONE" then
            if (unixtime = Utils::interactivelySelectAUnixtimeOrNull()) then
                DoNotShowUntil::setUnixtime(Inbox::getLocationUUID(location), unixtime)
                return
            end
        end
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
