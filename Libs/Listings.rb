# encoding: UTF-8

class Listings

    # Listings::listings()
    def self.listings()
        ["EVA", "WORK", "JEDI", "ENTERTAINMENT"]
    end

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
