
# encoding: UTF-8

class InboxLines

    # InboxLines::ns16s()
    def self.ns16s()
        BTreeSets::values(nil, "e1a10102-9e16-4ae9-af66-1a72bae89df2")
            .map{|item|
                {
                    "uuid"     => SecureRandom.hex, # Inbox items can't be DoNotDisplayUntil'ed
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

                        puts "[inbox] #{item["description"]}".green

                        LucilleCore::pressEnterToContinue()

                        if LucilleCore::askQuestionAnswerAsBoolean("done '#{item["description"]}' ? ") then
                            BTreeSets::destroy(nil, "e1a10102-9e16-4ae9-af66-1a72bae89df2", item["uuid"])
                        else
                            nx50 = Nx50s::issueNx50UsingTextInteractive(item["description"])
                            domain = Domains::selectDomainOrNull()
                            if domain then
                                Domains::setDomainForItem(nx50["uuid"], domain["uuid"])
                            end
                            nx50["unixtime"] = (Nx50s::interactivelyDetermineNewItemUnixtimeOrNull() || Time.new.to_f)
                            CoreDataTx::commit(nx50)
                        end
                        thr.exit
                        BankExtended::closeNxBall(nxball, true)
                    },
                    "done"     => lambda {
                        BTreeSets::destroy(nil, "e1a10102-9e16-4ae9-af66-1a72bae89df2", item["uuid"])
                    },
                    "domainuuid" => nil
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

        puts "[inbox] #{location}".green

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
            nx50 = Nx50s::issueNx50UsingLocation(location)
            domain = Domains::selectDomainOrNull()
            if domain then
                Domains::setDomainForItem(nx50["uuid"], domain["uuid"])
            end
            nx50["unixtime"] = (Nx50s::interactivelyDetermineNewItemUnixtimeOrNull() || Time.new.to_f)
            CoreDataTx::commit(nx50)
            LucilleCore::removeFileSystemLocation(location)
        end

        thr.exit

        BankExtended::closeNxBall(nxball, true)
    end

    # InboxFiles::ns16s()
    def self.ns16s()
        InboxFiles::locations().map{|location|
            {
                "uuid"       => SecureRandom.hex, # Inbox items can't be DoNotDisplayUntil'ed
                "announce"   => "[inbx] file: #{File.basename(location)}",
                "access"     => lambda { InboxFiles::access(location) },
                "done"       => lambda { LucilleCore::removeFileSystemLocation(location) },
                "domainuuid" => nil
            }
        }
    end
end
