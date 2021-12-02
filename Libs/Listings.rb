
# encoding: UTF-8

class Listings

    # Listings::listings()
    def self.listings()
        ["(eva)", "(work)", "(jedi)", "(entertainment)"]
    end

    # Listings::getActionAvailableListings()
    def self.getActionAvailableListings()
        return (Listings::listings() - ["(work)"]) if Time.new.wday == 6
        return (Listings::listings() - ["(work)"]) if Time.new.wday == 0
        return (Listings::listings() - ["(work)"]) if Time.new.hour < 8
        return (Listings::listings() - ["(work)"]) if Time.new.hour > 17
        Listings::listings()
    end

    # Listings::setStoredListingWithExpiry(listing, expiryUnixtime)
    def self.setStoredListingWithExpiry(listing, expiryUnixtime)
        packet = {
            "listing" => listing,
            "expiry" => expiryUnixtime
        }
        KeyValueStore::set(nil, "6992dae8-5b15-4266-a2c2-920358fda286", JSON.generate(packet))
    end

    # Listings::getStoredListingOrNull()
    def self.getStoredListingOrNull()
        packet = KeyValueStore::getOrNull(nil, "6992dae8-5b15-4266-a2c2-920358fda286")
        return nil if packet.nil?
        packet = JSON.parse(packet)
        return nil if Time.new.to_i > packet["expiry"]
        packet["listing"]
    end

    # Listings::listingDriver(listing)
    def self.listingDriver(listing)
        #{
        #    "type"   => "expectation",
        #    "target" => Float
        #}
        #{
        #    "type"      => "circuit-breaker",
        #    "hourly-rt" => Float
        #}

        map = {
            "(eva)" => {
                "type" => "eva",
                "x1" => 8,
                "x2" => 0.25
            },
            "(work)" => {
                "type"   => "expectation",
                "target" => 5
            },
            "(jedi)" => {
                "type"   => "expectation",
                "target" => 1
            },
            "(entertainment)" => {
                "type"   => "expectation",
                "target" => 1
            }
        }
        map[listing]
    end

    # Listings::listingToOrderingRatio(listing)
    def self.listingToOrderingRatio(listing)
        driver = Listings::listingDriver(listing)
        if driver["type"] == "eva" then
            # Driver eva if for listing (eva)
            # We have WAVES-UNITS-1-44F7-A64A-72D0205F8957 fed with units
            # In addition of the bank account "EVA-97F7F3341-4CD1-8B20-4A2466751408"
            return 1 if Bank::valueOverTimespan("WAVES-UNITS-1-44F7-A64A-72D0205F8957", 3600) >= driver["x1"]
            return 1 if Beatrice::stdRecoveredHourlyTimeInHours(Listings::listingToBankAccount(listing)) >= driver["x2"]
            return 0
        end
        if driver["type"] == "expectation" then
            account = Listings::listingToBankAccount(listing)
            target = driver["target"]
            return BankExtended::stdRecoveredDailyTimeInHours(account).to_f/target
        end
    end

    # Listings::getProgrammaticListing()
    def self.getProgrammaticListing()
        Listings::getActionAvailableListings()
            .map {|listing|
                {
                    "listing" => listing,
                    "ratio"   => Listings::listingToOrderingRatio(listing)
                }
            }
            .sort{|p1, p2|
                p1["ratio"] <=> p2["ratio"]
            }
            .first["listing"]
    end

    # Listings::getListingForTerminalDisplay()
    def self.getListingForTerminalDisplay()
        listing = Listings::getStoredListingOrNull()
        return listing if !listing.nil?
        Listings::getProgrammaticListing()
    end

    # Listings::listingToBankAccount(listing)
    def self.listingToBankAccount(listing)
        mapping = {
            "(eva)"           => "EVA-97F7F3341-4CD1-8B20-4A2466751408",
            "(work)"          => "WORK-E4A9-4BCD-9824-1EEC4D648408",
            "(jedi)"          => "C87787F9-77E9-4518-BC41-DBCFB7775299",
            "(entertainment)" => "C00F4D2B-DE5E-41A5-8791-8F486EC05ED7"
        }
        raise "[62e07265-cda5-45e1-9b90-7c88db751a1c: #{listing}]" if !mapping.keys.include?(listing)
        mapping[listing]
    end

    # Listings::interactivelySelectListing()
    def self.interactivelySelectListing()
        listing = LucilleCore::selectEntityFromListOfEntitiesOrNull("listing", Listings::listings())
        if !listing.nil? then
            return listing
        end
        Listings::interactivelySelectListing()
    end

    # Listings::interactivelySelectListingOrNull()
    def self.interactivelySelectListingOrNull()
        entity = LucilleCore::selectEntityFromListOfEntitiesOrNull("listing", Listings::listings() + ["(null) # default"])
        if entity == "(null) # default" then
            return nil
        end
        entity
    end

    # Listings::dx()
    def self.dx()
        listingToString = lambda{|listing|
            listing.gsub("(", "").gsub(")", "")
        }
        Listings::getActionAvailableListings()
            .map{|listing|
                account = Listings::listingToBankAccount(listing)
                {
                    "listing" => listing,
                    "rt"      => BankExtended::stdRecoveredDailyTimeInHours(account),
                    "today"   => Bank::valueAtDate(account, Utils::today()).to_f/3600,
                    "ratio"   => Listings::listingToOrderingRatio(listing)
                }
            }
            .sort{|p1, p2| p1["ratio"]<=>p2["ratio"] }
            .map{|px|               
                (lambda{|listing, ratio, driver|
                    if driver["type"] == "expectation" then
                        return "(#{listingToString.call(listing)}: #{(100*ratio).to_i}% of #{driver["target"]} hours)"
                    end
                    if driver["type"] == "eva" then
                        v1 = Bank::valueOverTimespan("WAVES-UNITS-1-44F7-A64A-72D0205F8957", 3600)
                        v2 = Beatrice::stdRecoveredHourlyTimeInHours(Listings::listingToBankAccount(listing))
                        return "(#{listingToString.call(listing)}: #{v1} of #{driver["x1"]}, #{v2.round(2)} of #{driver["x2"]})"
                    end
                }).call(px["listing"], px["ratio"], Listings::listingDriver(px["listing"]))
            }
            .join(" ")
    end
end
