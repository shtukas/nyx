# encoding: UTF-8

class Nx60Queue

    # Nx60Queue::repositoryFolderpath()
    def self.repositoryFolderpath()
        "/Users/pascal/Desktop"
    end

    # Nx60Queue::locations()
    def self.locations()
        LucilleCore::locationsAtFolder(Nx60Queue::repositoryFolderpath()) - IO.read("/Users/pascal/Galaxy/DataBank/Catalyst/Nx60Queue-ExclusionFilenames.txt").lines.map{|line| "/Users/pascal/Desktop/#{line.strip}" }
    end

    # Nx60Queue::getDescriptionOrNull(location)
    def self.getDescriptionOrNull(location)
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
        loop {

            system("clear")

            break if !File.exist?(location)

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

            puts "done | hide60 (hide for 1 hour) | hide18 (hide until 18) | hide09 (hide until tomorrow 9am) | >nx50s (move to nx50) | exit".yellow
            command = LucilleCore::askQuestionAnswerAsString("> ")
        
            break if command == "exit"

            if Interpreting::match("done", command) then
                LucilleCore::removeFileSystemLocation(location)
                break
            end

            if Interpreting::match("hide60", command) then
                unixtime = Time.new.to_i+3600
                DoNotShowUntil::setUnixtime(location, unixtime)
                Nx60Queue::ensureDescription(location)
                break
            end

            if Interpreting::match("hide18", command) then
                unixtime = Utils::unixtimeAtComingMidnightAtGivenTimeZone(Utils::getLocalTimeZone()) - 3600*8
                DoNotShowUntil::setUnixtime(location, unixtime)
                Nx60Queue::ensureDescription(location)
                break
            end

            if Interpreting::match("hide09", command) then
                unixtime = Utils::unixtimeAtComingMidnightAtGivenTimeZone(Utils::getLocalTimeZone()) + 3600*9
                DoNotShowUntil::setUnixtime(location, unixtime)
                Nx60Queue::ensureDescription(location)
                break
            end

            if Interpreting::match(">nx50s", command) then
                unixtime = Utils::unixtimeAtComingMidnightAtGivenTimeZone(Utils::getLocalTimeZone()) + 3600*9
                DoNotShowUntil::setUnixtime(location, unixtime)
                Nx60Queue::ensureDescription(location)
                break
            end
        }
    end

    # Nx60Queue::ns16s()
    def self.ns16s()
        Nx60Queue::locations().map{|location|
            {
                "uuid"     => location,
                "announce" => Nx60Queue::announce(location),
                "access"   => lambda { Nx60Queue::access(location) },
                "done"     => lambda { LucilleCore::removeFileSystemLocation(location) }
            }
        }
    end
end
