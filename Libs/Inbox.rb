
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

    # InboxLines::access(item)
    def self.access(item)

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
                "access"   => lambda { InboxLines::access(item) },
                "done"     => lambda { 
                    if LucilleCore::askQuestionAnswerAsBoolean("done: '#{announce}' ? ", true) then
                        CatalystDatabase::delete(uuid) 
                    end
                },
                "inbox-unixtime" => unixtime
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

    # InboxFiles::access(location)
    def self.access(location)

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
                Nx50s::issueNx50UsingInboxLocationInteractive(location)
                LucilleCore::removeFileSystemLocation(location)
                break
            end
        }

        thr.exit

        NxBalls::closeNxBall(nxball, true)
    end

    # InboxFiles::ns16s()
    def self.ns16s()
        InboxFiles::locations().map{|location|
            uuid = "#{Utils::today()}:#{location}"
            {
                "uuid"     => uuid,
                "announce" => "[inbx] file: #{File.basename(location)}",
                "access"   => lambda { InboxFiles::access(location) },
                "done"     => lambda { 
                    if LucilleCore::askQuestionAnswerAsBoolean("done: '#{File.basename(location)}' ? ", true) then
                        LucilleCore::removeFileSystemLocation(location)
                    end
                },
                "inbox-unixtime" => File.mtime(location).to_time.to_i
            }
        }
    end
end


class Inbox

    # Inbox::ns16s()
    def self.ns16s()
        (InboxLines::ns16s() + InboxFiles::ns16s())
            .sort{|i1, i2| i1["inbox-unixtime"] <=> i2["inbox-unixtime"] }
    end
end