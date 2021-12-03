
# encoding: UTF-8

class Listings

    # ----------------------------------------

    # Listings::listings()
    def self.listings()
        ["(eva)", "(work)", "(jedi)", "(entertainment)"]
    end

    # Listings::getActionAvailableListings()
    def self.getActionAvailableListings()
        isSaturday = Time.new.wday == 6
        isSunday = Time.new.wday == 0
        isWeekDay = !isSaturday and !isSunday
        isWeekDayBefore8AM = isWeekDay and (Time.new.hour < 8)
        isWeekDayWorkTime = isWeekDay and (Time.new.hour >= 8) and (Time.new.hour < 18)
        isWeekDayEvening = isWeekDay and (Time.new.hour >= 18)
        if isSaturday then
            return ["(eva)", "(jedi)", "(entertainment)"]
        end
        if isSunday then
            return ["(eva)", "(jedi)", "(entertainment)"]
        end
        if isWeekDayBefore8AM then
            return ["(eva)", "(entertainment)"]
        end
        if isWeekDayWorkTime then
            return ["(work)", "(jedi)"]
        end
        if isWeekDayEvening then
            return ["(eva)", "(jedi)", "(entertainment)"]
        end
        raise "eb120954-355c-4782-b478-7ea54113f7fe"
    end

    # ----------------------------------------

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

    # ----------------------------------------

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
                "type" => "eva"
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
            return 0
        end
        if driver["type"] == "expectation" then
            account = Listings::listingToBankAccount(listing)
            target = driver["target"]
            return BankExtended::stdRecoveredDailyTimeInHours(account).to_f/target
        end
    end

    # Listings::getActionAvailableProgrammaticallyOrderedListingsPlus()
    def self.getActionAvailableProgrammaticallyOrderedListingsPlus()
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
    end

    # Listings::getActionAvailableProgrammaticallyOrderedListingsPlusExcudingOverflowed()
    def self.getActionAvailableProgrammaticallyOrderedListingsPlusExcudingOverflowed()
        Listings::getActionAvailableProgrammaticallyOrderedListingsPlus()
            .select{|packet| packet["ratio"] < 1 }
    end

    # Listings::getOrderedListingsForTerminalDisplay()
    def self.getOrderedListingsForTerminalDisplay()
        listing = Listings::getStoredListingOrNull()
        return [listing] if !listing.nil?
        Listings::getActionAvailableProgrammaticallyOrderedListingsPlusExcudingOverflowed()
            .map{|packet| packet["listing"] }
    end

    # ----------------------------------------

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

    # ----------------------------------------

    # Listings::dx(listings)
    def self.dx(listings)
        listingToString = lambda{|listing|
            listing.gsub("(", "").gsub(")", "")
        }
        listings
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
                        return "(#{listingToString.call(listing)})"
                    end
                }).call(px["listing"], px["ratio"], Listings::listingDriver(px["listing"]))
            }
            .join(" ")
    end
end
