# encoding: UTF-8

class Catalyst

    # Catalyst::catalystItems()
    def self.catalystItems()
        NxTodos::items() + Waves::items()
    end

    # Catalyst::getCatalystItemOrNull(uuid)
    def self.getCatalystItemOrNull(uuid)
        item = Waves::getOrNull(uuid)
        return item if item

        item = NxTodos::getItemOrNull(uuid)
        return item if item

        item = Cx22::getOrNull(uuid)
        return item if item

        nil
    end
end
