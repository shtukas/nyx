
# encoding: UTF-8

class Multiverse

    # Multiverse::getUniverseOrNull(uuid)
    def self.getUniverseOrNull(uuid)
        KeyValueStore::getOrNull("/Users/pascal/Galaxy/DataBank/Catalyst/Multiverse/kv-store", uuid)
    end

    # Multiverse::setUniverse(uuid, universe)
    def self.setUniverse(uuid, universe)
        KeyValueStore::set("/Users/pascal/Galaxy/DataBank/Catalyst/Multiverse/kv-store", uuid, universe)
    end

    # Multiverse::getUniverseOrDefault(uuid)
    def self.getUniverseOrDefault(uuid)
        universe = Multiverse::getUniverseOrNull(uuid)
        return universe if universe
        "eva"
    end

    # Multiverse::interactivelySelectUniverse()
    def self.interactivelySelectUniverse()
        universe = LucilleCore::selectEntityFromListOfEntitiesOrNull("universe", ["eva", "kyoko", "work", "jedi"])
        return Multiverse::interactivelySelectUniverse() if universe.nil?
        universe
    end

    # Multiverse::interactivelySetUniverse(uuid)
    def self.interactivelySetUniverse(uuid)
        universe = Multiverse::interactivelySelectUniverse()
        Multiverse::setUniverse(uuid, universe)
    end

    # Multiverse::setFocus(universe)
    def self.setFocus(universe)
        KeyValueStore::set(nil, "5117D42F-8542-4D74-A219-47AF3C58F22B", universe)
    end

    # Multiverse::getFocus()
    def self.getFocus()
        universe = KeyValueStore::getOrNull(nil, "5117D42F-8542-4D74-A219-47AF3C58F22B")
        return universe if universe
        "eva"
    end

    # Multiverse::interactivelySetFocus()
    def self.interactivelySetFocus()
        universe = Multiverse::interactivelySelectUniverse()
        Multiverse::setFocus(universe)
        puts "Focus set to #{universe}"
    end
end
