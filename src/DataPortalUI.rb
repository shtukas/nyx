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

            ms.item("Tags (listing all)",lambda { Tags::tagsListing() })

            ms.item("Tags (peco iteractive select + landing)",lambda {
                loop {
                    set = Tags::selectExistingTagOrNull_v2()
                    return if set.nil?
                    Tags::landing(set)
                }
            })

            ms.item(
                "Datapoint Exploration", 
                lambda { NGX15_Search1::interactiveDatapointSearchAndExplore() }
            )

            ms.item(
                "Datapoint Exploration (ncurses experimental)", 
                lambda { 
                    loop {
                        nodes = NGX15_Search2::interactiveNodeNcursesSearch()
                        return if nodes.empty?
                        node = NGX15_Search1::selectOneDatapointFromDatapointsOrNull(nodes)
                        return if node.nil?
                        NGX15::landing(node)
                    }
                }
            )

            ms.item(
                "Datapoint Listing", 
                lambda {
                    nodes = NGX15::datapoints()
                    nodes = NyxObjectInterface::applyDateTimeOrderToObjects(nodes)
                    loop {
                        system("clear")
                        node = LucilleCore::selectEntityFromListOfEntitiesOrNull("node", nodes, lambda{|o| NGX15::toString(o) })
                        break if node.nil?
                        NGX15::landing(node)
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
                datapoint = NGX15::issueNewNGX15InteractivelyOrNull()
                return if datapoint.nil?
                description = LucilleCore::askQuestionAnswerAsString("datapoint description ? (empty for null) : ")
                if description.size > 0 then
                    datapoint["description"] = description
                    NyxObjects2::put(datapoint)
                end
                NGX15::landing(node)
            })

            ms.item("new cube", lambda {
                description = LucilleCore::askQuestionAnswerAsString("cube description: ")
                location =    LucilleCore::askQuestionAnswerAsString("cube location: ")
                cube = Cubes::issueCube(description, location)
                Cubes::landing(cube)
            })

            ms.item("dangerously edit a nyx object by uuid", lambda { 
                uuid = LucilleCore::askQuestionAnswerAsString("uuid: ")
                return if uuid == ""
                object = NyxObjects2::getOrNull(uuid)
                return if object.nil?
                object = Miscellaneous::editTextSynchronously(JSON.pretty_generate(object))
                object = JSON.parse(object)
                NyxObjects2::put(object)
            })

            ms.item("dangerously delete a nyx object by uuid", lambda { 
                uuid = LucilleCore::askQuestionAnswerAsString("uuid: ")
                object = NyxObjects2::getOrNull(uuid)
                return if object.nil?
                puts JSON.pretty_generate(object)
                return if !LucilleCore::askQuestionAnswerAsBoolean("delete ? : ")
                NyxObjects2::destroy(object)
            })

            puts ""

            ms.item(
                "1. rebuild search lookup", 
                lambda { SelectionLookupDataset::rebuildDataset(true) }
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
                    status = NyxFsck::main(runhash)
                    if status then
                        puts "All good".green
                    else
                        puts "Failed!".red
                    end
                    LucilleCore::pressEnterToContinue()
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


