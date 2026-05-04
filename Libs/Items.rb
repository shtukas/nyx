
# encoding: UTF-8

class Items
    # Items::setAttribute(uuid, attribute_name, attribute_value) # -> updated Item
    def self.setAttribute(uuid, attribute_name, attribute_value)
        item = Index::getItemOrNull(uuid)
        return if item.nil?
        item[attribute_name] = attribute_value
        Index::commitItem(item)
        item
    end
end
