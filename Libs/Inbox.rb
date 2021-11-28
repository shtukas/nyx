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

    # Inbox::run(location)
    def self.run(location)
        time1 = Time.new.to_f

        domain = nil

        system("clear")
        puts location.green

        # -------------------------------------
        # Lookup
        if File.file?(location) then
            action = LucilleCore::selectEntityFromListOfEntitiesOrNull("action", ["open", "copy to desktop", "next step (default)"])
            if action == "open" then
                system("open '#{location}'")
            end
            if action == "copy to desktop" then
                FileUtils.cp(location, "/Users/pascal/Desktop")
            end
        else
            system("open '#{location}'")
        end

        # -------------------------------------
        # Dispatch

        locationToDescription = lambda{|location|
            description = File.basename(location)
            puts "description: #{description}"
            d = LucilleCore::askQuestionAnswerAsString("description (empty to ignore step) : ")
            if d.size > 0 then
                description = d
            end
            description
        }

        action = LucilleCore::selectEntityFromListOfEntitiesOrNull("action", ["delete", "dispatch"])
        return if action.nil?

        if action == "delete" then
            LucilleCore::removeFileSystemLocation(location)
            Mercury::postValue("A4EC3B4B-NATHALIE-COLLECTION-REMOVE", Inbox::getLocationUUID(location))
        end
        
        if action == "dispatch" then
            target = LucilleCore::selectEntityFromListOfEntitiesOrNull("target", ["todo"])
            if target == "todo" then
                domain = Domain::interactivelySelectDomain()
                Nx50s::issueItemUsingLocation(location, domain)
                LucilleCore::removeFileSystemLocation(location)
                Mercury::postValue("A4EC3B4B-NATHALIE-COLLECTION-REMOVE", Inbox::getLocationUUID(location))
            end
        end

        if domain.nil? then 
            domain = Domain::interactivelySelectDomain()
        end
        account = Domain::domainToBankAccount(domain)
        time2 = Time.new.to_f
        timespan = time2 - time1
        puts "Putting #{timespan} seconds into #{account}"
        Bank::put(account, timespan)
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
                    "commands"     => [".."],
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
