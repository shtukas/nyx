# encoding: UTF-8

class DataPortalUI

    # DataPortalUI::dataPortalFront()
    def self.dataPortalFront()
        loop {
            system("clear")

            ms = LCoreMenuItemsNX1.new()

            ms.item(
                "Catalyst General Exploration", 
                lambda { GeneralSearch::searchAndDive() }
            )

            ms.item(
                "Node Exploration", 
                lambda { NSDataType1Extended::interactiveNodeSearchAndExplore() }
            )

            ms.item(
                "Node Exploration (ncurses experimental)", 
                lambda { 
                    loop {
                        nodes = NSDataType1Extended::interactiveNodeNcursesSearch()
                        return if nodes.empty?
                        node = NSDataType1Extended::selectOneNodeFromNodesOrNull(nodes)
                        return if node.nil?
                        NSDataPoint::landing(node)
                    }
                }
            )

            ms.item(
                "Node Listing", 
                lambda {
                    nodes = NSDataPoint::datapoints()
                    nodes = GenericObjectInterface::applyDateTimeOrderToObjects(nodes)
                    loop {
                        system("clear")
                        node = LucilleCore::selectEntityFromListOfEntitiesOrNull("node", nodes, lambda{|o| NSDataType1::toString(o) })
                        break if node.nil?
                        NSDataPoint::landing(node)
                    }
                }
            )

            puts ""

            ms.item(
                "new datapoint",
                lambda {
                    puts "We first select a node because a dataline without a parent will be garbage collected"
                    LucilleCore::pressEnterToContinue()
                    node = NSDataType1Extended::sandboxSelectionOfOneExistingOrNewNodeOrNull()
                    return if node.nil?
                    puts "selected node: #{NSDataType1::toString(node)}"
                    LucilleCore::pressEnterToContinue()
                    datapoint = NSDataPoint::issueNewPointInteractivelyOrNull()
                    return if datapoint.nil?
                    Arrows::issueOrException(node, datapoint)
                    description = LucilleCore::askQuestionAnswerAsString("datapoint description ? (empty for null) : ")
                    if description.size > 0 then
                        datapoint["description"] = description
                        NyxObjects2::put(datapoint)
                    end
                    NSDataPoint::landing(node)
                }
            )

            ms.item(
                "Merge two nodes",
                lambda { 
                    puts "Merging two nodes"
                    puts "Selecting one after the other and then will merge"
                    node1 = NSDataType1Extended::sandboxSelectionOfOneExistingOrNewNodeOrNull()
                    return if node1.nil?
                    node2 = NSDataType1Extended::sandboxSelectionOfOneExistingOrNewNodeOrNull()
                    return if node2.nil?
                    if node1["uuid"] == node2["uuid"] then
                        puts "You have selected the same node twice. Aborting merge operation."
                        LucilleCore::pressEnterToContinue()
                        return
                    end

                    puts ""
                    puts NSDataType1::toString(node1)
                    puts NSDataType1::toString(node2)

                    return if !LucilleCore::askQuestionAnswerAsBoolean("confirm merge : ")

                    # Moving all the node upstreams of node2 towards node 1
                    Arrows::getSourcesForTarget(node2).each{|x|
                        Arrows::issueOrException(x, node1)
                    }
                    # Moving all the downstreams of node2 toward node 1
                    Arrows::getTargetsForSource(node2).each{|x|
                        Arrows::issueOrException(node1, x)
                    }
                    NyxObjects2::destroy(node2) # Simple destroy, not the procedure,what happens if node2 had some contents ?
                }
            )

            ms.item(
                "dangerously edit a nyx object by uuid", 
                lambda { 
                    uuid = LucilleCore::askQuestionAnswerAsString("uuid: ")
                    return if uuid == ""
                    object = NyxObjects2::getOrNull(uuid)
                    return if object.nil?
                    object = Miscellaneous::editTextSynchronously(JSON.pretty_generate(object))
                    object = JSON.parse(object)
                    NyxObjects2::destroy(object)
                    NyxObjects2::put(object)
                }
            )

            puts ""

            ms.item(
                "Asteroids",
                lambda { Asteroids::main() }
            )

            ms.item(
                "asteroid floats open-project-in-the-background", 
                lambda { 
                    loop {
                        system("clear")
                        menuitems = LCoreMenuItemsNX1.new()
                        Asteroids::asteroids()
                            .select{|asteroid| asteroid["orbital"]["type"] == "open-project-in-the-background-b458aa91-6e1" }
                            .each{|asteroid|
                                menuitems.item(
                                    Asteroids::toString(asteroid),
                                    lambda { Asteroids::landing(asteroid) }
                                )
                            }
                        status = menuitems.promptAndRunSandbox()
                        break if !status
                    }
                }
            )

            puts ""

            ms.item(
                "Calendar",
                lambda { 
                    system("open '#{Miscellaneous::catalystDataCenterFolderpath()}/Calendar/Items'") 
                }
            )

            ms.item(
                "Waves",
                lambda { Waves::main() }
            )

            puts ""

            ms.item(
                "1. rebuild search lookup", 
                lambda { SelectionLookupDataset::rebuildDataset(true) }
            )

            ms.item(
                "2. NSDatapointNyxElementLocation::automaintenance(true)",
                lambda { NSDatapointNyxElementLocation::automaintenance(true) }
            )

            ms.item(
                "3. NyxGarbageCollection::run(true)",
                lambda { NyxGarbageCollection::run(true) }
            )

            ms.item(
                "GlobalMaintenance::main(false)",
                lambda { GlobalMaintenance::main(true) }
            )

            puts ""

            ms.item(
                "GlobalFsck::main(runhash)",
                lambda {
                    runhash = LucilleCore::askQuestionAnswerAsString("run hash (empty to generate a random one): ")
                    if runhash == "" then
                        runhash = SecureRandom.hex
                    end
                    GlobalFsck::main(runhash)
                }
            )

            puts ""

            ms.item(
                "Print Generation Speed Report", 
                lambda { CatalystObjectsOperator::generationSpeedReport() }
            )

            ms.item(
                "Curation::session()", 
                lambda { Curation::session() }
            )

            status = ms.promptAndRunSandbox()
            break if !status
        }
    end
end


