
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
        node = EncyclopediaNodes::make(name1)
        NyxObjects2::put(node)
        node
    end

    # EncyclopediaNodes::issueKnowledgeNodeInteractivelyOrNull()
    def self.issueKnowledgeNodeInteractivelyOrNull()
        name1 = LucilleCore::askQuestionAnswerAsString("encyclopedia node name: ")
        return nil if name1 == ""
        EncyclopediaNodes::issue(name1)
    end

    # EncyclopediaNodes::selectOneExistingListingOrNull()
    def self.selectOneExistingListingOrNull()
        LucilleCore::selectEntityFromListOfEntitiesOrNull("encyclopedia node", EncyclopediaNodes::nodes(), lambda{|node| EncyclopediaNodes::toString(node) })
    end

    # EncyclopediaNodes::selectOneExistingOrNewListingOrNull()
    def self.selectOneExistingOrNewListingOrNull()
        node = EncyclopediaNodes::selectOneExistingListingOrNull()
        return node if node
        return nil if !LucilleCore::askQuestionAnswerAsBoolean("no encyclopedia node selected, create a new one ? ")
        EncyclopediaNodes::issueKnowledgeNodeInteractivelyOrNull()
    end

    # EncyclopediaNodes::toString(node)
    def self.toString(node)
        "[encyclopedia node] #{node["name"]}"
    end

    # EncyclopediaNodes::landing(node)
    def self.landing(node)
        loop {
            system("clear")

            return if NyxObjects2::getOrNull(node["uuid"]).nil?

            puts EncyclopediaNodes::toString(node).green
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
                EncyclopediaNodes::removeSetDuplicates()
            })
            mx.item("add datapoint".yellow, lambda { 
                datapoint = Datapoints::makeNewDatapointOrNull()
                return if datapoint.nil?
                Arrows::issueOrException(node, datapoint)
            })
            mx.item("json object".yellow, lambda { 
                puts JSON.pretty_generate(node)
                LucilleCore::pressEnterToContinue()
            })
            mx.item("destroy encyclopedia node".yellow, lambda { 
                if LucilleCore::askQuestionAnswerAsBoolean("Are you sure you want to destroy encyclopedia node: '#{EncyclopediaNodes::toString(node)}': ") then
                    NyxObjects2::destroy(node)
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
                    nodes = EncyclopediaNodes::nodes()
                    node = LucilleCore::selectEntityFromListOfEntitiesOrNull("node", nodes, lambda{|node| EncyclopediaNodes::toString(node) })
                    return if node.nil?
                    EncyclopediaNodes::landing(node)
                }
            })

            ms.item("make new knowlege node",lambda { EncyclopediaNodes::issueKnowledgeNodeInteractivelyOrNull() })

            status = ms.promptAndRunSandbox()
            break if !status
        }
    end
end
