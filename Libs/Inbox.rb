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

    # Inbox::landingInbox1(location)
    def self.landingInbox1(location)
        system("clear")
        puts location.green
        loop {

            actions = 
                if File.file?(location) then
                    ["open", "copy to desktop", "datecode", "transmute", ">nyx", "destroy", "exit (default)"]
                else
                    ["open", "datecode", "transmute", ">nyx", "destroy", "exit (default)"]
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
                puts "(19f8c2ce-a9b6-44b1-8a37-3d734aa282b7: This has not been implemented, need re-implementation after refactoring)"
                LucilleCore::pressEnterToContinue()
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
                    "height"       => Heights::height1("beca7cc9", uuid),
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
                "height"   => Heights::height1("141de8cf", uuid),
                "item"     => item
            }
        }
    end

    # Inbox::landingInbox2(item)
    def self.landingInbox2(item)
        puts item["line"]
        if item["aionrootnhash"] then
            AionCore::exportHashAtFolder(InfinityElizabeth_InfinityBufferOutAndXCache_XCacheLookupThenDriveLookupWithLocalXCaching.new(), item["aionrootnhash"], "/Users/pascal/Desktop")
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
