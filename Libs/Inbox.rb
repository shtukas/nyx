
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

    # InboxLines::dispatch(item)
    def self.dispatch(item)
        domain = LucilleCore::selectEntityFromListOfEntitiesOrNull("domain", ["Nx25s", "Nx51s"])
        return if domain.nil?
        if domain == "Nx25s" then
            Nx25s::issueNx25UsingInboxLineInteractive(item["description"])
            CatalystDatabase::delete(item["uuid"])
        end
        if domain == "Nx51s" then
            Nx51s::issueNx51UsingInboxLineInteractive(item["description"])
            CatalystDatabase::delete(item["uuid"])
        end
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

    # InboxLines::arrows(item)
    def self.arrows(item)
        uuid = item["uuid"]
        description = item["description"]
        puts "[inbox] #{description}".green
        puts "Started at: #{Time.new.to_s}".yellow
        nxball = NxBalls::makeNxBall(["Nx60-69315F2A-BE92-4874-85F1-54F140E3B243"])
        thr = Thread.new {
            loop {
                sleep 60
                if (Time.new.to_i - nxball["cursorUnixtime"]) >= 600 then
                    nxball = NxBalls::upgradeNxBall(nxball, false)
                end
            }
        }

        LucilleCore::pressEnterToContinue()

        thr.exit

        options = ["done", "dispatch"]
        option = LucilleCore::selectEntityFromListOfEntitiesOrNull("option", options)
        NxBalls::closeNxBall(nxball, true)

        if option == "done" then
            CatalystDatabase::delete(uuid) 
        end
        if option == "dispatch" then
            InboxLines::dispatch(item)
        end
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
                "commands" => [">>", "done", "dispatch"],
                "interpreter" => lambda {|command|
                    if command == ">>" then
                        InboxLines::arrows(item)
                    end
                    if command == "done" then
                        if LucilleCore::askQuestionAnswerAsBoolean("done: '#{announce}' ? ", true) then
                            CatalystDatabase::delete(uuid) 
                        end
                    end
                    if command == "dispatch" then
                        InboxLines::dispatch(item)
                    end
                },
                "selected" => lambda {
                    InboxLines::arrows(item)
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

    # InboxText::dispatch(item)
    def self.dispatch(item)
        domain = LucilleCore::selectEntityFromListOfEntitiesOrNull("domain", ["Nx50s", "Nx51s"])
        return if domain.nil?
        if domain == "Nx50s" then
            Nx25s::issueNx25UsingInboxText(item)
            InboxText::delete(item["index"])
        end
        if domain == "Nx51s" then
            Nx51s::issueNx51UsingInboxText(item)
            InboxText::delete(item["index"])
        end
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

    # InboxText::arrows(item)
    def self.arrows(item)
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
            puts "Text -------------------------"
            puts description.green
            puts ""
            puts item["text"].green
            puts "------------------------------"

            LucilleCore::pressEnterToContinue()

            thr.exit

            options = ["edit", "done", "dispatch"]
            option = LucilleCore::selectEntityFromListOfEntitiesOrNull("option", options)
            NxBalls::closeNxBall(nxball, true)

            if option == "edit" then
                item["text"] = Utils::editTextSynchronously(item["text"])
                InboxText::commitItemToDisk(item)
                next
            end
            if option == "done" then
                InboxText::delete(item["index"])
                break
            end
            if option == "dispatch" then
                InboxText::dispatch(item)
                break
            end
        }
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
                "commands" => [">>", "done", "dispatch"],
                "interpreter" => lambda {|command|
                    if command == ">>" then
                        InboxText::arrows(item)
                    end
                    if command == "done" then
                        if LucilleCore::askQuestionAnswerAsBoolean("done: '#{announce}' ? ", true) then
                            InboxText::delete(item["index"]) 
                        end
                    end
                    if command == "dispatch" then
                        InboxText::dispatch(item)
                    end
                },
                "selected" => lambda {
                    InboxText::arrows(item)
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

    # InboxFiles::dispatch(location)
    def self.dispatch(location)
        domain = LucilleCore::selectEntityFromListOfEntitiesOrNull("domain", ["Nx50s", "Nx51s"])
        return if domain.nil?
        if domain == "Nx25s" then
            Nx25s::issueNx25UsingInboxLocationInteractive(location)
            LucilleCore::removeFileSystemLocation(location)
        end
        if domain == "Nx51s" then
            Nx51s::issueNx51UsingInboxLocationInteractive(location)
            LucilleCore::removeFileSystemLocation(location)
        end
    end

    # InboxFiles::arrows(location)
    def self.arrows(location)
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

        LucilleCore::pressEnterToContinue()

        thr.exit

        options = ["done", "dispatch"]
        option = LucilleCore::selectEntityFromListOfEntitiesOrNull("option", options)
        NxBalls::closeNxBall(nxball, true)

        if option == "done" then
            LucilleCore::removeFileSystemLocation(location)
        end

        if option == "dispatch" then
            InboxFiles::dispatch(location)
        end
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
                    "commands" => [">>", "done", "dispatch"],
                    "interpreter" => lambda {|command|
                        if command == ">>" then
                            InboxFiles::arrows(location)
                        end
                        if command == "done" then
                            if LucilleCore::askQuestionAnswerAsBoolean("done: '#{File.basename(location)}' ? ", true) then
                                LucilleCore::removeFileSystemLocation(location)
                            end
                        end
                        if command == "dispatch" then
                            InboxFiles::dispatch(location)
                        end
                    },
                    "selected" => lambda {
                        InboxFiles::arrows(location)
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

    # Inbox::nx19s()
    def self.nx19s()
        Inbox::ns16s().map{|ns16|
            {
                "uuid"     => ns16["uuid"],
                "announce" => ns16["announce"],
                "lambda"   => lambda { ns16["selected"].call() }
            }
        }
    end
end
