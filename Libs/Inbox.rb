
# encoding: UTF-8

=begin

{
    "uuid"         => String
    "unixtime"     => Float
    "description"  => String
    "catalystType" => "inbox"

    "payload1" :
    "payload2" :
    "payload3" :
}

=end

class InboxLines

    # InboxLines::inboxLines()
    def self.inboxLines()
        CatalystDatabase::getItemsByCatalystType("inbox")
    end

    # InboxLines::landing(item)
    def self.landing(item)

        uuid = item["uuid"]
        description = item["description"]

        nxball = NxBalls::makeNxBall(["Nx60-69315F2A-BE92-4874-85F1-54F140E3B243"])
        thr = Thread.new {
            loop {
                sleep 60
                if (Time.new.to_i - nxball["cursorUnixtime"]) >= 600 then
                    nxball = NxBalls::upgradeNxBall(nxball, false)
                end
            }
        }

        system("clear")

        puts "[inbox] #{description}".green
        puts "Started at: #{Time.new.to_s}".yellow

        puts ""

        loop {

            puts "done | dispatch".yellow

            command = LucilleCore::askQuestionAnswerAsString("> ")

            if command == "done" then
                CatalystDatabase::delete(uuid)
                break
            end

            if command == "dispatch" then
                domain = LucilleCore::selectEntityFromListOfEntitiesOrNull("domain", ["Nx50s", "Nx51s"])
                return if domain.nil?
                if domain == "Nx50s" then
                    Nx50s::issueNx50UsingInboxLineInteractive(description)
                    CatalystDatabase::delete(uuid)
                    break
                end
                if domain == "Nx51s" then
                    Nx51s::issueNx51UsingInboxLineInteractive(description)
                    CatalystDatabase::delete(uuid)
                    break
                end
            end
        }

        thr.exit
        NxBalls::closeNxBall(nxball, true)
    end

    # InboxLines::issueNewLine(description)
    def self.issueNewLine(description)
        uuid         = SecureRandom.uuid
        unixtime     = Time.new.to_f
        catalystType = "inbox"
        payload1     = nil
        payload2     = nil 
        payload3     = nil
        CatalystDatabase::insertItem(uuid, unixtime, description, catalystType, payload1, payload2, payload3, nil, nil)
    end

    # InboxLines::ns16s()
    def self.ns16s()
        CatalystDatabase::getItemsByCatalystType("inbox").map{|item|
            uuid = item["uuid"]
            announce = "[inbx] #{item["description"]}"
            unixtime = item["unixtime"]
            {
                "uuid"     => uuid,
                "announce" => announce,
                "unixtime" => unixtime,
                "metric"   => 0,
                "commands" => ["landing", "done"],
                "interpreter" => lambda {|command|
                    if command == "landing" then
                        InboxLines::landing(item)
                    end
                    if command == "done" then
                        if LucilleCore::askQuestionAnswerAsBoolean("done: '#{announce}' ? ", true) then
                            CatalystDatabase::delete(uuid) 
                        end
                    end
                }
            }
        }
    end
end

=begin

InboxTextItem {
    "uuid"        => String
    "index"       => Integer
    "unixtime"    => Integer
    "description" => String
    "text"        => Float
}

=end

class InboxText

    # InboxText::getItemAtIndexOrNull(indx)
    def self.getItemAtIndexOrNull(indx)
        item = KeyValueStore::getOrNull(nil, "62f86cdb-0f43-4427-96c7-644cb26193c3:#{indx}")
        return nil if item.nil?
        JSON.parse(item)
    end

    # InboxText::commitItemToDisk(item)
    def self.commitItemToDisk(item)
        KeyValueStore::set(nil, "62f86cdb-0f43-4427-96c7-644cb26193c3:#{item["index"]}", JSON.generate(item))
    end

    # InboxText::delete(indx)
    def self.delete(indx)
        KeyValueStore::destroy(nil, "62f86cdb-0f43-4427-96c7-644cb26193c3:#{indx}")
    end

    # InboxText::items()
    def self.items()
        (1..10).map{|indx| InboxText::getItemAtIndexOrNull(indx) }.compact
    end

    # InboxText::landing(item)
    def self.landing(item)

        uuid = item["uuid"]
        description = item["description"]

        nxball = NxBalls::makeNxBall(["Nx60-69315F2A-BE92-4874-85F1-54F140E3B243"])
        thr = Thread.new {
            loop {
                sleep 60
                if (Time.new.to_i - nxball["cursorUnixtime"]) >= 600 then
                    nxball = NxBalls::upgradeNxBall(nxball, false)
                end
            }
        }

        loop {

            system("clear")

            puts ""

            puts "Inbox Text -------------------"
            puts description.green
            puts item["text"].green
            puts "------------------------------"

            puts ""

            puts "done | edit | dispatch".yellow

            command = LucilleCore::askQuestionAnswerAsString("> ")

            if command == "done" then
                InboxText::delete(item["index"])
                break
            end

            if command == "edit" then
                item["text"] = Utils::editTextSynchronously(item["text"])
                InboxText::commitItemToDisk(item)
                next
            end

            if command == "dispatch" then
                domain = LucilleCore::selectEntityFromListOfEntitiesOrNull("domain", ["Nx50s", "Nx51s"])
                return if domain.nil?
                if domain == "Nx50s" then
                    Nx50s::issueNx50UsingInboxText(item)
                    InboxText::delete(item["index"])
                    break
                end
                if domain == "Nx51s" then
                    Nx51s::issueNx51UsingInboxText(item)
                    InboxText::delete(item["index"])
                    break
                end
            end
        }

        thr.exit
        NxBalls::closeNxBall(nxball, true)
    end

    # InboxText::issueNewText()
    def self.issueNewText()
        indx = ((1..10).to_a - InboxText::items().map{|item| item["index"] }).first
        if indx.nil? then
            puts "Too many texts"
            LucilleCore::pressEnterToContinue()
            return
        end
        item = {
            "uuid"        => SecureRandom.hex,
            "index"       => indx,
            "unixtime"    => Time.new.to_i,
            "description" => LucilleCore::askQuestionAnswerAsString("description: "),
            "text"        => Utils::editTextSynchronously("")
        }
        InboxText::commitItemToDisk(item)
    end

    # InboxText::ns16s()
    def self.ns16s()
        InboxText::items().map{|item|
            uuid = item["uuid"]
            announce = "[inbx] (text) #{item["description"]}"
            unixtime = item["unixtime"]
            {
                "uuid"     => uuid,
                "announce" => announce,
                "unixtime" => unixtime,
                "metric"   => 0,
                "commands" => ["access", "done"],
                "interpreter" => lambda {|command|
                    if command == "access" then
                        InboxText::landing(item)
                    end
                    if command == "done" then
                        if LucilleCore::askQuestionAnswerAsBoolean("done: '#{announce}' ? ", true) then
                            InboxText::delete(item["index"]) 
                        end
                    end
                }
            }
        }
    end
end

class InboxFiles

    # InboxFiles::repositoryFolderpath()
    def self.repositoryFolderpath()
        "/Users/pascal/Desktop/Inbox"
    end

    # InboxFiles::locations()
    def self.locations()
        LucilleCore::locationsAtFolder(InboxFiles::repositoryFolderpath())
    end

    # InboxFiles::landing(location)
    def self.landing(location)

        uuid = "#{location}:#{Utils::today()}"

        nxball = NxBalls::makeNxBall(["Nx60-69315F2A-BE92-4874-85F1-54F140E3B243"])

        thr = Thread.new {
            loop {
                sleep 60
                if (Time.new.to_i - nxball["cursorUnixtime"]) >= 600 then
                    nxball = NxBalls::upgradeNxBall(nxball, false)
                end

                if (Time.new.to_i - nxball["startUnixtime"]) >= 3600 then
                    Utils::onScreenNotification("Catalyst", "Inbox item running for more than an hour")
                end
            }
        }

        system("clear")

        puts "[inbox] file: #{location}".green

        if location.include?("'") then
            puts "Looking at: #{location}"
            if LucilleCore::askQuestionAnswerAsBoolean("remove quote ? ", true) then
                location2 = location.gsub("'", "-")
                FileUtils.mv(location, location2)
                location = location2
            end
        end

        if !location.include?("'") then
            system("open '#{location}'")
        end

        puts ""

        loop {

            puts "done | dispatch".yellow

            command = LucilleCore::askQuestionAnswerAsString("> ")

            if command == "done" then
                LucilleCore::removeFileSystemLocation(location)
                break
            end

            if command == "dispatch" then

                domain = LucilleCore::selectEntityFromListOfEntitiesOrNull("domain", ["Nx50s", "Nx51s"])
                return if domain.nil?
                if domain == "Nx50s" then
                    Nx50s::issueNx50UsingInboxLocationInteractive(location)
                    LucilleCore::removeFileSystemLocation(location)
                    break
                end
                if domain == "Nx51s" then
                    Nx51s::issueNx51UsingInboxLocationInteractive(location)
                    LucilleCore::removeFileSystemLocation(location)
                    break
                end
                break
            end
        }

        thr.exit

        NxBalls::closeNxBall(nxball, true)
    end

    # InboxFiles::ns16s()
    def self.ns16s()
        InboxFiles::locations()
            .map{|location|
                uuid = "#{Utils::today()}:#{location}"
                {
                    "uuid"     => uuid,
                    "announce" => "[inbx] file: #{File.basename(location)}",
                    "unixtime" => File.mtime(location).to_time.to_i,
                    "metric"   => 0,
                    "interpreter" => lambda {|command|
                        if command == "access" then
                            InboxFiles::landing(location)
                        end
                        if command == "done" then
                            if LucilleCore::askQuestionAnswerAsBoolean("done: '#{File.basename(location)}' ? ", true) then
                                LucilleCore::removeFileSystemLocation(location)
                            end
                        end
                    }
                }
            }
            .select{|item| DoNotShowUntil::isVisible(item["uuid"]) }
    end
end

class Inbox

    # Inbox::ns16s()
    def self.ns16s()
        (InboxLines::ns16s() + InboxFiles::ns16s() + InboxText::ns16s() )
            .sort{|i1, i2| i1["unixtime"] <=> i2["unixtime"] }
    end
end