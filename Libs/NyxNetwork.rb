# encoding: UTF-8

class NyxNetwork

    # NyxNetwork::selectEntityFromGivenEntitiesOrNull(items)
    def self.selectEntityFromGivenEntitiesOrNull(items)
        item = Utils::selectOneObjectUsingInteractiveInterfaceOrNull(items, lambda{|item| LxFunction::function("toString", item) })
        return nil if item.nil?
        item
    end

    # NyxNetwork::selectExistingNetworkElementOrNull()
    def self.selectExistingNetworkElementOrNull()
        nx20 = Search::interativeInterfaceSelectNx20OrNull()
        return nil if nx20.nil?
        nx20["payload"]
    end

    # NyxNetwork::interactivelyMakeNewOrNull()
    def self.interactivelyMakeNewOrNull()
        Nx100s::interactivelyIssueNewItemOrNull()
    end

    # NyxNetwork::architectOneOrNull()
    def self.architectOneOrNull()
        operations = ["existing || new", "new"]
        operation = LucilleCore::selectEntityFromListOfEntitiesOrNull("operation", operations)
        return nil if operation.nil?
        if operation == "existing || new" then
            puts "-> existing"
            sleep 1
            entity = NyxNetwork::selectExistingNetworkElementOrNull()
            return entity if entity
            puts "-> new"
            sleep 1
            return NyxNetwork::interactivelyMakeNewOrNull()
        end
        if operation == "new" then
            return NyxNetwork::interactivelyMakeNewOrNull()
        end
    end

    # NyxNetwork::architectMultiple()
    def self.architectMultiple()
        operations = ["existing || new", "new", "use stack"]
        operation = LucilleCore::selectEntityFromListOfEntitiesOrNull("operation", operations)
        return [] if operation.nil?
        if operation == "existing || new" then
            puts "-> existing"
            sleep 1
            entity = NyxNetwork::selectExistingNetworkElementOrNull()
            return [entity] if entity
            puts "-> new"
            sleep 1
            return [NyxNetwork::interactivelyMakeNewOrNull()].compact
        end
        if operation == "new" then
            return [NyxNetwork::interactivelyMakeNewOrNull()].compact
        end
        if operation == "use stack" then
            selected, unselected = LucilleCore::selectZeroOrMore("item", [], TheNetworkStack::getStack(), lambda{ |i| LxFunction::function("toString", i) })
            return selected
        end
    end

    # NyxNetwork::linkToDesignatedOther(item, other)
    def self.linkToDesignatedOther(item, other)
        connectionType = LucilleCore::selectEntityFromListOfEntitiesOrNull("connection type", ["other is parent", "other is related (default)", "other is child"])
        if connectionType.nil? or connectionType == "other is related (default)" then
            Links::link(item["uuid"], other["uuid"], true)
        end
        if connectionType == "other is parent" then
            Links::link(other["uuid"], item["uuid"], false)
        end
        if connectionType == "other is child" then
            Links::link(item["uuid"], other["uuid"], false)
        end
    end

    # NyxNetwork::connectToOneOrMoreOthersArchitectured(item)
    def self.connectToOneOrMoreOthersArchitectured(item)
        connectionType = LucilleCore::selectEntityFromListOfEntitiesOrNull("connection type", ["other is parent", "other is related", "other is child"])
        return if connectionType.nil?
        NyxNetwork::architectMultiple().each{|other|
            if connectionType == "other is parent" then
                Links::link(other["uuid"], item["uuid"], false)
            end
            if connectionType == "other is related" then
                Links::link(item["uuid"], other["uuid"], true)
            end
            if connectionType == "other is child" then
                Links::link(item["uuid"], other["uuid"], false)
            end
        }
    end

    # NyxNetwork::crelinkToOneOrMoreLinked(item)
    def self.relinkToOneOrMoreLinked(item)
        entities = Links::linked(item["uuid"])
                    .sort{|e1, e2| e1["datetime"]<=>e2["datetime"] }
        selected, unselected = LucilleCore::selectZeroOrMore("linked", [], entities, lambda{ |i| LxFunction::function("toString", i) })

        connectionType = LucilleCore::selectEntityFromListOfEntitiesOrNull("connection type", ["other is parent", "other is related", "other is child"])
        return if connectionType.nil?

        selected.each{|other|
            Links::unlink(item["uuid"], other["uuid"])
            if connectionType == "other is parent" then
                Links::link(other["uuid"], item["uuid"], false)
            end
            if connectionType == "other is related" then
                Links::link(item["uuid"], other["uuid"], true)
            end
            if connectionType == "other is child" then
                Links::link(item["uuid"], other["uuid"], false)
            end
        }
    end

    # NyxNetwork::disconnectFromLinkedInteractively(item)
    def self.disconnectFromLinkedInteractively(item)
        entities = Links::linked(item["uuid"])
                    .sort{|e1, e2| e1["datetime"]<=>e2["datetime"] }
        selected, _ = LucilleCore::selectZeroOrMore("item", [], entities, lambda{ |i| LxFunction::function("toString", i) })
        selected.each{|other|
            Links::unlink(item["uuid"], other["uuid"])
        }
    end
end
