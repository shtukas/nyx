# encoding: UTF-8

class Inbox

    # Inbox::repository()
    def self.repository()
        "/Users/pascal/Desktop/Inbox"
    end

    # Inbox::getLocationUUID(location)
    def self.getLocationUUID(location)
        uuid = KeyValueStore::getOrNull(nil, "54226eda-9437-4f64-9ab9-7e5141a15471:#{location}")
        return uuid if uuid
        uuid = SecureRandom.uuid
        KeyValueStore::set(nil, "54226eda-9437-4f64-9ab9-7e5141a15471:#{location}", uuid)
        uuid
    end

    # Inbox::interactivelyDecideBestDescriptionForLocation(location)
    def self.interactivelyDecideBestDescriptionForLocation(location)
        description = File.basename(location)
        b1 = LucilleCore::askQuestionAnswerAsBoolean("Do you want to run with description '#{description}' ? ", true)
        return description if b1
        description = nil
        while description.nil? do
            dx = LucilleCore::askQuestionAnswerAsString("description: ")
            if dx.size > 0 then
                description = dx
            end
        end
        description
    end

    # Inbox::access(location)
    def self.access(location)
        system("clear")
        puts location.green
        loop {
            if File.file?(location) then
                action = LucilleCore::selectEntityFromListOfEntitiesOrNull("action", ["open", "copy to desktop", "datecode", "transmute", ">nyx", "destroy", "exit (default)"])
                if action == "open" then
                    system("open '#{location}'")
                end
                if action == "copy to desktop" then
                    FileUtils.cp(location, "/Users/pascal/Desktop")
                end
                if action == "datecode" then
                    unixtime = Utils::interactivelySelectUnixtimeOrNull()
                    next if unixtime.nil?
                    DoNotShowUntil::setUnixtime(Inbox::getLocationUUID(location), unixtime)
                    return
                end
                if action == "transmute" then
                    TerminalUtils::transmutation2(location, "inbox")
                    return
                end
                if action == ">nyx" then
                    NyxAdapter::locationToNyx(location)
                    return
                end
                if action == "destroy" then
                    LucilleCore::removeFileSystemLocation(location)
                    return
                end
                if action.nil? or action == "exit (default)" then
                    return
                end
            else
                action = LucilleCore::selectEntityFromListOfEntitiesOrNull("action", ["open", "datecode", "transmute", ">nyx", "destroy", "exit (default)"])
                if action == "open" then
                    system("open '#{location}'")
                end
                if action == "datecode" then
                    unixtime = Utils::interactivelySelectUnixtimeOrNull()
                    next if unixtime.nil?
                    DoNotShowUntil::setUnixtime(Inbox::getLocationUUID(location), unixtime)
                    return
                end
                if action == "transmute" then
                    TerminalUtils::transmutation2(location, "inbox")
                    return
                end
                if action == ">nyx" then
                    NyxAdapter::locationToNyx(location)
                    return
                end
                if action == "destroy" then
                    LucilleCore::removeFileSystemLocation(location)
                    return
                end
                if action.nil? or action == "exit (default)" then
                    return
                end
            end
        }
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
                    "mikuType"     => "NS16:Inbox1",
                    "unixtime"     => getLocationUnixtime.call(location),
                    "announce"     => announce,
                    "commands"     => ["..", "transmute"],
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
                "lambda"   => lambda { Inbox::access(item) }
            }
        }
    end
end
