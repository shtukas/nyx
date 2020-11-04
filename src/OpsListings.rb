
# encoding: UTF-8

class OpsListings

    # OpsListings::listings()
    def self.listings()
        NyxObjects2::getSet("abb20581-f020-43e1-9c37-6c3ef343d2f5")
    end

    # OpsListings::make(name1)
    def self.make(name1)
        {
            "uuid"     => SecureRandom.hex,
            "nyxNxSet" => "abb20581-f020-43e1-9c37-6c3ef343d2f5",
            "unixtime" => Time.new.to_f,
            "name"     => name1
        }
    end

    # OpsListings::issue(name1)
    def self.issue(name1)
        listing = OpsListings::make(name1)
        NyxObjects2::put(listing)
        listing
    end

    # OpsListings::issueListingInteractivelyOrNull()
    def self.issueListingInteractivelyOrNull()
        name1 = LucilleCore::askQuestionAnswerAsString("ops listing name: ")
        return nil if name1 == ""
        OpsListings::issue(name1)
    end

    # OpsListings::selectOneExistingListingOrNull()
    def self.selectOneExistingListingOrNull()
        LucilleCore::selectEntityFromListOfEntitiesOrNull("ops listing", OpsListings::listings(), lambda{|listing| OpsListings::toString(listing) })
    end

    # OpsListings::selectOneExistingOrNewListingOrNull()
    def self.selectOneExistingOrNewListingOrNull()
        listing = OpsListings::selectOneExistingListingOrNull()
        return listing if listing
        return nil if !LucilleCore::askQuestionAnswerAsBoolean("no ops listing selected, create a new one ? ")
        OpsListings::issueListingInteractivelyOrNull()
    end

    # OpsListings::toString(listing)
    def self.toString(listing)
        "[ops listing] #{listing["name"]}"
    end

    # OpsListings::landing(listing)
    def self.landing(listing)
        loop {
            system("clear")

            return if NyxObjects2::getOrNull(listing["uuid"]).nil?

            puts OpsListings::toString(listing).green
            puts "uuid: #{listing["uuid"]}".yellow

            mx = LCoreMenuItemsNX1.new()

            targets = Arrows::getTargetsForSource(listing)
            targets = targets.select{|target| !GenericNyxObject::isTag(target) }
            targets = GenericNyxObject::applyDateTimeOrderToObjects(targets)
            puts "" if !targets.empty?
            targets
                .each{|object|
                    mx.item(
                        GenericNyxObject::toString(object),
                        lambda { GenericNyxObject::landing(object) }
                    )
                }

            puts ""
            mx.item("rename".yellow, lambda { 
                name1 = Miscellaneous::editTextSynchronously(listing["name"]).strip
                return if name1 == ""
                listing["name"] = name1
                NyxObjects2::put(listing)
                OpsListings::removeSetDuplicates()
            })
            mx.item("add datapoint".yellow, lambda { 
                datapoint = Datapoints::makeNewDatapointOrNull()
                return if datapoint.nil?
                Arrows::issueOrException(listing, datapoint)
            })
            mx.item("json object".yellow, lambda { 
                puts JSON.pretty_generate(listing)
                LucilleCore::pressEnterToContinue()
            })
            mx.item("destroy listing".yellow, lambda { 
                if LucilleCore::askQuestionAnswerAsBoolean("Are you sure you want to destroy ops listing: '#{OpsListings::toString(listing)}': ") then
                    NyxObjects2::destroy(listing)
                end
            })
            puts ""
            status = mx.promptAndRunSandbox()
            break if !status
        }
    end

    # OpsListings::main()
    def self.main()
        loop {
            system("clear")
            ms = LCoreMenuItemsNX1.new()

            ms.item("ops listings dive",lambda { 
                loop {
                    listings = OpsListings::listings()
                    listing = LucilleCore::selectEntityFromListOfEntitiesOrNull("ops listing", listings, lambda{|listing| OpsListings::toString(listing) })
                    return if listing.nil?
                    OpsListings::landing(listing)
                }
            })

            ms.item("make new ops listing",lambda { OpsListings::issueListingInteractivelyOrNull() })

            status = ms.promptAndRunSandbox()
            break if !status
        }
    end
end
