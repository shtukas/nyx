
# encoding: UTF-8

$InMemoryItems9ECED108 = nil

class Items

    # Items::ensureItems()
    def self.ensureItems()
        # This function just ensures that 
        if $InMemoryItems9ECED108.nil? then
            puts "loading items to memory".yellow
            $InMemoryItems9ECED108 = Index::getItems()
        end
    end

    # ---------------------------------------------

    # Items::commitItem returns an item, because it may not be the item that 
    # was submitted, in case we had to do a reconciliation
    # Items::commitItem(item) -> Item
    def self.commitItem(item)
        # Here we need to send the item to disk and update the in memory dataset

        # Index::commitItem returns an item, because it may not be the item that 
        # was submitted, in case we had to do a reconciliation
        item = Index::commitItem(item)

        if $InMemoryItems9ECED108 then
            $InMemoryItems9ECED108 = $InMemoryItems9ECED108.reject{|i| i["uuid"] == item["uuid"] } + [item]
        end

        item
    end

    # Items::getItems()
    def self.getItems()
        Items::ensureItems()
        $InMemoryItems9ECED108.clone()
    end

    # Items::getItemOrNull(uuid)
    def self.getItemOrNull(uuid)
        Items::ensureItems()
        $InMemoryItems9ECED108.select{|i| i["uuid"] == uuid }.first
    end

    # Items::init(uuid)
    def self.init(uuid)
        item = {
            "uuid" => uuid,
            "mikuType" => "NxDeleted",
            "unixtime" => Time.new.to_i
        }
        Items::commitItem(item)
        Items::ensureItems()
        $InMemoryItems9ECED108 = $InMemoryItems9ECED108 + [item]
    end

    # Items::getMikuType(mikuType)
    def self.getMikuType(mikuType)
        Items::ensureItems()
        $InMemoryItems9ECED108.select{|i| i["mikuType"] == mikuType }
    end

    # Items::setAttribute returns an item, because it may not be the item that 
    # was submitted, in case we had to do a reconciliation
    # Items::setAttribute(uuid, attribute_name, attribute_value) # -> updated Item
    def self.setAttribute(uuid, attribute_name, attribute_value)
        item = Items::getItemOrNull(uuid)
        return if item.nil?

        item[attribute_name] = attribute_value
        # Index::commitItem returns an item, because it may not be the item that 
        # was submitted, in case we had to do a reconciliation
        item = Items::commitItem(item)

        item
    end

    # Items::deleteItem(uuid)
    def self.deleteItem(uuid)
        Index::deleteItem(uuid)
        if $InMemoryItems9ECED108 then
            $InMemoryItems9ECED108 = $InMemoryItems9ECED108.reject{|i| i["uuid"] == uuid }
        end
    end
end
