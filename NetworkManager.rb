
# encoding: UTF-8

class NetworkManager

    # NetworkManager::ensureReadiness()
    def self.ensureReadiness()

        # --------------------------------------------------------
        # We ensure that the "[root]" clique exists

        if Cliques::cliques().none?{|clique| Cliques::isRoot?(clique) } then
            # We do not have a [root] clique, going to create one
            puts "We do not have a [root] clique, going to create one"
            LucilleCore::pressEnterToContinue()
            Cliques::issueClique("[root]")
        end

        # --------------------------------------------------------
        # Make any clique that is not a target a target of root

        root = Cliques::getRootClique()
        if root.nil? then
            puts "[error: 8891f3b1] That's strange, I could not find the root clique 🤔"
            exit
        end
    end

    # NetworkManager::performSecondaryNetworkMaintenance()
    def self.performSecondaryNetworkMaintenance()

        # --------------------------------------------------------
        # Make any clique that is not a target a target of root

        root = Cliques::getRootClique()
        if root.nil? then
            puts "[error: bb9833e3] That's strange, I could not find the root clique 🤔"
            exit
        end

        Cliques::cliques().each{|clique|
            next if Cliques::isRoot?(clique) # we do not target the [root]
            next if Cliques::getCliqueNavigationSources(clique).size > 0
            # At this hypercube we have a clique which doesn't have any sources
            Arrows::issue(root, clique)
        }

        # --------------------------------------------------------
        # Make any clique that is a target of root and something else 
        # (meaning has more than one source)
        # is untargetted from [root]

        Cliques::getCliqueNavigationTargets(root).each{|clique|
            next if Cliques::isRoot?(clique) # we do not target the [root]
            next if Arrows::getSourcesOfGivenSetsForTarget(clique, ["4ebd0da9-6fe4-442e-81b9-eda8343fc1e5"]).size <= 1 # It would be pathologique if it was zero, because by this hypercube they should all have at least one source 
            Arrows::remove(root, clique)
        }
    end
end
