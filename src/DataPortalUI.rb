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
                lambda { NSDT1SelectionInterface::interactiveNodeSearchAndExplore() }
            )

            ms.item(
                "Node Exploration (ncurses experimental)", 
                lambda { 
                    loop {
                        nodes = NSDT1SelectionInterface::interactiveNodeNcursesSearch()
                        return if nodes.empty?
                        node = NSDT1SelectionInterface::selectOneNodeFromNodesOrNull(nodes)
                        return if node.nil?
                        NSDataType1::landing(node)
                    }
                }
            )

            ms.item(
                "Node Listing", 
                lambda {
                    nodes = NSDataType1::objects()
                    nodes = GenericObjectInterface::applyDateTimeOrderToObjects(nodes)
                    loop {
                        system("clear")
                        node = LucilleCore::selectEntityFromListOfEntitiesOrNull("node", nodes, lambda{|o| NSDataType1::toString(o) })
                        break if node.nil?
                        NSDataType1::landing(node)
                    }
                }
            )

            puts ""

            ms.item(
                "new data",
                lambda {
                    puts "We first select a node because a dataline without a parent will be garbage collected"
                    LucilleCore::pressEnterToContinue()
                    node = NSDT1SelectionInterface::sandboxSelectionOfOneExistingOrNewNodeOrNull()
                    return if node.nil?
                    puts "selected node: #{NSDataType1::toString(node)}"
                    LucilleCore::pressEnterToContinue()
                    dataline = NSDataLine::interactiveIssueNewDatalineWithItsFirstPointOrNull()
                    return if dataline.nil?
                    Arrows::issueOrException(node, dataline)
                    description = LucilleCore::askQuestionAnswerAsString("dataline description ? (empty for null) : ")
                    if description.size > 0 then
                        NSDataTypeXExtended::issueDescriptionForTarget(dataline, description)
                    end
                    NSDataType1::landing(node)
                }
            )

            ms.item(
                "new node",
                lambda { 
                    point = NSDataType1::issueNewNodeInteractivelyOrNull()
                    return if point.nil?
                    NSDataType1::landing(point)
                }
            )

            ms.item(
                "Merge two nodes",
                lambda { 
                    puts "Merging two nodes"
                    puts "Selecting one after the other and then will merge"
                    node1 = NSDT1SelectionInterface::sandboxSelectionOfOneExistingOrNewNodeOrNull()
                    return if node1.nil?
                    node2 = NSDT1SelectionInterface::sandboxSelectionOfOneExistingOrNewNodeOrNull()
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
                "rebuild search lookup", 
                lambda { SelectionLookupDataset::rebuildDataset() }
            )

            ms.item(
                "Print Generation Speed Report", 
                lambda { CatalystObjectsOperator::generationSpeedReport() }
            )

            ms.item(
                "Curation::session()", 
                lambda { Curation::session() }
            )

            ms.item(
                "DeskOperator::commitDeskChangesToPrimaryRepository()", 
                lambda { DeskOperator::commitDeskChangesToPrimaryRepository() }
            )

            ms.item(
                "NyxGarbageCollection::run()",
                lambda { NyxGarbageCollection::run() }
            )

            ms.item(
                "NyxFsck::main(runhash)",
                lambda {
                    runhash = LucilleCore::askQuestionAnswerAsString("run hash (empty to generate a random one): ")
                    if runhash == "" then
                        runhash = SecureRandom.hex
                    end
                    NyxFsck::main(runhash)
                    puts "NyxFsck::main(#{runhash}) completed"
                    LucilleCore::pressEnterToContinue()
                }
            )


            ms.item(
                "Archive timeline garbage collection", 
                lambda { 
                    puts "#{EstateServices::getArchiveT1mel1neSizeInMegaBytes()} Mb"
                    EstateServices::binTimelineGarbageCollectionEnvelop(true)
                }
            )

            status = ms.promptAndRunSandbox()
            break if !status
        }
    end
end


