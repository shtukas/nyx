
# encoding: UTF-8

class Listings

    # Listings::makeNewNodeOrNull()
    def self.makeNewNodeOrNull()
        type = LucilleCore::selectEntityFromListOfEntitiesOrNull("type", ["ops listing", "encyclopedia node"])
        if type == "ops listing" then
            return OperationalListings::issueListingInteractivelyOrNull()
        end
        if type == "encyclopedia node" then
            return EncyclopediaListings::issueKnowledgeNodeInteractivelyOrNull()
        end
        nil
    end

    # Listings::selectExistingXNodeOrMakeANewXNodeOrNull()
    def self.selectExistingXNodeOrMakeANewXNodeOrNull()
        xnodes = OperationalListings::nodes() + EncyclopediaListings::nodes()
        xnode = LucilleCore::selectEntityFromListOfEntitiesOrNull("xnodes", xnodes, lambda { |xnode| GenericNyxObject::toString(xnode) })
        return xnode if xnode
        puts "You did not select an existing xnode"
        if LucilleCore::askQuestionAnswerAsBoolean("Would you like to create a new xnode ? ") then
            return Listings::makeNewNodeOrNull()
        end
        nil
    end

    # Listings::setNodeName(node, name_)
    def self.setNodeDescription(node, name_)
        if GenericNyxObject::isOpsNode(node) then
            node["name"] = name_
            NyxObjects2::put(node)
            return nil
        end
        if GenericNyxObject::isEncyclopediaNode(node) then
            node["name"] = name_
            NyxObjects2::put(node)
            return nil
        end
        puts node
        raise "error: db35548c-310b-485e-8ce0-2af23a93d02e"
    end
end