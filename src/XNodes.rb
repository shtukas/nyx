
# encoding: UTF-8

class XNodes

    # XNodes::makeNewNodeOrNull()
    def self.makeNewNodeOrNull()
        type = LucilleCore::selectEntityFromListOfEntitiesOrNull("type", ["ops listing", "knowledge listing"])
        if type == "ops listing" then
            return OpsListings::issueListingInteractivelyOrNull()
        end
        if type == "knowledge listing" then
            return KnowledgeNodes::issueKnowledgeNodeInteractivelyOrNull()
        end
        nil
    end
end