# encoding: UTF-8

class Catalyst

    # Catalyst::catalystItems()
    def self.catalystItems()
        NxTodosIO::items() + Database2Data::itemsForMikuType("Wave")
    end
end
