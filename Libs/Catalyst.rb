# encoding: UTF-8

class Catalyst

    # Catalyst::catalystItems()
    def self.catalystItems()
        NxTodosIO::items() + TodoDatabase2::itemsForMikuType("Wave")
    end

    # Catalyst::getCatalystItemOrNull(uuid)
    def self.getCatalystItemOrNull(uuid)

        item = TodoDatabase2::getObjectByUUIDOrNull(uuid)
        return item if item

        item = NxOndates::getOrNull(uuid)
        return item if item

        item = TodoDatabase2::getObjectByUUIDOrNull(uuid)
        return item if item

        item = NxTodosIO::getOrNull(uuid)
        return item if item

        nil
    end
end
