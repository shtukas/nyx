
class PolyActions

    # PolyActions::connect1(node, uuid)
    def self.connect1(node, uuid)
        linkeduuids = node["linkeduuids"] || []
        linkeduuids << uuid
        linkeduuids = linkeduuids.uniq
        Items::setAttribute(node["uuid"], "linkeduuids", linkeduuids)
    end

    # PolyActions::connect2(node, isSeekingSelect) # nil or node
    def self.connect2(node, isSeekingSelect)
        node2 = PolyFunctions::architectNodeOrNull()
        return nil if node2.nil?
        PolyActions::connect1(node, node2["uuid"])
        PolyActions::connect1(node2, node["uuid"])
        # We have connected node and node2
        # We are now going to land on it and get an opportunity to select it.
        Nx27::program(node2, isSeekingSelect)
    end

    # PolyActions::programGeneralItem(item, isSeekingSelect)
    def self.programGeneralItem(item, isSeekingSelect)
        if item["mikuType"] == "Nx27" then
            return Nx27::program(item, isSeekingSelect)
        end
        if item["mikuType"] == "Px44" then
            return Px44::programPx44(item)
        end
    end
end
