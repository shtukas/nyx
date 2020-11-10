
# encoding: UTF-8

class XNodes

    # XNodes::makeNewNodeOrNull()
    def self.makeNewNodeOrNull()
        type = LucilleCore::selectEntityFromListOfEntitiesOrNull("type", ["ops listing", "encyclopedia node"])
        if type == "ops listing" then
            return OpsNodes::issueListingInteractivelyOrNull()
        end
        if type == "encyclopedia node" then
            return EncyclopediaNodes::issueKnowledgeNodeInteractivelyOrNull()
        end
        nil
    end

    # XNodes::selectExistingXNodeOrMakeANewXNodeOrNull()
    def self.selectExistingXNodeOrMakeANewXNodeOrNull()
        xnodes = OpsNodes::nodes() + EncyclopediaNodes::nodes()
        xnode = LucilleCore::selectEntityFromListOfEntitiesOrNull("xnodes", xnodes, lambda { |xnode| GenericNyxObject::toString(xnode) })
        return xnode if xnode
        puts "You did not select an existing xnode"
        if LucilleCore::askQuestionAnswerAsBoolean("Would you like to create a new xnode ? ") then
            return XNodes::makeNewNodeOrNull()
        end
        nil
    end

    # XNodes::setNodeName(node, name_)
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