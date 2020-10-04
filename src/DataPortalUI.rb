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
                lambda { NSNode1638Extended::interactiveDatapointSearchAndExplore() }
            )

            ms.item(
                "Node Exploration (ncurses experimental)", 
                lambda { 
                    loop {
                        nodes = NSNode1638Extended::interactiveNodeNcursesSearch()
                        return if nodes.empty?
                        node = NSNode1638Extended::selectOneDatapointFromDatapointsOrNull(nodes)
                        return if node.nil?
                        NSNode1638::landing(node)
                    }
                }
            )

            ms.item(
                "Node Listing", 
                lambda {
                    nodes = NSNode1638::datapoints()
                    nodes = NyxObjectInterface::applyDateTimeOrderToObjects(nodes)
                    loop {
                        system("clear")
                        node = LucilleCore::selectEntityFromListOfEntitiesOrNull("node", nodes, lambda{|o| NSNode1638::toString(o) })
                        break if node.nil?
                        NSNode1638::landing(node)
                    }
                }
            )

            ms.item(
                "TaxonomyItem listing", 
                lambda {
                    loop {

                        system("clear")

                        mx = LCoreMenuItemsNX1.new()

                        Taxonomy::items().each{|taxonomyItem|
                            mx.item(
                                Taxonomy::toString(taxonomyItem),
                                lambda { Taxonomy::landing(taxonomyItem) }
                            )
                        }

                        puts ""

                        mx.item("issue new taxonomy item", lambda {
                            coordinates = LucilleCore::askQuestionAnswerAsString("coordinates: ")
                            return if coordinates.size == ""
                            Taxonomy::issueTaxonomyItemFromStringOrNull(coordinates)
                        })

                        status = mx.promptAndRunSandbox()
                        break if !status
                    }
                }
            )

            ms.item(
                "Tag listing",
                lambda {
                    loop {

                        system("clear")

                        mx = LCoreMenuItemsNX1.new()

                        Tags::tags().each{|tag|
                            mx.item(
                                Tags::toString(tag),
                                lambda { Tags::landing(tag) }
                            )
                        }

                        puts ""

                        status = mx.promptAndRunSandbox()
                        break if !status
                    }
                }
            )

            puts ""

            ms.item(
                "new datapoint",
                lambda {
                    datapoint = NSNode1638::issueNewPointInteractivelyOrNull()
                    return if datapoint.nil?
                    description = LucilleCore::askQuestionAnswerAsString("datapoint description ? (empty for null) : ")
                    if description.size > 0 then
                        datapoint["description"] = description
                        NSNode1638::commitDatapointToDiskOrNothingReturnBoolean(datapoint)
                    end
                    NSNode1638::landing(node)
                }
            )

            ms.item(
                "dangerously edit a nyx object by uuid", 
                lambda { 
                    uuid = LucilleCore::askQuestionAnswerAsString("uuid: ")
                    return if uuid == ""
                    object = NyxObjects2::getOrNull(uuid)
                    return if object.nil?
                    if NyxObjectInterface::isDataPoint(object) then
                        if object["type"] == "NyxFSPoint001" then
                            puts "Sorry, you can't do this on a DataPoint that is a NyxFSPoint001. Find the copy on disk."
                            LucilleCore::pressEnterToContinue()
                            return
                        end
                    end
                    object = Miscellaneous::editTextSynchronously(JSON.pretty_generate(object))
                    object = JSON.parse(object)
                    NyxObjects2::put(object)
                }
            )

            puts ""

            ms.item(
                "Asteroids",
                lambda { Asteroids::main() }
            )

            ms.item(
                "Calendar",
                lambda { 
                    system("open '#{Calendar::pathToCalendarItems()}'") 
                }
            )

            ms.item(
                "Waves",
                lambda { Waves::main() }
            )

            puts ""

            ms.item(
                "Guardian Open Cycles",
                lambda { GuardianOpenCycles::program(nil) }
            )

            puts ""

            ms.item(
                "1. rebuild search lookup", 
                lambda { SelectionLookupDataset::rebuildDataset(true) }
            )

            ms.item(
                "2. NSNode1638NyxElementLocation::maintenance(true)",
                lambda { NSNode1638NyxElementLocation::maintenance(true) }
            )

            ms.item(
                "3. NyxGarbageCollection::run()",
                lambda { NyxGarbageCollection::run() }
            )

            puts ""

            ms.item(
                "NyxFsck::main(runhash)",
                lambda {
                    runhash = LucilleCore::askQuestionAnswerAsString("run hash (empty to generate a random one): ")
                    if runhash == "" then
                        runhash = SecureRandom.hex
                    end
                    NyxFsck::main(runhash)
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


