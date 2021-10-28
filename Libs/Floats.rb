# encoding: UTF-8

class Floats

    # Floats::repositoryFolderpath()
    def self.repositoryFolderpath()
        "/Users/pascal/Galaxy/DataBank/Catalyst/Floats"
    end

    # Floats::getLocationDomain(location)
    def self.getLocationDomain(location)
        locationname = File.basename(location)
        domain = KeyValueStore::getOrNull(nil, "196d3609-eea7-47ea-a172-b24c7240c4df:#{locationname}")
        return domain if domain
        puts location.green
        if File.file?(location) then
            puts IO.read(location).strip.green
        end
        domain = Domain::interactivelySelectDomain()
        KeyValueStore::set(nil, "196d3609-eea7-47ea-a172-b24c7240c4df:#{locationname}", domain)
        domain
    end

    # Floats::locationToString(location)
    def self.locationToString(location)
        if File.file?(location) then
            "[float] #{IO.read(location).strip}"
        else
            "[float] (folder) #{File.basename(location)}"
        end
    end

    # Floats::locationToUnixtime(location)
    def self.locationToUnixtime(location)
        if File.file?(location) then
            unixtime = KeyValueStore::getOrNull(nil, "0609a9fc-f7f6-4c3e-b0dd-952fbb26020f:#{location}")
            return unixtime.to_f if unixtime
            unixtime = Time.new.to_i
            KeyValueStore::set(nil, "0609a9fc-f7f6-4c3e-b0dd-952fbb26020f:#{location}", unixtime)
            unixtime
        else
            filepath = "#{location}/.unixtime-784971ed"
            if !File.exists?(filepath) then
                File.open(filepath, "w") {|f| f.puts(Time.new.to_f)}
            end
            IO.read(filepath).strip.to_f
        end
    end

    # Floats::interactivelyCreateNewOrNull()
    def self.interactivelyCreateNewOrNull()

        domain = Domain::getCurrentDomain()

        type = LucilleCore::selectEntityFromListOfEntitiesOrNull("type", ["line", "folder"])
        return if type.nil?

        if type == "line" then
            line = LucilleCore::askQuestionAnswerAsString("line: ")
            date = Time.new.to_s[0, 10]
            filename = "#{date} #{SecureRandom.uuid}.txt"
            location = "#{Floats::repositoryFolderpath()}/#{filename}"
            File.open(location, "w"){|f| f.puts(line) }
            KeyValueStore::set(nil, "196d3609-eea7-47ea-a172-b24c7240c4df:#{location}", domain)
        end

        if type == "folder" then
            description = LucilleCore::askQuestionAnswerAsString("description: ")
            date = Time.new.to_s[0, 10]
            filename = "#{date} #{description}"
            location = "#{Floats::repositoryFolderpath()}/#{filename}"
            FileUtils.mkdir(location)
            KeyValueStore::set(nil, "196d3609-eea7-47ea-a172-b24c7240c4df:#{location}", domain)
            system("open '#{location}'")
            LucilleCore::pressEnterToContinue()
        end
    end

    # Floats::items(domain)
    def self.items(domain)
        LucilleCore::locationsAtFolder(Floats::repositoryFolderpath())
            .select{|location| Floats::getLocationDomain(location) == domain }
            .map{|location|
                announce = Floats::locationToString(location).gsub("[float]", "[floa]")
                unixtime = Floats::locationToUnixtime(location)
                {
                    "announce"     => announce,
                    "unixtime"     => unixtime,
                    "run"          => lambda{ Floats::landing(location) },
                }
            }
            .sort{|i1, i2| i1["unixtime"] <=> i2["unixtime"] }

        #{
        #    "announce"
        #    "run"
        #}
    end

    # Floats::landing(location)
    def self.landing(location)
        system("clear")
        if File.file?(location) then
            puts "[floa] #{File.basename(location)}".green
            action = LucilleCore::selectEntityFromListOfEntitiesOrNull("action", ["destroy"])
            if action == "destroy" then
                LucilleCore::removeFileSystemLocation(location)
            end
        else
            puts "[floa] (folder) #{File.basename(location)}".green
            system("open '#{location}'")
            LucilleCore::pressEnterToContinue("> Press [enter] to exit folder visit: ") 
        end
    end

    # Floats::ns16s(domain)
    def self.ns16s(domain)
        LucilleCore::locationsAtFolder(Floats::repositoryFolderpath())
            .select{|location| Floats::getLocationDomain(location) == domain }
            .select{|location| 
                uuid = Digest::SHA1.hexdigest("7d7967c7-3214-47af-ab9d-6c314085c88d:#{location}")
                !KeyValueStore::flagIsTrue(nil, "80954193-8ff0-4d90-af94-20862d67f9dd:#{uuid}:#{Utils::today()}")
            }
            .map{|location|
                uuid = Digest::SHA1.hexdigest("7d7967c7-3214-47af-ab9d-6c314085c88d:#{location}")
                announce = "[acknowledgement] #{Floats::locationToString(location)}"
                {
                    "uuid"        => uuid,
                    "announce"    => announce,
                    "commands"    => ["..", "landing"],
                    "run"         => lambda {
                        KeyValueStore::setFlagTrue(nil, "80954193-8ff0-4d90-af94-20862d67f9dd:#{uuid}:#{Utils::today()}")
                    },
                    "interpreter" => lambda{|command|
                        if command == "dive" then
                            Floats::landing(location)
                        end
                    }
                }
            }
    end

    # Floats::nx19s()
    def self.nx19s()
        (Floats::items("(eva)")+Floats::items("(work)")).map{|item|
            {
                "uuid"     => Digest::SHA1.hexdigest(item["announce"]),
                "announce" => item["announce"],
                "lambda"   => lambda { item["run"].call() }
            }
        }
    end
end
