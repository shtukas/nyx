
# encoding: UTF-8

class Multiverse

    # Multiverse::universes()
    def self.universes()
        ["standard", "theguardian", "jedi"]
    end

    # Multiverse::interactivelySelectUniverseOrNull()
    def self.interactivelySelectUniverseOrNull()
        LucilleCore::selectEntityFromListOfEntitiesOrNull("universe", Multiverse::universes())
    end

    # Multiverse::interactivelySelectUniverse()
    def self.interactivelySelectUniverse()
        universe = LucilleCore::selectEntityFromListOfEntitiesOrNull("universe", Multiverse::universes())
        return Multiverse::interactivelySelectUniverse() if universe.nil?
        universe
    end
end

class UniverseStored

    # UniverseStored::setUniverse(universe or null)
    def self.setUniverse(universe)
        if universe.nil? then
            XCache::destroy("5117D42F-8542-4D74-A219-47AF3C58F22B")
            return
        end
        XCache::set("5117D42F-8542-4D74-A219-47AF3C58F22B", universe)
    end

    # UniverseStored::getUniverseOrNull()
    def self.getUniverseOrNull()
        XCache::getOrNull("5117D42F-8542-4D74-A219-47AF3C58F22B")
    end

    # UniverseStored::interactivelySetUniverse()
    def self.interactivelySetUniverse()
        universe = Multiverse::interactivelySelectUniverseOrNull()
        UniverseStored::setUniverse(universe)
    end
end
