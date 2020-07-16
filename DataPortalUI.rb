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
                "network navigation from [root]", 
                lambda { Cliques::cliqueNavigationView(Cliques::getRootClique()) }
            )

            ms.item(
                "cliques (listing)", 
                lambda { Cliques::cliquesListingAndDive() }
            )

            ms.item(
                "pages (listing)", 
                lambda { Pages::pagesListingAndDive() }
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
                                    lambda { Asteroids::asteroidDive(asteroid) }
                                )
                            }
                        status = menuitems.prompt()
                        break if !status
                    }
                }
            )

            puts ""

            ms.item(
                "clique (new)",
                lambda { 
                    description = LucilleCore::askQuestionAnswerAsString("clique name: ")
                    return if description == ""
                    Cliques::issueClique(description)
                }
            )

            ms.item(
                "page (new)",
                lambda { 
                    page = Pages::issueNewPageInteractively()
                    Pages::attachPageToZeroOrMoreCliquesInteractively(page)
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
                "merge two cliques",
                lambda { 
                    Cliques::interactivelySelectTwoCliquesAndMerge()
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
                lambda { 
                    CatalystObjectsOperator::generationSpeedReport()
                }
            )

            ms.item(
                "Run Shadow Update", 
                lambda { Drives::runShadowUpdate() }
            )

            ms.item(
                "Nyx curation", 
                lambda { Curation::run() }
            )

            ms.item(
                "Commit desk changes to primary repository", 
                lambda { DeskOperator::commitDeskChangesToPrimaryRepository() }
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


