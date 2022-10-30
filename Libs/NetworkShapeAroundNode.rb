
class NetworkShapeAroundNode

    # NetworkShapeAroundNode::getGenericNyxNetworkObjectOrNull(uuid)
    def self.getGenericNyxNetworkObjectOrNull(uuid)
        item = Nx7::getItemOrNull(uuid)
        return item if item
        item = NxLines::getOrNull(uuid)
        return item if item
        nil
    end

    # Selection

    # NetworkShapeAroundNode::interactivelySelectChildOrNull(item)
    def self.interactivelySelectChildOrNull(item)
        items = Nx7::children(item).sort{|i1, i2| i1["datetime"] <=> i2["datetime"] }
        LucilleCore::selectEntityFromListOfEntitiesOrNull("child", items, lambda{ |item| PolyFunctions::toString(item) })
    end

    # NetworkShapeAroundNode::interactivelySelectParentOrNull(item)
    def self.interactivelySelectParentOrNull(item)
        items = Nx7::parents(item).sort{|i1, i2| i1["datetime"] <=> i2["datetime"] }
        LucilleCore::selectEntityFromListOfEntitiesOrNull("parent", items, lambda{ |item| PolyFunctions::toString(item) })
    end

    # NetworkShapeAroundNode::interactivelySelectChildren(item)
    def self.interactivelySelectChildren(item)
        items = Nx7::children(item).sort{|i1, i2| i1["datetime"] <=> i2["datetime"] }
        selected, unselected = LucilleCore::selectZeroOrMore("chidren", [], items, lambda{ |item| PolyFunctions::toString(item) })
        selected
    end

    # NetworkShapeAroundNode::interactivelySelectParents(item)
    def self.interactivelySelectParents(item)
        items = Nx7::parents(item).sort{|i1, i2| i1["datetime"] <=> i2["datetime"] }
        selected, unselected = LucilleCore::selectZeroOrMore("parents", [], items, lambda{ |item| PolyFunctions::toString(item) })
        selected
    end

    # Select and recast

    # NetworkShapeAroundNode::selectParentsAndRecastAsChildren(item)
    def self.selectParentsAndRecastAsChildren(item)
        uuid = item["uuid"]
        entities = NetworkShapeAroundNode::interactivelySelectParents(item)
        return if entities.empty?
        entities.each{|entity|
            Nx7::detach(entity, item)
            Nx7::arrow(item, entity)
        }
    end

    # NetworkShapeAroundNode::selectParentsAndRecastAsRelated(item)
    def self.selectParentsAndRecastAsRelated(item)
        uuid = item["uuid"]
        entities = NetworkShapeAroundNode::interactivelySelectParents(item)
        return if entities.empty?
        entities.each{|entity|
            Nx7::detach(entity, item)
            Nx7::relate(item, entity)
        }
    end

    # NetworkShapeAroundNode::selectLinkedsAndRecastAsChildren(item)
    def self.selectLinkedsAndRecastAsChildren(item)
        uuid = item["uuid"]
        entities = NetworkShapeAroundNode::interactivelySelectRelatedEntities(item)
        return if entities.empty?
        entities.each{|child|
            Nx7::detach(item, child)
        }
        entities.each{|child|
            Nx7::arrow(item, child)
        }

    end

    # NetworkShapeAroundNode::selectLinkedAndRecastAsParents(item)
    def self.selectLinkedAndRecastAsParents(item)
        uuid = item["uuid"]
        entities = NetworkShapeAroundNode::interactivelySelectRelatedEntities(item)
        return if entities.empty?
        entities.each{|parent|
            Nx7::detach(parent, item)
        }
        entities.each{|parent|
            Nx7::arrow(parent, item)
        }
    end

    # NetworkShapeAroundNode::selectChildrenAndRecastAsRelated(item)
    def self.selectChildrenAndRecastAsRelated(item)
        uuid = item["uuid"]
        entities = NetworkShapeAroundNode::interactivelySelectChildren(item)
        return if entities.empty?
        entities.each{|child|
            Nx7::detach(item, child)
        }
        entities.each{|child|
            Nx7::relate(item, child)
        }
    end

    # Architecture

    # NetworkShapeAroundNode::architectureAndSetAsChild(item)
    def self.architectureAndSetAsChild(item)
        child = Nyx::architectOneOrNull()
        return if child.nil?
        Nx7::arrow(item, child)
    end

    # NetworkShapeAroundNode::architectureAndSetAsParent(item)
    def self.architectureAndSetAsParent(item)
        parent = Nyx::architectOneOrNull()
        return if parent.nil?
        Nx7::arrow(parent, item)
    end

    # Architecture

    # NetworkShapeAroundNode::selectChildrenAndSelectTargetChildAndMove(item)
    def self.selectChildrenAndSelectTargetChildAndMove(item)
        children = NetworkShapeAroundNode::interactivelySelectChildren(item)
        theChild = NetworkShapeAroundNode::interactivelySelectChildOrNull(item)
        children.each{|childX|
            Nx7::detach(item, childX)
            Nx7::arrow(theChild, childX)
        }
    end

    # NetworkShapeAroundNode::selectChildrenAndMoveToUUID(item)
    def self.selectChildrenAndMoveToUUID(item)
        children = NetworkShapeAroundNode::interactivelySelectChildren(item)
        targetuuid = LucilleCore::askQuestionAnswerAsString("uuid: ")
        return if targetuuid == item["uuid"]
        targetitem = NetworkShapeAroundNode::getGenericNyxNetworkObjectOrNull(targetuuid)
        return if targetitem.nil?
        children.each{|childX|
            Nx7::detach(item, childX)
            Nx7::arrow(targetitem, childX)
        }
    end

    # NetworkShapeAroundNode::selectOneRelatedAndDetach(item)
    def self.selectOneRelatedAndDetach(item)
        store = ItemStore.new()

        Nx7::relateds(item)
            .sort{|e1, e2| e1["datetime"]<=>e2["datetime"] }
            .each{|entity|
                indx = store.register(entity, false)
                puts "[#{indx.to_s.ljust(3)}] #{PolyFunctions::toString(entity)}"
            }

        i = LucilleCore::askQuestionAnswerAsString("> remove index (empty to exit): ")

        return if i == ""

        if (indx = Interpreting::readAsIntegerOrNull(i)) then
            entity = store.get(indx)
            return if entity.nil?
            Nx7::detach(item, entity)
        end
    end

    # NetworkShapeAroundNode::architectureAndRelate(item)
    def self.architectureAndRelate(item)
        item2 = Nyx::architectOneOrNull()
        return if item2.nil?
        Nx7::relate(item item2)
    end

    # NetworkShapeAroundNode::interactivelySelectRelatedEntities(item)
    def self.interactivelySelectRelatedEntities(item)
        entities = Nx7::relateds(item).sort{|e1, e2| e1["datetime"]<=>e2["datetime"] }
        selected, unselected = LucilleCore::selectZeroOrMore("entity", [], entities, lambda{ |item| PolyFunctions::toString(item) })
        selected
    end
end
