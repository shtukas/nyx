# encoding: UTF-8

class Listings

    # ----------------------------------------
    # Distributions

    # Listings::listings()
    def self.listings()
        ["EVA", "WORK", "JEDI", "ENTERTAINMENT"]
    end

    # Listings::listingsForThisTime()
    def self.listingsForThisTime()
        isSaturday = Time.new.wday == 6
        isSunday = Time.new.wday == 0
        isWeekDay = (!isSaturday and !isSunday)
        isWeekDayBefore8AM = (isWeekDay and (Time.new.hour < 8))
        isWeekDayWorkTime = (isWeekDay and (Time.new.hour >= 8) and (Time.new.hour < 18))
        isWeekDayEvening = (isWeekDay and (Time.new.hour >= 18))
        if isSaturday then
            return ["EVA", "JEDI", "ENTERTAINMENT"]
        end
        if isSunday then
            return ["EVA", "JEDI", "ENTERTAINMENT"]
        end
        if isWeekDayBefore8AM then
            return ["EVA", "ENTERTAINMENT"]
        end
        if isWeekDayWorkTime then
            return ["WORK", "JEDI"]
        end
        if isWeekDayEvening then
            return ["EVA", "JEDI", "ENTERTAINMENT"]
        end
        raise "eb120954-355c-4782-b478-7ea54113f7fe"
    end

    # Listings::applyRatioOrderingToListings(listings)
    def self.applyRatioOrderingToListings(listings)
        listings
            .map {|listing|
                driver = Listings::listingDriver(listing)
                {
                    "listing" => listing,
                    "ratio"   => Listings::computeOrderingRatio(listing, driver)
                }
            }
            .sort{|p1, p2|
                p1["ratio"] <=> p2["ratio"]
            }
            .map{|packet| packet["listing"] }
    end

    # ----------------------------------------
    # Banking

    # Listings::listingToBankAccount(listing)
    def self.listingToBankAccount(listing)
        mapping = {
            "EVA"           => "EVA-97F7F3341-4CD1-8B20-4A2466751408",
            "WORK"          => "WORK-E4A9-4BCD-9824-1EEC4D648408",
            "JEDI"          => "C87787F9-77E9-4518-BC41-DBCFB7775299",
            "ENTERTAINMENT" => "C00F4D2B-DE5E-41A5-8791-8F486EC05ED7"
        }
        raise "[62e07265-cda5-45e1-9b90-7c88db751a1c: #{listing}]" if !mapping.keys.include?(listing)
        mapping[listing]
    end

    # ----------------------------------------
    # Override Listings

    # Listings::setOverrideListing(listing, expiryUnixtime)
    def self.setOverrideListing(listing, expiryUnixtime)
        packet = {
            "listing" => listing,
            "expiry" => expiryUnixtime
        }
        KeyValueStore::set(nil, "6992dae8-5b15-4266-a2c2-920358fda286", JSON.generate(packet))
    end

    # Listings::getOverrideListingOrNull()
    def self.getOverrideListingOrNull()
        packet = KeyValueStore::getOrNull(nil, "6992dae8-5b15-4266-a2c2-920358fda286")
        return nil if packet.nil?
        packet = JSON.parse(packet)
        return nil if Time.new.to_i > packet["expiry"]
        packet["listing"]
    end

    # ----------------------------------------
    # Drivers and computations

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
            "EVA" => {
                "type" => "eva"
            },
            "WORK" => {
                "type"   => "expectation",
                "target" => 5
            },
            "JEDI" => {
                "type"   => "expectation",
                "target" => 1
            },
            "ENTERTAINMENT" => {
                "type"   => "expectation",
                "target" => 1
            }
        }
        map[listing]
    end

    # Listings::computeOrderingRatio(listing, driver)
    def self.computeOrderingRatio(listing, driver)
        if driver["type"] == "eva" then
            return 0
        end
        if driver["type"] == "expectation" then
            account = Listings::listingToBankAccount(listing)
            target = driver["target"]
            return BankExtended::stdRecoveredDailyTimeInHours(account).to_f/target
        end
    end

    # Listings::getThisTimeListingsInPriorityOrder()
    def self.getThisTimeListingsInPriorityOrder()
        Listings::listingsForThisTime()
            .map {|listing|
                driver = Listings::listingDriver(listing)
                {
                    "listing" => listing,
                    "ratio"   => Listings::computeOrderingRatio(listing, driver)
                }
            }
            .sort{|p1, p2|
                p1["ratio"] <=> p2["ratio"]
            }
            .map{|packet| packet["listing"] }
    end

    # ----------------------------------------

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
        listing = LucilleCore::selectEntityFromListOfEntitiesOrNull("listing", Listings::listings() + ["(null) # default"])
        if listing == "(null) # default" then
            return nil
        end
        listing
    end
end
