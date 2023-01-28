# encoding: UTF-8

class Catalyst

    # Catalyst::catalystItems()
    def self.catalystItems()
        Database2Data::itemsForMikuType("NxTodo") + Database2Data::itemsForMikuType("Wave")
    end
end
