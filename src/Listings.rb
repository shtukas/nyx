
# encoding: UTF-8

class Listings

    # Listings::listings()
    def self.listings()
        NyxObjects2::getSet("abb20581-f020-43e1-9c37-6c3ef343d2f5")
    end

    # Listings::make(name1, category)
    def self.make(name1, category)
        raise "0A03D147-308A-4203-A864-BC76013268A2" if !["operations", "encyclopaedia"].include?(category)
        {
            "uuid"     => SecureRandom.hex,
            "nyxNxSet" => "abb20581-f020-43e1-9c37-6c3ef343d2f5",
            "unixtime" => Time.new.to_f,
            "category" => category,
            "name"     => name1
        }
    end

    # Listings::issue(name1, category)
    def self.issue(name1, category)
        listing = Listings::make(name1, category)
        NyxObjects2::put(listing)
        listing
    end

    # Listings::selectCategoryInteractivelyOrNull()
    def self.selectCategoryInteractivelyOrNull()
        LucilleCore::selectEntityFromListOfEntitiesOrNull("category", ["operations", "encyclopaedia"])
    end

    # Listings::issueListingInteractivelyOrNull()
    def self.issueListingInteractivelyOrNull()
        name1 = LucilleCore::askQuestionAnswerAsString("listing name: ")
        return nil if name1 == ""
        category = Listings::selectCategoryInteractivelyOrNull()
        return nil if category.nil?
        Listings::issue(name1, category)
    end

    # Listings::selectOneExistingListingOrNull()
    def self.selectOneExistingListingOrNull()
        LucilleCore::selectEntityFromListOfEntitiesOrNull("listing", Listings::listings(), lambda{|listing| Listings::toString(listing) })
    end

    # Listings::selectOneExistingOrNewListingOrNull()
    def self.selectOneExistingOrNewListingOrNull()
        listing = Listings::selectOneExistingListingOrNull()
        return listing if listing
        return nil if !LucilleCore::askQuestionAnswerAsBoolean("no listing selected, create a new one ? ")
        Listings::issueListingInteractivelyOrNull()
    end

    # Listings::toString(listing)
    def self.toString(listing)
        "[listing] [#{listing["category"]}] #{listing["name"]}"
    end

    # Listings::landing(listing)
    def self.landing(listing)
        loop {
            system("clear")

            return if NyxObjects2::getOrNull(listing["uuid"]).nil?

            puts Listings::toString(listing).green
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
                Listings::removeSetDuplicates()
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
                if LucilleCore::askQuestionAnswerAsBoolean("Are you sure you want to destroy listing: '#{Listings::toString(listing)}': ") then
                    NyxObjects2::destroy(listing)
                end
            })
            puts ""
            status = mx.promptAndRunSandbox()
            break if !status
        }
    end

    # Listings::main()
    def self.main()
        loop {
            system("clear")
            ms = LCoreMenuItemsNX1.new()

            ms.item("listings dive",lambda { 
                loop {
                    listings = Listings::listings()
                    listing = LucilleCore::selectEntityFromListOfEntitiesOrNull("listing", listings, lambda{|listing| Listings::toString(listing) })
                    return if listing.nil?
                    Listings::landing(listing)
                }
            })

            ms.item("make new listing",lambda { Listings::issueListingInteractivelyOrNull() })

            status = ms.promptAndRunSandbox()
            break if !status
        }
    end
end
