# encoding: UTF-8

class Catalyst

    # Catalyst::catalystItems()
    def self.catalystItems()
        NxTodosIO::items() + TodoDatabase2::itemsForMikuType("Wave")
    end
end
