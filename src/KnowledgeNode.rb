
# encoding: UTF-8

class KnowledgeNode

    # KnowledgeNode::listings()
    def self.listings()
        NyxObjects2::getSet("f1ae7449-16d5-41c0-a89e-f2a8e486cc99")
    end

    # KnowledgeNode::make(name1)
    def self.make(name1)
        {
            "uuid"     => SecureRandom.hex,
            "nyxNxSet" => "f1ae7449-16d5-41c0-a89e-f2a8e486cc99",
            "unixtime" => Time.new.to_f,
            "name"     => name1
        }
    end

    # KnowledgeNode::issue(name1)
    def self.issue(name1)
        listing = KnowledgeNode::make(name1)
        NyxObjects2::put(listing)
        listing
    end

    # KnowledgeNode::issueListingInteractivelyOrNull()
    def self.issueListingInteractivelyOrNull()
        name1 = LucilleCore::askQuestionAnswerAsString("listing name: ")
        return nil if name1 == ""
        KnowledgeNode::issue(name1)
    end

    # KnowledgeNode::selectOneExistingListingOrNull()
    def self.selectOneExistingListingOrNull()
        LucilleCore::selectEntityFromListOfEntitiesOrNull("listing", KnowledgeNode::listings(), lambda{|listing| KnowledgeNode::toString(listing) })
    end

    # KnowledgeNode::selectOneExistingOrNewListingOrNull()
    def self.selectOneExistingOrNewListingOrNull()
        listing = KnowledgeNode::selectOneExistingListingOrNull()
        return listing if listing
        return nil if !LucilleCore::askQuestionAnswerAsBoolean("no listing selected, create a new one ? ")
        KnowledgeNode::issueListingInteractivelyOrNull()
    end

    # KnowledgeNode::toString(listing)
    def self.toString(listing)
        "[knowledge node] #{listing["name"]}"
    end

    # KnowledgeNode::landing(listing)
    def self.landing(listing)
        loop {
            system("clear")

            return if NyxObjects2::getOrNull(listing["uuid"]).nil?

            puts KnowledgeNode::toString(listing).green
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
                KnowledgeNode::removeSetDuplicates()
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
                if LucilleCore::askQuestionAnswerAsBoolean("Are you sure you want to destroy listing: '#{KnowledgeNode::toString(listing)}': ") then
                    NyxObjects2::destroy(listing)
                end
            })
            puts ""
            status = mx.promptAndRunSandbox()
            break if !status
        }
    end

    # KnowledgeNode::main()
    def self.main()
        loop {
            system("clear")
            ms = LCoreMenuItemsNX1.new()

            ms.item("listings dive",lambda { 
                loop {
                    listings = KnowledgeNode::listings()
                    listing = LucilleCore::selectEntityFromListOfEntitiesOrNull("listing", listings, lambda{|listing| KnowledgeNode::toString(listing) })
                    return if listing.nil?
                    KnowledgeNode::landing(listing)
                }
            })

            ms.item("make new listing",lambda { KnowledgeNode::issueListingInteractivelyOrNull() })

            status = ms.promptAndRunSandbox()
            break if !status
        }
    end
end
