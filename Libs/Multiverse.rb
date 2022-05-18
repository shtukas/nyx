
# encoding: UTF-8

class Multiverse

    # Multiverse::universes()
    def self.universes()
        ["backlog", "work"]
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

class StoredUniverse

    # StoredUniverse::setUniverse(universe or null)
    def self.setUniverse(universe)
        if universe.nil? then
            XCache::destroy("5117D42F-8542-4D74-A219-47AF3C58F22B")
            return
        end
        XCache::set("5117D42F-8542-4D74-A219-47AF3C58F22B", universe)
    end

    # StoredUniverse::getUniverseOrNull()
    def self.getUniverseOrNull()
        XCache::getOrNull("5117D42F-8542-4D74-A219-47AF3C58F22B")
    end

    # StoredUniverse::interactivelySetUniverse()
    def self.interactivelySetUniverse()
        universe = Multiverse::interactivelySelectUniverse()
        StoredUniverse::setUniverse(universe)
    end
end

class UniverseMonitor

    # UniverseMonitor::naturalUniverseForThisTime()
    def self.naturalUniverseForThisTime()
        "work"
    end

    # UniverseMonitor::listingMessageOrNull()
    def self.listingMessageOrNull()
        universe = UniverseMonitor::naturalUniverseForThisTime()
        if universe != StoredUniverse::getUniverseOrNull() then
            "We should be on universe #{universe}"
        else
            nil
        end
    end
end
