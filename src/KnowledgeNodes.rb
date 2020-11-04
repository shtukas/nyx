
# encoding: UTF-8

class KnowledgeNodes

    # KnowledgeNodes::listings()
    def self.listings()
        NyxObjects2::getSet("f1ae7449-16d5-41c0-a89e-f2a8e486cc99")
    end

    # KnowledgeNodes::make(name1)
    def self.make(name1)
        {
            "uuid"     => SecureRandom.hex,
            "nyxNxSet" => "f1ae7449-16d5-41c0-a89e-f2a8e486cc99",
            "unixtime" => Time.new.to_f,
            "name"     => name1
        }
    end

    # KnowledgeNodes::issue(name1)
    def self.issue(name1)
        listing = KnowledgeNodes::make(name1)
        NyxObjects2::put(listing)
        listing
    end

    # KnowledgeNodes::issueListingInteractivelyOrNull()
    def self.issueListingInteractivelyOrNull()
        name1 = LucilleCore::askQuestionAnswerAsString("knowledge node name: ")
        return nil if name1 == ""
        KnowledgeNodes::issue(name1)
    end

    # KnowledgeNodes::selectOneExistingListingOrNull()
    def self.selectOneExistingListingOrNull()
        LucilleCore::selectEntityFromListOfEntitiesOrNull("knowledge node", KnowledgeNodes::listings(), lambda{|listing| KnowledgeNodes::toString(listing) })
    end

    # KnowledgeNodes::selectOneExistingOrNewListingOrNull()
    def self.selectOneExistingOrNewListingOrNull()
        listing = KnowledgeNodes::selectOneExistingListingOrNull()
        return listing if listing
        return nil if !LucilleCore::askQuestionAnswerAsBoolean("no knowledge node selected, create a new one ? ")
        KnowledgeNodes::issueListingInteractivelyOrNull()
    end

    # KnowledgeNodes::toString(listing)
    def self.toString(listing)
        "[knowledge node] #{listing["name"]}"
    end

    # KnowledgeNodes::landing(listing)
    def self.landing(listing)
        loop {
            system("clear")

            return if NyxObjects2::getOrNull(listing["uuid"]).nil?

            puts KnowledgeNodes::toString(listing).green
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
                KnowledgeNodes::removeSetDuplicates()
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
            mx.item("destroy knowledge listing".yellow, lambda { 
                if LucilleCore::askQuestionAnswerAsBoolean("Are you sure you want to destroy knowledge listing: '#{KnowledgeNodes::toString(listing)}': ") then
                    NyxObjects2::destroy(listing)
                end
            })
            puts ""
            status = mx.promptAndRunSandbox()
            break if !status
        }
    end

    # KnowledgeNodes::main()
    def self.main()
        loop {
            system("clear")
            ms = LCoreMenuItemsNX1.new()

            ms.item("knowledge listings dive",lambda { 
                loop {
                    listings = KnowledgeNodes::listings()
                    listing = LucilleCore::selectEntityFromListOfEntitiesOrNull("listing", listings, lambda{|listing| KnowledgeNodes::toString(listing) })
                    return if listing.nil?
                    KnowledgeNodes::landing(listing)
                }
            })

            ms.item("make new knowlege listing",lambda { KnowledgeNodes::issueListingInteractivelyOrNull() })

            status = ms.promptAndRunSandbox()
            break if !status
        }
    end
end
