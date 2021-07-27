
# encoding: UTF-8

class InboxLines

    # InboxLines::ns16s()
    def self.ns16s()
        BTreeSets::values(nil, "e1a10102-9e16-4ae9-af66-1a72bae89df2")
            .map{|item|
                {
                    "uuid"     => "#{Utils::today()}:#{item["uuid"]}",
                    "announce" => "[inbx] line: #{item["description"]}",
                    "access"   => lambda {
                        nxball = BankExtended::makeNxBall(["Nx60-69315F2A-BE92-4874-85F1-54F140E3B243"])
                        thr = Thread.new {
                            loop {
                                sleep 60
                                if (Time.new.to_i - nxball["cursorUnixtime"]) >= 600 then
                                    nxball = BankExtended::upgradeNxBall(nxball, false)
                                end
                            }
                        }

                        system("clear")

                        puts "[inbox] line: #{item["description"]}".green

                        LucilleCore::pressEnterToContinue()

                        if LucilleCore::askQuestionAnswerAsBoolean("done '#{item["description"]}' ? ") then
                            BTreeSets::destroy(nil, "e1a10102-9e16-4ae9-af66-1a72bae89df2", item["uuid"])
                        else
                            Nx50s::issueNx50UsingTextInteractive(item["description"])
                            BTreeSets::destroy(nil, "e1a10102-9e16-4ae9-af66-1a72bae89df2", item["uuid"])
                        end
                        thr.exit
                        BankExtended::closeNxBall(nxball, true)
                    },
                    "done"   => lambda {
                        BTreeSets::destroy(nil, "e1a10102-9e16-4ae9-af66-1a72bae89df2", item["uuid"])
                    },
                    "domain"               => nil,
                    "isInbox"              => true,
                    "isInboxText"          => true,
                    "dispatch-uuid"        => item["uuid"],
                    "dispatch-description" => item["description"],
                    "inbox-unixtime"       => item["unixtime"]
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

        nxball = BankExtended::makeNxBall(["Nx60-69315F2A-BE92-4874-85F1-54F140E3B243"])

        thr = Thread.new {
            loop {
                sleep 60
                if (Time.new.to_i - nxball["cursorUnixtime"]) >= 600 then
                    nxball = BankExtended::upgradeNxBall(nxball, false)
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

        LucilleCore::pressEnterToContinue()

        if LucilleCore::askQuestionAnswerAsBoolean("done? : ") then
            LucilleCore::removeFileSystemLocation(location)
        else
            Nx50s::issueNx50UsingLocationInteractive(location)
            LucilleCore::removeFileSystemLocation(location)
        end

        thr.exit

        BankExtended::closeNxBall(nxball, true)
    end

    # InboxFiles::ns16s()
    def self.ns16s()
        InboxFiles::locations().map{|location|
            {
                "uuid"     => "#{Utils::today()}:#{location}",
                "announce" => "[inbx] file: #{File.basename(location)}",
                "access"   => lambda { InboxFiles::access(location) },
                "done"     => lambda { LucilleCore::removeFileSystemLocation(location) },
                "domain"   => nil,
                "isInbox"              => true,
                "isInboxFile"          => true,
                "dispatch-location"    => location,
                "inbox-unixtime"       => File.mtime(location).to_time.to_i
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