# encoding: UTF-8

class Catalyst

    # Catalyst::catalystItems()
    def self.catalystItems()
        Engine::itemsForMikuType("NxTodo") + Engine::itemsForMikuType("Wave")
    end
end
