
# encoding: UTF-8

class EncyclopediaNodes

    # EncyclopediaNodes::nodes()
    def self.nodes()
        NyxObjects2::getSet("f1ae7449-16d5-41c0-a89e-f2a8e486cc99")
    end

    # EncyclopediaNodes::make(name1)
    def self.make(name1)
        {
            "uuid"     => SecureRandom.hex,
            "nyxNxSet" => "f1ae7449-16d5-41c0-a89e-f2a8e486cc99",
            "unixtime" => Time.new.to_f,
            "name"     => name1
        }
    end

    # EncyclopediaNodes::issue(name1)
    def self.issue(name1)
        listing = EncyclopediaNodes::make(name1)
        NyxObjects2::put(listing)
        listing
    end

    # EncyclopediaNodes::issueKnowledgeNodeInteractivelyOrNull()
    def self.issueKnowledgeNodeInteractivelyOrNull()
        name1 = LucilleCore::askQuestionAnswerAsString("knowledge node name: ")
        return nil if name1 == ""
        EncyclopediaNodes::issue(name1)
    end

    # EncyclopediaNodes::selectOneExistingListingOrNull()
    def self.selectOneExistingListingOrNull()
        LucilleCore::selectEntityFromListOfEntitiesOrNull("knowledge node", EncyclopediaNodes::nodes(), lambda{|listing| EncyclopediaNodes::toString(listing) })
    end

    # EncyclopediaNodes::selectOneExistingOrNewListingOrNull()
    def self.selectOneExistingOrNewListingOrNull()
        listing = EncyclopediaNodes::selectOneExistingListingOrNull()
        return listing if listing
        return nil if !LucilleCore::askQuestionAnswerAsBoolean("no knowledge node selected, create a new one ? ")
        EncyclopediaNodes::issueKnowledgeNodeInteractivelyOrNull()
    end

    # EncyclopediaNodes::toString(listing)
    def self.toString(listing)
        "[knowledge node] #{listing["name"]}"
    end

    # EncyclopediaNodes::landing(listing)
    def self.landing(listing)
        loop {
            system("clear")

            return if NyxObjects2::getOrNull(listing["uuid"]).nil?

            puts EncyclopediaNodes::toString(listing).green
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
                EncyclopediaNodes::removeSetDuplicates()
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
            mx.item("destroy encyclopedia node".yellow, lambda { 
                if LucilleCore::askQuestionAnswerAsBoolean("Are you sure you want to destroy encyclopedia node: '#{EncyclopediaNodes::toString(listing)}': ") then
                    NyxObjects2::destroy(listing)
                end
            })
            puts ""
            status = mx.promptAndRunSandbox()
            break if !status
        }
    end

    # EncyclopediaNodes::main()
    def self.main()
        loop {
            system("clear")
            ms = LCoreMenuItemsNX1.new()

            ms.item("encyclopedia nodes dive",lambda { 
                loop {
                    listings = EncyclopediaNodes::nodes()
                    listing = LucilleCore::selectEntityFromListOfEntitiesOrNull("listing", listings, lambda{|listing| EncyclopediaNodes::toString(listing) })
                    return if listing.nil?
                    EncyclopediaNodes::landing(listing)
                }
            })

            ms.item("make new knowlege listing",lambda { EncyclopediaNodes::issueKnowledgeNodeInteractivelyOrNull() })

            status = ms.promptAndRunSandbox()
            break if !status
        }
    end
end
