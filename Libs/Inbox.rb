# encoding: UTF-8

class Inbox

    # --------------------------------------------------------------------------
    # Desktop Functions

    # Inbox::repository()
    def self.repository()
        "/Users/pascal/Desktop/Inbox"
    end

    # Inbox::getLocationUUID(location)
    def self.getLocationUUID(location)
        uuid = XCache::getOrNull("54226eda-9437-4f64-9ab9-7e5141a15471:#{location}")
        return uuid if uuid
        uuid = SecureRandom.uuid
        XCache::set("54226eda-9437-4f64-9ab9-7e5141a15471:#{location}", uuid)
        uuid
    end

    # Inbox::interactivelyDecideBestDescriptionForLocation(location)
    def self.interactivelyDecideBestDescriptionForLocation(location)
        description = File.basename(location)
        description2 = LucilleCore::askQuestionAnswerAsString("New description (if needed, otherwise empty for default): ")
        if description2 != "" then
            description = description2
        end
        description
    end

    # Inbox::landingInbox1(location)
    def self.landingInbox1(location)
        system("clear")
        Sx01Snapshots::printSnapshotDeploymentStatusIfRelevant()
        puts location.green
        loop {

            actions = 
                if File.file?(location) then
                    ["open", "copy to desktop", "datecode", ">todo", ">fyre", ">nyx", "destroy", "exit (default)"]
                else
                    ["open", "datecode", ">todo", ">fyre", ">nyx", "destroy", "exit (default)"]
                end

            action = LucilleCore::selectEntityFromListOfEntitiesOrNull("action", actions)
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
            if action == ">todo" then
                Transmutation::transmutation1(location, "inbox", "TxTodo")
                return
            end
            if action == ">fyre" then
                Transmutation::transmutation1(location, "inbox", "TxFyre")
                return
            end
            if action == ">nyx" then
                Transmutation::transmutation1(location, "inbox", "Nx100")
                return
            end
            if action == "destroy" then
                LucilleCore::removeFileSystemLocation(location)
                return
            end
            if action.nil? or action == "exit (default)" then
                return
            end
        }
    end

    # Inbox::inboxDesktopNS16s()
    def self.inboxDesktopNS16s()

        getLocationUnixtime = lambda{|location|
            unixtime = XCache::getOrNull("54226eda-9437-4f64-9ab9-7e5141a15471:#{location}")
            return unixtime.to_f if unixtime
            unixtime = Time.new.to_f
            XCache::set("54226eda-9437-4f64-9ab9-7e5141a15471:#{location}", unixtime)
            unixtime
        }

        if !File.exists?(Inbox::repository()) then
            # Added to simplify the Desktop during the aion techtime
            return []
        end

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
                uuid = Inbox::getLocationUUID(location)
                {
                    "uuid"         => uuid,
                    "mikuType"     => "NS16:Inbox1",
                    "unixtime"     => getLocationUnixtime.call(location),
                    "announce"     => announce,
                    "location"     => location
                }
            }
            .sort{|i1, i2| i1["unixtime"] <=> i2["unixtime"] }
    end

    # --------------------------------------------------------------------------
    # TxInbox2 Functions

    # Inbox::txInbox2NS16s()
    def self.txInbox2NS16s()
        Librarian6ObjectsLocal::getObjectsByMikuType("TxInbox2").map{|item|
            uuid = item["uuid"]
            {
                "uuid"     => uuid,
                "mikuType" => "NS16:TxInbox2",
                "unixtime" => item["unixtime"],
                "announce" => "(inbox) #{item["line"]}",
                "item"     => item
            }
        }
    end

    # Inbox::landingInbox2(item)
    def self.landingInbox2(item)
        Sx01Snapshots::printSnapshotDeploymentStatusIfRelevant()
        puts item["line"]
        if item["aionrootnhash"] then
            AionCore::exportHashAtFolder(InfinityElizabeth_XCacheAndInfinityBufferOut_ThenDriveLookupWithLocalXCaching.new(), item["aionrootnhash"], "/Users/pascal/Desktop")
        end
        action = LucilleCore::selectEntityFromListOfEntitiesOrNull("action", ["exit (default)", "destroy"])
        if action.nil? or action == "exit" then
            return
        end
        if action == "destroy" then
            Librarian6ObjectsLocal::destroy(item["uuid"])
            return
        end
    end

    # --------------------------------------------------------------------------
    # Common Interface

    # Inbox::ns16s()
    def self.ns16s()
        (Inbox::txInbox2NS16s()+Inbox::inboxDesktopNS16s())
            .sort{|i1, i2| i1["unixtime"] <=> i2["unixtime"] }
    end
end
