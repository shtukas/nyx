
# Nodes is a more abstract concept than ItemsDatabase, it is used to refer to both
# Nx27s or Fx35s, regardless of how they are stored.

class Nodes

    # Nodes::itemOrNull(uuid)
    def self.itemOrNull(uuid)
        entry = Nodes::entryOrNull(uuid)
        return nil if entry.nil?
        entry["item"]
    end

    # Nodes::commitItem(item)
    def self.commitItem(item)

    end

    # Nodes::setAttribute(uuid, attrname, attrvalue)
    def self.setAttribute(uuid, attrname, attrvalue)

    end

    # Nodes::nodes()
    def self.nodes()

    end

    # Nodes::deleteItem(uuid)
    def self.deleteItem(uuid)

    end
end
