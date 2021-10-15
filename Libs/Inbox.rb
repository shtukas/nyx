# encoding: UTF-8

class Inbox

    # Inbox::repository()
    def self.repository()
        "/Users/pascal/Desktop/Catalyst Inbox"
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
