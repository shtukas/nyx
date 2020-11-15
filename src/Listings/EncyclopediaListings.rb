
# encoding: UTF-8

class EncyclopediaListings

    # EncyclopediaListings::listings()
    def self.listings()
        NyxObjects2::getSet("f1ae7449-16d5-41c0-a89e-f2a8e486cc99")
    end

    # EncyclopediaListings::make(name1)
    def self.make(name1)
        {
            "uuid"     => SecureRandom.hex,
            "nyxNxSet" => "f1ae7449-16d5-41c0-a89e-f2a8e486cc99",
            "unixtime" => Time.new.to_f,
            "name"     => name1
        }
    end

    # EncyclopediaListings::issue(name1)
    def self.issue(name1)
        listing = EncyclopediaListings::make(name1)
        NyxObjects2::put(listing)
        listing
    end

    # EncyclopediaListings::issueListingInteractivelyOrNull()
    def self.issueListingInteractivelyOrNull()
        name1 = LucilleCore::askQuestionAnswerAsString("encyclopedia listing name: ")
        return nil if name1 == ""
        EncyclopediaListings::issue(name1)
    end

    # EncyclopediaListings::selectOneExistingListingOrNull()
    def self.selectOneExistingListingOrNull()
        LucilleCore::selectEntityFromListOfEntitiesOrNull("encyclopedia listing", EncyclopediaListings::listings(), lambda{|l| EncyclopediaListings::toString(l) })
    end

    # EncyclopediaListings::selectOneExistingOrNewListingOrNull()
    def self.selectOneExistingOrNewListingOrNull()
        listing = EncyclopediaListings::selectOneExistingListingOrNull()
        return listing if listing
        return nil if !LucilleCore::askQuestionAnswerAsBoolean("no encyclopedia listing selected, create a new one ? ")
        EncyclopediaListings::issueListingInteractivelyOrNull()
    end

    # EncyclopediaListings::toString(listing)
    def self.toString(listing)
        "[encyclopedia listing] #{listing["name"]}"
    end

    # EncyclopediaListings::landing(listing)
    def self.landing(listing)
        loop {
            system("clear")

            return if NyxObjects2::getOrNull(listing["uuid"]).nil?

            puts EncyclopediaListings::toString(listing).green
            puts "uuid: #{listing["uuid"]}".yellow

            mx = LCoreMenuItemsNX1.new()

            sources = Arrows::getSourcesForTarget(listing)
            puts "" if !sources.empty?
            sources.each{|source|
                mx.item(
                    "source: #{GenericNyxObject::toString(source)}",
                    lambda { GenericNyxObject::landing(source) }
                )
            }

            targets = Arrows::getTargetsForSource(listing)
            targets = GenericNyxObject::applyDateTimeOrderToObjects(targets)
            puts "" if !targets.empty?
            targets
                .each{|object|
                    mx.item(
                        "target: #{GenericNyxObject::toString(object)}",
                        lambda { GenericNyxObject::landing(object) }
                    )
                }

            puts ""
            mx.item("rename".yellow, lambda { 
                name1 = Miscellaneous::editTextSynchronously(listing["name"]).strip
                return if name1 == ""
                listing["name"] = name1
                NyxObjects2::put(listing)
                EncyclopediaListings::removeSetDuplicates()
            })
            mx.item("make datapoint ; add as target".yellow, lambda { 
                datapoint = Datapoints::makeNewDatapointOrNull()
                return if datapoint.nil?
                Arrows::issueOrException(listing, datapoint)
            })
            mx.item("make listing ; add as target".yellow, lambda { 
                l = Listings::issueNewListingInteractivelyOrNull()
                return if l.nil?
                Arrows::issueOrException(listing, l)
            })
            mx.item("select object ; add as target".yellow, lambda { 
                o = Patricia::searchAndReturnObjectOrNullSequential()
                return if o.nil?
                Arrows::issueOrException(listing, o)
            })
            mx.item("select listing ; add as parent".yellow, lambda { 
                l2 = Listings::extractionSelectListingOrMakeListingOrNull()
                return if l2.nil?
                Arrows::issueOrException(l2, listing)
            })
            mx.item("select multiple targets ; inject data container".yellow, lambda {
                targets = Arrows::getTargetsForSource(listing)
                selectedtargets, _ = LucilleCore::selectZeroOrMore("target", [], targets, lambda{ |item| GenericNyxObject::toString(item) })
                datacontainer = DataContainers::issueContainerInteractivelyOrNull()
                return if datacontainer.nil?
                Arrows::issueOrException(listing, datacontainer)
                selectedtargets.each{|target|
                    Arrows::issueOrException(datacontainer, target)
                    Arrows::unlink(listing, target)
                }
            })
            mx.item("json object".yellow, lambda { 
                puts JSON.pretty_generate(listing)
                LucilleCore::pressEnterToContinue()
            })
            mx.item("destroy encyclopedia listing".yellow, lambda { 
                if LucilleCore::askQuestionAnswerAsBoolean("Are you sure you want to destroy encyclopedia listing: '#{EncyclopediaListings::toString(listing)}': ") then
                    NyxObjects2::destroy(listing)
                end
            })
            puts ""
            status = mx.promptAndRunSandbox()
            break if !status
        }
    end

    # EncyclopediaListings::main()
    def self.main()
        loop {
            system("clear")
            ms = LCoreMenuItemsNX1.new()

            ms.item("encyclopedia listings dive",lambda { 
                loop {
                    listings = EncyclopediaListings::listings()
                    listing = LucilleCore::selectEntityFromListOfEntitiesOrNull("listing", listings, lambda{|l| EncyclopediaListings::toString(l) })
                    return if listing.nil?
                    EncyclopediaListings::landing(listing)
                }
            })

            ms.item("make new encyclopedia listing",lambda { 
                listing = EncyclopediaListings::issueListingInteractivelyOrNull()
                return if listing.nil?
                EncyclopediaListings::landing(listing)
            })

            status = ms.promptAndRunSandbox()
            break if !status
        }
    end
end
