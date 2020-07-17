# encoding: UTF-8

class DataPortalUI
    # DataPortalUI::dataPortalFront()
    def self.dataPortalFront()
        loop {
            system("clear")

            ms = LCoreMenuItemsNX1.new()
            ms.item(
                "network navigation from [root]", 
                lambda { NSDataType3::landing(NSDataType3::getRootNSDataType3()) }
            )
            ms.item(
                "general search", 
                lambda { GeneralSearch::searchAndDive() }
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
                "ns3 (new)",
                lambda { 
                    description = LucilleCore::askQuestionAnswerAsString("ns3 name: ")
                    return if description == ""
                    ns3 = NSDataType3::issueNSDataType3(description)
                    NSDataType3::landing(ns3)
                }
            )

            ms.item(
                "ns2 (new)",
                lambda { 
                    ns2 = NSDataType2::issueNewNSDataType2Interactively()
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

            ms.item(
                "merge two ns3s",
                lambda { 
                    NSDataType3::interactivelySelectTwoNSDataType3sAndMerge()
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


