# encoding: UTF-8

class Inbox

    # Inbox::repository()
    def self.repository()
        "/Users/pascal/Desktop/Inbox"
    end

    # Inbox::ns16s()
    def self.ns16s()

        getLocationUUID = lambda{|location|
            uuid = KeyValueStore::getOrNull(nil, "54226eda-9437-4f64-9ab9-7e5141a15471:#{location}")
            return uuid.to_f if uuid
            uuid = SecureRandom.uuid
            KeyValueStore::set(nil, "54226eda-9437-4f64-9ab9-7e5141a15471:#{location}", uuid)
            uuid
        }

        getLocationUnixtime = lambda{|location|
            unixtime = KeyValueStore::getOrNull(nil, "54226eda-9437-4f64-9ab9-7e5141a15471:#{location}")
            return unixtime.to_f if unixtime
            unixtime = Time.new.to_f
            KeyValueStore::set(nil, "54226eda-9437-4f64-9ab9-7e5141a15471:#{location}", unixtime)
            unixtime
        }

        LucilleCore::locationsAtFolder(Inbox::repository())
            .map{|location|
                announce = "[inbx] #{File.basename(location)}"
                {
                    "uuid"         => getLocationUUID.call(location),
                    "unixtime"     => getLocationUnixtime.call(location),
                    "announce"     => announce,
                    "run"          => lambda {
                        system("clear")
                        puts location.green

                        # -------------------------------------
                        # Lookup
                        if File.file?(location) then
                            action = LucilleCore::selectEntityFromListOfEntitiesOrNull("action", ["open", "copy to desktop"])
                            if action == "open" then
                                system("open '#{location}'")
                            end
                            if action == "copy to desktop" then
                                FileUtils.cp(location, "/Users/pascal/Desktop")
                            end
                        else
                            system("open '#{location}'")
                        end

                        # -------------------------------------
                        # Dispatch
                        action = LucilleCore::selectEntityFromListOfEntitiesOrNull("action", ["delete", "dispatch"])
                        if action == "delete" then
                            LucilleCore::removeFileSystemLocation(location)
                        end
                        if action == "dispatch" then
                            target = LucilleCore::selectEntityFromListOfEntitiesOrNull("target", ["Process", "Nx50"])
                            if target == "Process" then

                                if File.file?(location) then
                                    Processes::interactivelyCreateNewProcess()
                                    LucilleCore::removeFileSystemLocation(location)
                                else
                                    folderpath1 = location
                                    folderpath2 = "/Users/pascal/Galaxy/Processes/#{Time.new.to_s[0, 10]} #{File.basename(location)} [#{SecureRandom.hex(2)}]"
                                    FileUtils.mkdir(folderpath2)
                                    LucilleCore::copyContents(folderpath1, folderpath2)
                                    LucilleCore::removeFileSystemLocation(location)
                                end

                            end
                            if target == "Nx50" then
                                domain = Domain::interactivelySelectDomain()
                                unixtime = Nx50s::interactivelyDetermineNewItemUnixtime(domain)
                                Nx50s::issueItemUsingLocation(location, unixtime, domain)
                                LucilleCore::removeFileSystemLocation(location)
                            end
                        end
                    }
                }
            }
            .sort{|i1, i2| i1["unixtime"] <=> i2["unixtime"] }
    end

    # Inbox::nx19s()
    def self.nx19s()
        Inbox::ns16s().map{|item|
            {
                "uuid"     => item["uuid"],
                "announce" => Inbox::toStringForNS19(item),
                "lambda"   => lambda { Inbox::run(item) }
            }
        }
    end
end
