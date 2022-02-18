
# encoding: UTF-8

class Multiverse

    # Multiverse::getObjectUniverseOrNull(uuid)
    def self.getObjectUniverseOrNull(uuid)
        KeyValueStore::getOrNull("/Users/pascal/Galaxy/DataBank/Catalyst/Multiverse/kv-store", uuid)
    end

    # Multiverse::setObjectUniverse(uuid, universe)
    def self.setObjectUniverse(uuid, universe)
        raise "(error: incorrect universe: #{universe})" if !Multiverse::universes().include?(universe)
        KeyValueStore::set("/Users/pascal/Galaxy/DataBank/Catalyst/Multiverse/kv-store", uuid, universe)
    end

    # Multiverse::getUniverseOrDefault(uuid)
    def self.getUniverseOrDefault(uuid)
        universe = Multiverse::getObjectUniverseOrNull(uuid)
        return universe if universe
        "lucille"
    end

    # Multiverse::universes()
    def self.universes()
        ["lucille", "eva", "work", "jedi"]
    end

    # Multiverse::interactivelySelectUniverse()
    def self.interactivelySelectUniverse()
        universe = LucilleCore::selectEntityFromListOfEntitiesOrNull("universe", Multiverse::universes())
        return Multiverse::interactivelySelectUniverse() if universe.nil?
        universe
    end

    # Multiverse::interactivelySetObjectUniverse(uuid)
    def self.interactivelySetObjectUniverse(uuid)
        universe = Multiverse::interactivelySelectUniverse()
        Multiverse::setObjectUniverse(uuid, universe)
    end

    # Multiverse::setFocus(universe)
    def self.setFocus(universe)
        KeyValueStore::set(nil, "5117D42F-8542-4D74-A219-47AF3C58F22B", universe)
    end

    # Multiverse::getFocus()
    def self.getFocus()
        universe = KeyValueStore::getOrNull(nil, "5117D42F-8542-4D74-A219-47AF3C58F22B")
        return universe if universe
        "lucille"
    end

    # Multiverse::interactivelySetFocus()
    def self.interactivelySetFocus()
        universe = Multiverse::interactivelySelectUniverse()
        Multiverse::setFocus(universe)
    end
end
