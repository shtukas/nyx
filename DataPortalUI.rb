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
                "select point by name", 
                lambda { 
                    ns = NavigationPointSelection::selectExistingNavigationPointType2OrNull()
                    return if ns.nil?
                    NavigationPoint::navigationLambda(ns).call()
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
                "new #{NavigationPoint::ufn("Type1")}",
                lambda { 
                    ns1 = NSDataType1::issueNewCubeAndItsFirstFrameInteractivelyOrNull()
                    return if ns1.nil?
                    NSDataType1::landing(ns1)
                }
            )

            ms.item(
                "new #{NavigationPoint::ufn("Type2")}",
                lambda { 
                    ns2 = NSDataType2::issueNewPageInteractivelyOrNull()
                    return if ns2.nil?
                    NSDataType2::landing(ns2)
                }
            )

            ms.item(
                "merge two #{NavigationPoint::ufn("Type2")}s",
                lambda { 
                    puts "Merging two #{NavigationPoint::ufn("Type2")}s"
                    puts "Selecting one after the other and then will merge"
                    page1 = NavigationPointSelection::selectExistingNavigationPointType2OrNull()
                    return if page1.nil?
                    page2 = NavigationPointSelection::selectExistingNavigationPointType2OrNull()
                    return if page2.nil?
                    if page1["uuid"] == page2["uuid"] then
                        puts "You have selected the same #{NavigationPoint::ufn("Type2")} twice. Aborting merge operation."
                        LucilleCore::pressEnterToContinue()
                        return
                    end

                    # Moving all the page upstreams of page2 towards page 1
                    NavigationPoint::getUpstreamNavigationPoints(page2).each{|x|
                        puts "arrow (1): #{NavigationPoint::toString(x)} -> #{NavigationPoint::toString(page1)}"
                    }
                    # Moving all the downstreams of page2 toward page 1
                    NavigationPoint::getDownstreamNavigationPoints(page2).each{|x|
                        puts "arrow (2): #{NavigationPoint::toString(page1)} -> #{NavigationPoint::toString(x)}"
                    }

                    return if !LucilleCore::askQuestionAnswerAsBoolean("confirm merge : ")

                    # Moving all the page upstreams of page2 towards page 1
                    NavigationPoint::getUpstreamNavigationPoints(page2).each{|x|
                        Arrows::issueOrException(x, page1)
                    }
                    # Moving all the downstreams of page2 toward page 1
                    NavigationPoint::getDownstreamNavigationPoints(page2).each{|x|
                        Arrows::issueOrException(page1, x)
                    }
                    NyxObjects::destroy(page2)
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
                "Curation::run()", 
                lambda { Curation::run() }
            )

            ms.item(
                "Commit desk changes to primary repository", 
                lambda { DeskOperator::commitDeskChangesToPrimaryRepository() }
            )

            ms.item(
                "Drives::runShadowUpdate()", 
                lambda { Drives::runShadowUpdate() }
            )

            ms.item(
                "NyxGarbageCollection", 
                lambda { NyxGarbageCollection::run() }
            )

            ms.item(
                "Archive timeline garbage collection", 
                lambda { 
                    puts "#{EstateServices::getArchiveT1mel1neSizeInMegaBytes()} Mb"
                    EstateServices::binT1mel1neGarbageCollectionEnvelop(true)
                }
            )

            status = ms.prompt()
            break if !status
        }
    end
end


