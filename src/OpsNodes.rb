
# encoding: UTF-8

class OpsNodes

    # OpsNodes::nodes()
    def self.nodes()
        NyxObjects2::getSet("abb20581-f020-43e1-9c37-6c3ef343d2f5")
    end

    # OpsNodes::make(name1)
    def self.make(name1)
        {
            "uuid"     => SecureRandom.hex,
            "nyxNxSet" => "abb20581-f020-43e1-9c37-6c3ef343d2f5",
            "unixtime" => Time.new.to_f,
            "name"     => name1
        }
    end

    # OpsNodes::issue(name1)
    def self.issue(name1)
        node = OpsNodes::make(name1)
        NyxObjects2::put(node)
        node
    end

    # OpsNodes::issueListingInteractivelyOrNull()
    def self.issueListingInteractivelyOrNull()
        name1 = LucilleCore::askQuestionAnswerAsString("ops node name: ")
        return nil if name1 == ""
        OpsNodes::issue(name1)
    end

    # OpsNodes::selectOneExistingListingOrNull()
    def self.selectOneExistingListingOrNull()
        LucilleCore::selectEntityFromListOfEntitiesOrNull("ops node", OpsNodes::nodes(), lambda{|node| OpsNodes::toString(node) })
    end

    # OpsNodes::selectOneExistingOrNewListingOrNull()
    def self.selectOneExistingOrNewListingOrNull()
        node = OpsNodes::selectOneExistingListingOrNull()
        return node if node
        return nil if !LucilleCore::askQuestionAnswerAsBoolean("no ops node selected, create a new one ? ")
        OpsNodes::issueListingInteractivelyOrNull()
    end

    # OpsNodes::toString(node)
    def self.toString(node)
        "[ops node] #{node["name"]}"
    end

    # OpsNodes::landing(node)
    def self.landing(node)
        loop {
            system("clear")

            return if NyxObjects2::getOrNull(node["uuid"]).nil?

            puts OpsNodes::toString(node).green
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
            targets = targets.select{|target| !GenericNyxObject::isTag(target) }
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
                OpsNodes::removeSetDuplicates()
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
            mx.item("destroy node".yellow, lambda { 
                if LucilleCore::askQuestionAnswerAsBoolean("Are you sure you want to destroy ops node: '#{OpsNodes::toString(node)}': ") then
                    NyxObjects2::destroy(node)
                end
            })
            puts ""
            status = mx.promptAndRunSandbox()
            break if !status
        }
    end

    # OpsNodes::main()
    def self.main()
        loop {
            system("clear")
            ms = LCoreMenuItemsNX1.new()

            ms.item("ops nodes dive",lambda { 
                loop {
                    nodes = OpsNodes::nodes()
                    node = LucilleCore::selectEntityFromListOfEntitiesOrNull("ops node", nodes, lambda{|node| OpsNodes::toString(node) })
                    return if node.nil?
                    OpsNodes::landing(node)
                }
            })

            ms.item("make new ops node",lambda { OpsNodes::issueListingInteractivelyOrNull() })

            status = ms.promptAndRunSandbox()
            break if !status
        }
    end
end
