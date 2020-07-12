
# encoding: UTF-8

class NetworkManager

    # NetworkManager::ensureBasicConfiguration()
    def self.ensureBasicConfiguration()

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
            puts "That's strange, I could not find the root clique 🤔"
            LucilleCore::pressEnterToContinue()
            return
        end
        Cliques::cliques().each{|clique|
            next if Cliques::isRoot?(clique) # we do not target the [root]
            next if TaxonomyArrows::getSourcesForTarget(clique).size > 0
            # At this point we have a clique which doesn't have any sources
            puts "Issuing Taxonomy arrow [root] -> #{Cliques::cliqueToString(clique)}"
            LucilleCore::pressEnterToContinue()
            TaxonomyArrows::issue(root, clique)
        }

        # --------------------------------------------------------
        # Make any clique that is a target of root and something else 
        # (meaning has more than one source)
        # is untargetted from [root]

        TaxonomyArrows::getTargetsForSource(root).each{|clique|
            next if Cliques::isRoot?(clique) # we do not target the [root]
            next if TaxonomyArrows::getSourcesForTarget(clique).size <= 1 # It would be pathologique if it was zero, because by this point they should all have at least one source 
            puts "Removing Taxonomy arrow [root] -> #{Cliques::cliqueToString(clique)}"
            LucilleCore::pressEnterToContinue()
            TaxonomyArrows::destroyArrow(root, clique)
        }

    end
end
