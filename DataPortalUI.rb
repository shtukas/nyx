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

            puts ""

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
                "ns1 (new)",
                lambda { 
                    ns1 = NSDataType1::issueNewNSDataType1AndItsFirstNSDataType0InteractivelyOrNull()
                    return if ns1.nil?
                    NSDataType1::landing(ns1)
                }
            )

            ms.item(
                "ns2 (new)",
                lambda { 
                    ns2 = NSDataType2::issueNewNSDataType2InteractivelyOrNull()
                    return if ns2.nil?
                    NSDataType2::landing(ns2)
                }
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

            puts ""

            ms.item(
                "Asteroids",
                lambda { Asteroids::main() }
            )

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


