
# encoding: UTF-8

class NetworkManager

    # NetworkManager::ensureBasicConfiguration()
    def self.ensureBasicConfiguration()
        # We ensure that the "[root]" clique exists

        if Cliques::cliques().none?{|clique| Cliques::getCliqueDescriptionOrNull(clique) == "[root]" } then

            # We do not have a [root] clique, going to create one
            puts "We do not have a [root] clique, going to create one"
            LucilleCore::pressEnterToContinue()
            Cliques::issueClique("[root]")

        end

    end
end
