
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
        node = EncyclopediaListings::make(name1)
        NyxObjects2::put(node)
        node
    end

    # EncyclopediaListings::issueKnowledgeNodeInteractivelyOrNull()
    def self.issueKnowledgeNodeInteractivelyOrNull()
        name1 = LucilleCore::askQuestionAnswerAsString("encyclopedia node name: ")
        return nil if name1 == ""
        EncyclopediaListings::issue(name1)
    end

    # EncyclopediaListings::selectOneExistingListingOrNull()
    def self.selectOneExistingListingOrNull()
        LucilleCore::selectEntityFromListOfEntitiesOrNull("encyclopedia node", EncyclopediaListings::listings(), lambda{|node| EncyclopediaListings::toString(node) })
    end

    # EncyclopediaListings::selectOneExistingOrNewListingOrNull()
    def self.selectOneExistingOrNewListingOrNull()
        node = EncyclopediaListings::selectOneExistingListingOrNull()
        return node if node
        return nil if !LucilleCore::askQuestionAnswerAsBoolean("no encyclopedia node selected, create a new one ? ")
        EncyclopediaListings::issueKnowledgeNodeInteractivelyOrNull()
    end

    # EncyclopediaListings::toString(node)
    def self.toString(node)
        "[encyclopedia node] #{node["name"]}"
    end

    # EncyclopediaListings::landing(node)
    def self.landing(node)
        loop {
            system("clear")

            return if NyxObjects2::getOrNull(node["uuid"]).nil?

            puts EncyclopediaListings::toString(node).green
            puts "uuid: #{node["uuid"]}".yellow

            mx = LCoreMenuItemsNX1.new()

            sources = Arrows::getSourcesForTarget(node)
            puts "" if !sources.empty?
            sources.each{|source|
                mx.item(
                    "source: #{GenericNyxObject::toString(source)}",
                    lambda { GenericNyxObject::landing(source) }
                )
            }

            targets = Arrows::getTargetsForSource(node)
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
                name1 = Miscellaneous::editTextSynchronously(node["name"]).strip
                return if name1 == ""
                node["name"] = name1
                NyxObjects2::put(node)
                EncyclopediaListings::removeSetDuplicates()
            })
            mx.item("add datapoint".yellow, lambda { 
                datapoint = Datapoints::makeNewDatapointOrNull()
                return if datapoint.nil?
                Arrows::issueOrException(node, datapoint)
            })
            mx.item("add to listing".yellow, lambda { 
                l2 = Listings::extractionSelectListingOrMakeListingOrNull()
                return if l2.nil?
                Arrows::issueOrException(l2, node)
            })
            mx.item("json object".yellow, lambda { 
                puts JSON.pretty_generate(node)
                LucilleCore::pressEnterToContinue()
            })
            mx.item("destroy encyclopedia node".yellow, lambda { 
                if LucilleCore::askQuestionAnswerAsBoolean("Are you sure you want to destroy encyclopedia node: '#{EncyclopediaListings::toString(node)}': ") then
                    NyxObjects2::destroy(node)
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

            ms.item("encyclopedia nodes dive",lambda { 
                loop {
                    nodes = EncyclopediaListings::listings()
                    node = LucilleCore::selectEntityFromListOfEntitiesOrNull("node", nodes, lambda{|node| EncyclopediaListings::toString(node) })
                    return if node.nil?
                    EncyclopediaListings::landing(node)
                }
            })

            ms.item("make new knowlege node",lambda { EncyclopediaListings::issueKnowledgeNodeInteractivelyOrNull() })

            status = ms.promptAndRunSandbox()
            break if !status
        }
    end
end
