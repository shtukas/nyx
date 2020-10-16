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

            ms.item("Pages (listing all)",lambda { Pages::pagesListing() })

            ms.item("Pages (peco iteractive select + landing)",lambda {
                loop {
                    page = Pages::selectExistingPageOrNull_v2()
                    return if page.nil?
                    Pages::landing(page)
                }
            })

            ms.item(
                "Datapoint Exploration", 
                lambda { NSNode1638Extended::interactiveDatapointSearchAndExplore() }
            )

            ms.item(
                "Datapoint Exploration (ncurses experimental)", 
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
                "Datapoint Listing", 
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

            ms.item("Cubes Listing all",lambda { Cubes::cubesListing() })

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

            ms.item("new datapoint", lambda {
                datapoint = NSNode1638::issueNewPointInteractivelyOrNull()
                return if datapoint.nil?
                description = LucilleCore::askQuestionAnswerAsString("datapoint description ? (empty for null) : ")
                if description.size > 0 then
                    datapoint["description"] = description
                    NSNode1638::commitDatapointToDiskOrNothingReturnBoolean(datapoint)
                end
                NSNode1638::landing(node)
            })

            ms.item("new cube", lambda {
                description = LucilleCore::askQuestionAnswerAsString("cube description: ")
                location =    LucilleCore::askQuestionAnswerAsString("cube location: ")
                cube = Cubes::issueCube(description, location)
                Cubes::cubeLanding(cube)
            })

            ms.item("dangerously edit a nyx object by uuid", lambda { 
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
            })

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


