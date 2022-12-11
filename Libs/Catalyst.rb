# encoding: UTF-8

class Catalyst

    # Catalyst::catalystItems()
    def self.catalystItems()
        ItemsManager::items("NxTodo") + ItemsManager::items("Wave")
    end

    # Catalyst::getCatalystItemOrNull(uuid)
    def self.getCatalystItemOrNull(uuid)

        item = ItemsManager::getOrNull("NxTriage", uuid)
        return item if item

        item = NxOnDates::getItemOrNull(uuid)
        return item if item

        item = ItemsManager::getOrNull("Wave", uuid)
        return item if item

        item = ItemsManager::getOrNull("NxTodo", uuid)
        return item if item

        nil
    end
end
