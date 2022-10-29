
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

    # NetworkShapeAroundNode::interactivelySelectChildOrNull(uuid)
    def self.interactivelySelectChildOrNull(uuid)
        items = NetworkLocalViews::children(uuid).sort{|i1, i2| i1["datetime"] <=> i2["datetime"] }
        LucilleCore::selectEntityFromListOfEntitiesOrNull("child", items, lambda{ |item| PolyFunctions::toString(item) })
    end

    # NetworkShapeAroundNode::interactivelySelectParentOrNull(uuid)
    def self.interactivelySelectParentOrNull(uuid)
        items = NetworkLocalViews::parents(uuid).sort{|i1, i2| i1["datetime"] <=> i2["datetime"] }
        LucilleCore::selectEntityFromListOfEntitiesOrNull("parent", items, lambda{ |item| PolyFunctions::toString(item) })
    end

    # NetworkShapeAroundNode::interactivelySelectChildren(uuid)
    def self.interactivelySelectChildren(uuid)
        items = NetworkLocalViews::children(uuid).sort{|i1, i2| i1["datetime"] <=> i2["datetime"] }
        selected, unselected = LucilleCore::selectZeroOrMore("chidren", [], items, lambda{ |item| PolyFunctions::toString(item) })
        selected
    end

    # NetworkShapeAroundNode::interactivelySelectParents(uuid)
    def self.interactivelySelectParents(uuid)
        items = NetworkLocalViews::parents(uuid).sort{|i1, i2| i1["datetime"] <=> i2["datetime"] }
        selected, unselected = LucilleCore::selectZeroOrMore("parents", [], items, lambda{ |item| PolyFunctions::toString(item) })
        selected
    end

    # Select and recast

    # NetworkShapeAroundNode::selectParentsAndRecastAsChildren(item)
    def self.selectParentsAndRecastAsChildren(item)
        uuid = item["uuid"]
        entities = NetworkShapeAroundNode::interactivelySelectParents(uuid)
        return if entities.empty?
        entities.each{|entity|
            NetworkLocalViews::detach(entity["uuid"], item["uuid"])
            NetworkLocalViews::arrow(item["uuid"], entity["uuid"])
        }
    end

    # NetworkShapeAroundNode::selectParentsAndRecastAsRelated(item)
    def self.selectParentsAndRecastAsRelated(item)
        uuid = item["uuid"]
        entities = NetworkShapeAroundNode::interactivelySelectParents(uuid)
        return if entities.empty?
        entities.each{|entity|
            NetworkLocalViews::detach(entity["uuid"], item["uuid"])
            NetworkLocalViews::relate(item["uuid"], entity["uuid"])
        }
    end

    # NetworkShapeAroundNode::selectLinkedsAndRecastAsChildren(item)
    def self.selectLinkedsAndRecastAsChildren(item)
        uuid = item["uuid"]
        entities = NetworkShapeAroundNode::interactivelySelectRelatedEntities(uuid)
        return if entities.empty?
        entities.each{|child|
            NetworkLocalViews::detach(item["uuid"], child["uuid"])
        }
        entities.each{|child|
            NetworkLocalViews::arrow(item["uuid"], child["uuid"])
        }

    end

    # NetworkShapeAroundNode::selectLinkedAndRecastAsParents(item)
    def self.selectLinkedAndRecastAsParents(item)
        uuid = item["uuid"]
        entities = NetworkShapeAroundNode::interactivelySelectRelatedEntities(uuid)
        return if entities.empty?
        entities.each{|parent|
            NetworkLocalViews::detach(parent["uuid"], item["uuid"])
        }
        entities.each{|parent|
            NetworkLocalViews::arrow(parent["uuid"], item["uuid"])
        }
    end

    # NetworkShapeAroundNode::selectChildrenAndRecastAsRelated(item)
    def self.selectChildrenAndRecastAsRelated(item)
        uuid = item["uuid"]
        entities = NetworkShapeAroundNode::interactivelySelectChildren(uuid)
        return if entities.empty?
        entities.each{|child|
            NetworkLocalViews::detach(item["uuid"], child["uuid"])
        }
        entities.each{|child|
            NetworkLocalViews::relate(item["uuid"], child["uuid"])
        }
    end

    # Architecture

    # NetworkShapeAroundNode::architectureAndSetAsChild(item)
    def self.architectureAndSetAsChild(item)
        child = Nyx::architectOneOrNull()
        return if child.nil?
        NetworkLocalViews::arrow(item["uuid"], child["uuid"])
    end

    # NetworkShapeAroundNode::architectureAndSetAsParent(item)
    def self.architectureAndSetAsParent(item)
        parent = Nyx::architectOneOrNull()
        return if parent.nil?
        NetworkLocalViews::arrow(parent["uuid"], item["uuid"])
    end

    # Architecture

    # NetworkShapeAroundNode::selectChildrenAndSelectTargetChildAndMove(item)
    def self.selectChildrenAndSelectTargetChildAndMove(item)
        children = NetworkShapeAroundNode::interactivelySelectChildren(item["uuid"])
        theChild = NetworkShapeAroundNode::interactivelySelectChildOrNull(item["uuid"])
        children.each{|childX|
            NetworkLocalViews::detach(item["uuid"], childX["uuid"])
            NetworkLocalViews::arrow(theChild["uuid"], childX["uuid"])
        }
    end

    # NetworkShapeAroundNode::selectChildrenAndMoveToUUID(item)
    def self.selectChildrenAndMoveToUUID(item)
        children = NetworkShapeAroundNode::interactivelySelectChildren(item["uuid"])
        targetuuid = LucilleCore::askQuestionAnswerAsString("uuid: ")
        return if targetuuid == item["uuid"]
        targetitem = NetworkShapeAroundNode::getGenericNyxNetworkObjectOrNull(targetuuid)
        return if targetitem.nil?
        children.each{|childX|
            NetworkLocalViews::detach(item["uuid"], childX["uuid"])
            NetworkLocalViews::arrow(targetitem["uuid"], childX["uuid"])
        }
    end

    # NetworkShapeAroundNode::selectOneRelatedAndDetach(item)
    def self.selectOneRelatedAndDetach(item)
        store = ItemStore.new()

        NetworkLocalViews::relatedUUIDs(item["uuid"]) # .sort{|e1, e2| e1["datetime"]<=>e2["datetime"] }
            .each{|entityuuid|
                entity = NetworkShapeAroundNode::getGenericNyxNetworkObjectOrNull(entityuuid)
                next if entity.nil?
                indx = store.register(entity, false)
                puts "[#{indx.to_s.ljust(3)}] #{PolyFunctions::toString(entity)}"
            }

        i = LucilleCore::askQuestionAnswerAsString("> remove index (empty to exit): ")

        return if i == ""

        if (indx = Interpreting::readAsIntegerOrNull(i)) then
            entity = store.get(indx)
            return if entity.nil?
            NetworkLocalViews::detach(item["uuid"], entity["uuid"])
        end
    end

    # NetworkShapeAroundNode::architectureAndRelate(item)
    def self.architectureAndRelate(item)
        item2 = Nyx::architectOneOrNull()
        return if item2.nil?
        NetworkLocalViews::relate(item["uuid"], item2["uuid"])
    end

    # NetworkShapeAroundNode::interactivelySelectRelatedEntities(uuid)
    def self.interactivelySelectRelatedEntities(uuid)
        entities = NetworkLocalViews::relateds(uuid).sort{|e1, e2| e1["datetime"]<=>e2["datetime"] }
        selected, unselected = LucilleCore::selectZeroOrMore("entity", [], entities, lambda{ |item| PolyFunctions::toString(item) })
        selected
    end
end
