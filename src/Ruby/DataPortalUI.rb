# encoding: UTF-8

class DataPortalUI
    # DataPortalUI::dataPortalFront()
    def self.dataPortalFront()
        loop {
            system("clear")

            ms = LCoreMenuItemsNX1.new()

            ms.item(
                "general search", 
                lambda { GeneralSearch::searchAndDive() }
            )

            ms.item(
                "explore pages", 
                lambda { NSDataType2::selectPagesByInteractiveSearchStringAndExploreThem() }
            )

            ms.item(
                "explore cubes", 
                lambda { NSDataType1::selectCubesByInteractiveSearchStringAndExploreThem() }
            )

            puts ""

            ms.item(
                "new cube",
                lambda { 
                    ns1 = NSDataType1::issueNewCubeAndItsFirstFrameInteractivelyOrNull()
                    return if ns1.nil?
                    NSDataType1::landing(ns1)
                }
            )

            ms.item(
                "new page",
                lambda { 
                    ns2 = NSDataType2::issueNewPageInteractivelyOrNull()
                    return if ns2.nil?
                    NSDataType2::landing(ns2)
                }
            )

            ms.item(
                "merge two pages",
                lambda { 
                    puts "Merging two pages"
                    puts "Selecting one after the other and then will merge"
                    page1 = NSDataType2::selectPageInteractivelyOrNull()
                    return if page1.nil?
                    page2 = NSDataType2::selectPageInteractivelyOrNull()
                    return if page2.nil?
                    if page1["uuid"] == page2["uuid"] then
                        puts "You have selected the same page twice. Aborting merge operation."
                        LucilleCore::pressEnterToContinue()
                        return
                    end

                    # Moving all the page upstreams of page2 towards page 1
                    PageCubeCommonInterface::getUpstreamPages(page2).each{|x|
                        puts "arrow (1): #{NSDataType2::pageToString(x)} -> #{NSDataType2::pageToString(page1)}"
                    }
                    # Moving all the downstreams of page2 toward page 1
                    PageCubeCommonInterface::getDownstreamObjects(page2).each{|x|
                        puts "arrow (2): #{NSDataType2::pageToString(page1)} -> #{NSDataType2::pageToString(x)}"
                    }

                    return if !LucilleCore::askQuestionAnswerAsBoolean("confirm merge : ")

                    # Moving all the page upstreams of page2 towards page 1
                    PageCubeCommonInterface::getUpstreamPages(page2).each{|x|
                        Arrows::issueOrException(x, page1)
                    }
                    # Moving all the downstreams of page2 toward page 1
                    PageCubeCommonInterface::getDownstreamObjects(page2).each{|x|
                        Arrows::issueOrException(page1, x)
                    }
                    NyxObjects::destroy(page2)
                }
            )

            ms.item(
                "dangerously edit a nyx object by uuid", 
                lambda { 
                    uuid = LucilleCore::askQuestionAnswerAsString("uuid: ")
                    return if uuid == ""
                    object = NyxObjects::getOrNull(uuid)
                    return if object.nil?
                    object = Miscellaneous::editTextUsingTextmate(JSON.pretty_generate(object))
                    object = JSON.parse(object)
                    NyxObjects::destroy(object)
                    NyxObjects::put(object)
                }
            )

            puts ""

            ms.item(
                "Asteroids",
                lambda { Asteroids::main() }
            )

            ms.item(
                "asteroid (new)",
                lambda { 
                    asteroid = Asteroids::issueAsteroidInteractivelyOrNull()
                    return if asteroid.nil?
                    puts JSON.pretty_generate(asteroid)
                    LucilleCore::pressEnterToContinue()
                }
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
                                    Asteroids::asteroidToString(asteroid),
                                    lambda { Asteroids::landing(asteroid) }
                                )
                            }
                        status = menuitems.prompt()
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
                "Drives::runShadowUpdate()", 
                lambda { Drives::runShadowUpdate() }
            )

            ms.item(
                "NyxGarbageCollection::run()", 
                lambda { NyxGarbageCollection::run() }
            )

            ms.item(
                "Archive timeline garbage collection", 
                lambda { 
                    puts "#{EstateServices::getArchiveT1mel1neSizeInMegaBytes()} Mb"
                    EstateServices::binTimelineGarbageCollectionEnvelop(true)
                }
            )

            status = ms.prompt()
            break if !status
        }
    end
end


