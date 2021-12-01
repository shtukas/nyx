
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

    # Listings::expectation(listing)
    def self.expectation(listing)
        map = {
            "(eva)"           => 1,
            "(work)"          => 6,
            "(jedi)"          => 2,
            "(entertainment)" => 1
        }
        map[listing]
    end

    # Listings::getProgrammaticListing()
    def self.getProgrammaticListing()
        Listings::getActionAvailableListings()
            .map {|listing|
                {
                    "listing" => listing,
                    "ratio"  => BankExtended::stdRecoveredDailyTimeInHours(Listings::listingToBankAccount(listing)).to_f/Listings::expectation(listing)
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
                    "ratio"   => BankExtended::stdRecoveredDailyTimeInHours(Listings::listingToBankAccount(listing)).to_f/Listings::expectation(listing)
                }
            }
            .sort{|p1, p2| p1["ratio"]<=>p2["ratio"] }
            .map{|px|
                "(#{listingToString.call(px["listing"])}: #{(100*px["ratio"]).to_i}% of #{Listings::expectation(px["listing"])} hours)"
            }
            .join(" ")
    end
end
