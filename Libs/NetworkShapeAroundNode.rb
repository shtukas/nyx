
class NetworkShapeAroundNode

    # Selection

    # NetworkShapeAroundNode::interactivelySelectChildOrNull(uuid)
    def self.interactivelySelectChildOrNull(uuid)
        LucilleCore::selectEntityFromListOfEntitiesOrNull("child", NetworkArrows::children(uuid), lambda{ |item| PolyFunctions::toString(item) })
    end

    # NetworkShapeAroundNode::interactivelySelectParentOrNull(uuid)
    def self.interactivelySelectParentOrNull(uuid)
        LucilleCore::selectEntityFromListOfEntitiesOrNull("parent", NetworkArrows::parents(uuid), lambda{ |item| PolyFunctions::toString(item) })
    end

    # NetworkShapeAroundNode::interactivelySelectChildren(uuid)
    def self.interactivelySelectChildren(uuid)
        selected, unselected = LucilleCore::selectZeroOrMore("chidren", [], NetworkArrows::children(uuid), lambda{ |item| PolyFunctions::toString(item) })
        selected
    end

    # NetworkShapeAroundNode::interactivelySelectParents(uuid)
    def self.interactivelySelectParents(uuid)
        selected, unselected = LucilleCore::selectZeroOrMore("parents", [], NetworkArrows::parents(uuid), lambda{ |item| PolyFunctions::toString(item) })
        selected
    end

    # Select and recast

    # NetworkShapeAroundNode::selectParentsAndRecastAsChildren(item)
    def self.selectParentsAndRecastAsChildren(item)
        uuid = item["uuid"]
        entities = NetworkShapeAroundNode::interactivelySelectParents(uuid)
        return if entities.empty?
        entities.each{|entity|
            NetworkArrows::unlink(entity["uuid"], item["uuid"])
            NetworkArrows::link(item["uuid"], entity["uuid"])
        }
    end

    # NetworkShapeAroundNode::selectParentsAndRecastAsRelated(item)
    def self.selectParentsAndRecastAsRelated(item)
        uuid = item["uuid"]
        entities = NetworkShapeAroundNode::interactivelySelectParents(uuid)
        return if entities.empty?
        entities.each{|entity|
            NetworkArrows::unlink(entity["uuid"], item["uuid"])
            NetworkLinks::link(item["uuid"], entity["uuid"])
        }
    end

    # NetworkShapeAroundNode::selectLinkedsAndRecastAsChildren(item)
    def self.selectLinkedsAndRecastAsChildren(item)
        uuid = item["uuid"]
        entities = NetworkLinks::interactivelySelectLinkedEntities(uuid)
        return if entities.empty?
        entities.each{|child|
            NetworkArrows::link(item["uuid"], child["uuid"])
        }
        entities.each{|child|
            NetworkLinks::unlink(item["uuid"], child["uuid"])
        }
    end

    # NetworkShapeAroundNode::selectLinkedAndRecastAsParents(item)
    def self.selectLinkedAndRecastAsParents(item)
        uuid = item["uuid"]
        entities = NetworkLinks::interactivelySelectLinkedEntities(uuid)
        return if entities.empty?
        entities.each{|parent|
            NetworkArrows::link(parent["uuid"], item["uuid"])
        }
        entities.each{|parent|
            NetworkLinks::unlink(parent["uuid"], item["uuid"])
        }
    end

    # Architecture

    # NetworkShapeAroundNode::architectureAndSetAsChild(item)
    def self.architectureAndSetAsChild(item)
        child = Nyx::architectOneOrNull()
        return if child.nil?
        NetworkArrows::link(item["uuid"], child["uuid"])
    end

    # NetworkShapeAroundNode::architectureAndSetAsParent(item)
    def self.architectureAndSetAsParent(item)
        parent = Nyx::architectOneOrNull()
        return if parent.nil?
        NetworkArrows::link(parent["uuid"], item["uuid"])
    end

    # Architecture

    # NetworkShapeAroundNode::selectChildrenAndSelectTargetChildAndMove(item)
    def self.selectChildrenAndSelectTargetChildAndMove(item)
        children = NetworkShapeAroundNode::interactivelySelectChildren(item["uuid"])
        theChild = NetworkShapeAroundNode::interactivelySelectChildOrNull(item["uuid"])
        children.each{|childX|
            NetworkArrows::link(theChild["uuid"], childX["uuid"])
            NetworkArrows::unlink(item["uuid"], childX["uuid"])
        }
    end
end
