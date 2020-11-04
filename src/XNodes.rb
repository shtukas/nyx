
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

    # XNodes::selectExistingXNodeOrMakeANewXNodeOrNull()
    def self.selectExistingXNodeOrMakeANewXNodeOrNull()
        xnodes = OpsListings::listings() + KnowledgeNodes::knowledgeNodes()
        type = LucilleCore::selectEntityFromListOfEntitiesOrNull("xnodes", xnodes, lambda { |xnode| GenericNyxObject::toString(xnode) })
        answer = nil
        if type == "ops listing" then
            answer = OpsListings::issueListingInteractivelyOrNull()
        end
        if type == "knowledge listing" then
            answer = KnowledgeNodes::issueKnowledgeNodeInteractivelyOrNull()
        end
        return answer if answer
        puts "You did not select an existing xnode"
        if LucilleCore::askQuestionAnswerAsBoolean("Would you like to create a new xnode ? ") then
            return XNodes::makeNewNodeOrNull()
        end
        nil
    end
end