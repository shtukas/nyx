# encoding: UTF-8

class Processes

    # Processes::interactivelyCreateNewProcess()
    def self.interactivelyCreateNewProcess()

        domain = Domain::getCurrentDomain(domain)

        type = LucilleCore::selectEntityFromListOfEntitiesOrNull("type", ["line", "folder"])
        return if type.nil?

        if type == "line" then
            line = LucilleCore::askQuestionAnswerAsString("line: ")
            date = Time.new.to_s[0, 10]
            filename = "#{date} #{SecureRandom.uuid}.txt"
            location = "/Users/pascal/Galaxy/Processes/#{filename}"
            File.open(location, "w"){|f| f.puts(line) }
            KeyValueStore::set(nil, "196d3609-eea7-47ea-a172-b24c7240c4df:#{location}", domain)
        end

        if type == "folder" then
            description = LucilleCore::askQuestionAnswerAsString("description: ")
            date = Time.new.to_s[0, 10]
            filename = "#{date} #{description}"
            location = "/Users/pascal/Galaxy/Processes/#{filename}"
            FileUtils.mkdir(location)
            KeyValueStore::set(nil, "196d3609-eea7-47ea-a172-b24c7240c4df:#{location}", domain)
            system("open '#{location}'")
            LucilleCore::pressEnterToContinue()

        end
    end

    # Processes::runLocation(location)
    def self.runLocation(location)
        system("clear")
        if File.file?(location) then
            puts "[proc] #{File.basename(location)}".green
            action = LucilleCore::selectEntityFromListOfEntitiesOrNull("action", ["destroy"])
            if action == "destroy" then
                if LucilleCore::askQuestionAnswerAsBoolean("destroy ? ") then
                    LucilleCore::removeFileSystemLocation(location)
                end
            end
        else
            puts "[proc] (folder) #{File.basename(location)}".green
            system("open '#{location}'")
            LucilleCore::pressEnterToContinue("> Press [enter] to exit folder visit: ") 
        end
    end

    # Processes::getLocationDomain(location)
    def self.getLocationDomain(location)
        domain = KeyValueStore::getOrNull(nil, "196d3609-eea7-47ea-a172-b24c7240c4df:#{location}")
        return domain if domain
        puts location.green
        if File.file?(location) then
            puts IO.read(location).strip.green
        end
        domain = Domain::interactivelySelectDomain()
        KeyValueStore::set(nil, "196d3609-eea7-47ea-a172-b24c7240c4df:#{location}", domain)
        domain
    end

    # Processes::items(domain)
    def self.items(domain)

        getFileUnixtime = lambda{|filepath|
            unixtime = KeyValueStore::getOrNull(nil, "0609a9fc-f7f6-4c3e-b0dd-952fbb26020f:#{filepath}")
            return unixtime.to_f if unixtime
            unixtime = Time.new.to_i
            KeyValueStore::set(nil, "0609a9fc-f7f6-4c3e-b0dd-952fbb26020f:#{filepath}", unixtime)
            unixtime
        }

        getFolderUnixtime = lambda{|folderpath|
            filepath = "#{folderpath}/.unixtime-784971ed"
            if !File.exists?(filepath) then
                File.open(filepath, "w") {|f| f.puts(Time.new.to_f)}
            end
            IO.read(filepath).strip.to_f
        }

        LucilleCore::locationsAtFolder("/Users/pascal/Galaxy/Processes")
            .select{|location| Processes::getLocationDomain(location) == domain }
            .map{|location|
                if File.file?(location) then
                    announce = "[proc] #{IO.read(location).strip}"
                    {
                        "announce"     => announce,
                        "unixtime"     => getFileUnixtime.call(location),
                        "run"          => lambda{
                            if LucilleCore::askQuestionAnswerAsBoolean("destroy ? ") then
                                LucilleCore::removeFileSystemLocation(location)
                            end
                        },
                    }
                else
                    announce = "[proc] (folder) #{File.basename(location)}"
                    {
                        "announce"     => announce,
                        "unixtime"     => getFolderUnixtime.call(location),
                        "run"          => lambda{ Processes::runLocation(location) },
                    }
                end
            }
            .sort{|i1, i2| i1["unixtime"] <=> i2["unixtime"] }

        #{
        #    "announce"
        #    "run"
        #}
    end

    # Processes::ns16s(domain)
    def self.ns16s(domain)
        LucilleCore::locationsAtFolder("/Users/pascal/Galaxy/Processes")
            .select{|location| Processes::getLocationDomain(location) == domain }
            .select{|location| 
                uuid = Digest::SHA1.hexdigest("7d7967c7-3214-47af-ab9d-6c314085c88d:#{location}")
                !KeyValueStore::flagIsTrue(nil, "80954193-8ff0-4d90-af94-20862d67f9dd:#{uuid}:#{Utils::today()}")
            }
            .map{|location|
                uuid = Digest::SHA1.hexdigest("7d7967c7-3214-47af-ab9d-6c314085c88d:#{location}")
                announce = 
                    if File.file?(location) then
                        "[process acknowledgement] #{IO.read(location).strip}"
                    else
                        "[process acknowledgement] (folder) #{File.basename(location)}"
                    end
                {
                    "uuid"        => uuid,
                    "announce"    => announce,
                    "commands"    => ["..", "ack"],
                    "run"         => lambda {
                        Processes::runLocation(location)
                        KeyValueStore::setFlagTrue(nil, "80954193-8ff0-4d90-af94-20862d67f9dd:#{uuid}:#{Utils::today()}")
                    },
                    "interpreter" => lambda{|command|
                        if command == "ack" then
                            KeyValueStore::setFlagTrue(nil, "80954193-8ff0-4d90-af94-20862d67f9dd:#{uuid}:#{Utils::today()}")
                        end
                    }
                }
            }
    end

    # Processes::nx19s()
    def self.nx19s()
        (Processes::items("(eva)")+Processes::items("(work)")).map{|item|
            {
                "uuid"     => Digest::SHA1.hexdigest(item["announce"]),
                "announce" => item["announce"],
                "lambda"   => lambda { item["run"].call() }
            }
        }
    end
end
