# encoding: UTF-8

class Listings

    # ----------------------------------------
    # Distributions

    # Listings::listings()
    def self.listings()
        ["EVA", "WORK", "JEDI", "ENTERTAINMENT"]
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
    # Drivers and computations

    # Listings::computeRatioDefinedOrNull(listing, driver)
    def self.computeRatioDefinedOrNull(listing, driver)
        if driver["type"] == "eva" then
            account = Listings::listingToBankAccount(listing)
            target = driver["target"]
            return Beatrice::stdRecoveredHourlyTimeInHours(account).to_f/target
        end
        if driver["type"] == "expectation" then
            if driver["time-constraints"] == "work" then
                isWorkTime = ([1, 2, 3, 4, 5].include?(Time.new.wday) and Time.new.hour > 8 and Time.new.hour < 18)
                return nil if !isWorkTime
            end
            account = Listings::listingToBankAccount(listing)
            target = driver["target"]
            return BankExtended::stdRecoveredDailyTimeInHours(account).to_f/target
        end
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

    # ----------------------------------------
end
