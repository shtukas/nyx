
# encoding: UTF-8

class InboxLines

    # InboxLines::ns16s()
    def self.ns16s()
        BTreeSets::values(nil, "e1a10102-9e16-4ae9-af66-1a72bae89df2")
            .map{|item|
                {
                    "uuid"     => item["uuid"],
                    "announce" => "[item] #{item["description"]}",
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
                        if LucilleCore::askQuestionAnswerAsBoolean("done '#{item["description"]}' ? ") then
                            BTreeSets::destroy(nil, "e1a10102-9e16-4ae9-af66-1a72bae89df2", item["uuid"])
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

    # InboxFiles::getDescriptionOrNull(location)
    def self.getDescriptionOrNull(location)
        return nil if !File.exists?(location)
        KeyValueStore::getOrNull(nil, "ca23acc1-6596-4e8e-b9e7-714ae3c7b0f8:#{location}")
    end

    # InboxFiles::setDescription(location, description)
    def self.setDescription(location, description)
        KeyValueStore::set(nil, "ca23acc1-6596-4e8e-b9e7-714ae3c7b0f8:#{location}", description)
    end

    # InboxFiles::announce(location)
    def self.announce(location)
        description = InboxFiles::getDescriptionOrNull(location)
        if description then
            "[inbx] #{description}"
        else
            "[inbx] #{File.basename(location)}"
        end
    end

    # InboxFiles::ensureDescription(location)
    def self.ensureDescription(location)
        if InboxFiles::getDescriptionOrNull(location).nil? then
            description = LucilleCore::askQuestionAnswerAsString("description: ")
            InboxFiles::setDescription(location, description)
        end
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
            }
        }

        loop {

            system("clear")

            break if !File.exist?(location)

            puts location.yellow

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

            puts "done | open | <datecode> | >nx50s (move to nx50) | exit".yellow
            command = LucilleCore::askQuestionAnswerAsString("> ")
        
            break if command == "exit"

            if Interpreting::match("done", command) then
                LucilleCore::removeFileSystemLocation(location)
                break
            end

            if Interpreting::match("open", command) then
                system("open '#{location}'")
                break
            end

            if command == "++" then
                DoNotShowUntil::setUnixtime(uuid, Time.new.to_i+3600)
                break
            end

            if (unixtime = Utils::codeToUnixtimeOrNull(command.gsub(" ", ""))) then
                DoNotShowUntil::setUnixtime(uuid, unixtime)
                break
            end

            if Interpreting::match(">nx50s", command) then
                nx50 = Nx50s::issueNx50UsingLocation(location)
                nx50["unixtime"] = (Nx50s::interactivelyDetermineNewItemUnixtimeOrNull() || Time.new.to_f)
                CoreDataTx::commit(nx50)
                LucilleCore::removeFileSystemLocation(location)
                break
            end
        }

        if File.exists?(location) and InboxFiles::getDescriptionOrNull(location).nil? then
            InboxFiles::ensureDescription(location)
        end

        thr.exit

        BankExtended::closeNxBall(nxball, true)
    end

    # InboxFiles::ns16s()
    def self.ns16s()
        InboxFiles::locations().map{|location|
            {
                "uuid"       => "#{location}:#{Utils::today()}",
                "announce"   => InboxFiles::announce(location),
                "access"     => lambda { InboxFiles::access(location) },
                "done"       => lambda { LucilleCore::removeFileSystemLocation(location) },
                "domainuuid" => nil
            }
        }
    end
end
