# encoding: UTF-8

class Nx60Queue

    # Nx60Queue::repositoryFolderpath()
    def self.repositoryFolderpath()
        "/Users/pascal/Desktop/Inbox"
    end

    # Nx60Queue::locations()
    def self.locations()
        LucilleCore::locationsAtFolder(Nx60Queue::repositoryFolderpath())
    end

    # Nx60Queue::getDescriptionOrNull(location)
    def self.getDescriptionOrNull(location)
        return nil if !File.exists?(location)
        KeyValueStore::getOrNull(nil, "ca23acc1-6596-4e8e-b9e7-714ae3c7b0f8:#{location}")
    end

    # Nx60Queue::setDescription(location, description)
    def self.setDescription(location, description)
        KeyValueStore::set(nil, "ca23acc1-6596-4e8e-b9e7-714ae3c7b0f8:#{location}", description)
    end

    # Nx60Queue::announce(location)
    def self.announce(location)
        description = Nx60Queue::getDescriptionOrNull(location)
        if description then
            "[quee] #{description}"
        else
            "[quee] #{File.basename(location)}"
        end
    end

    # Nx60Queue::ensureDescription(location)
    def self.ensureDescription(location)
        if Nx60Queue::getDescriptionOrNull(location).nil? then
            description = LucilleCore::askQuestionAnswerAsString("description: ")
            Nx60Queue::setDescription(location, description)
        end
    end

    # Nx60Queue::access(location)
    def self.access(location)

        uuid = "#{location}:#{Utils::today()}"

        nxball = BankExtended::makeNxBall([uuid, "Nx60-69315F2A-BE92-4874-85F1-54F140E3B243"])

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

        if File.exists?(location) and Nx60Queue::getDescriptionOrNull(location).nil? then
            Nx60Queue::ensureDescription(location)
        end

        thr.exit

        BankExtended::closeNxBall(nxball, true)
    end

    # Nx60Queue::ns16s()
    def self.ns16s()
        Nx60Queue::locations().map{|location|
            uuid = "#{location}:#{Utils::today()}" # this disable DoNotShowUntil beyond the current day. 
            {
                "uuid"     => uuid,
                "announce" => Nx60Queue::announce(location),
                "access"   => lambda { Nx60Queue::access(location) },
                "done"     => lambda { LucilleCore::removeFileSystemLocation(location) },
                "metric"   => 0.25 + MetricUtils::datetimeToMetricShiftIncreasing(File.mtime(location).to_s)
            }
        }
    end
end
