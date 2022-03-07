
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

class ObjectUniverseMapping

    # ObjectUniverseMapping::getObjectUniverseMappingOrNull(uuid)
    def self.getObjectUniverseMappingOrNull(uuid)
        universe = KeyValueStore::getOrNull("/Users/pascal/Galaxy/DataBank/Catalyst/Multiverse/kv-store", uuid)
        if universe == "eva" then
            puts "updating outdated universe attribution from eva to backlog"
            universe = "backlog"
            ObjectUniverseMapping::setObjectUniverseMapping(uuid, "backlog")
        end
        if universe == "beach" then
            puts "updating outdated universe attribution from beach to backlog"
            universe = "backlog"
            ObjectUniverseMapping::setObjectUniverseMapping(uuid, "backlog")
        end
        if universe == "xstream" then
            puts "updating outdated universe attribution from xstream to backlog"
            universe = "backlog"
            ObjectUniverseMapping::setObjectUniverseMapping(uuid, "backlog")
        end
        if universe == "jedi" then
            puts "updating outdated universe attribution from jedi to backlog"
            universe = "backlog"
            ObjectUniverseMapping::setObjectUniverseMapping(uuid, "backlog")
        end
        if !Multiverse::universes().include?(universe) then
            universe = nil
            KeyValueStore::destroy("/Users/pascal/Galaxy/DataBank/Catalyst/Multiverse/kv-store", uuid)
        end
        universe
    end

    # ObjectUniverseMapping::setObjectUniverseMapping(uuid, universe)
    def self.setObjectUniverseMapping(uuid, universe)
        raise "(error: incorrect universe: #{universe})" if !Multiverse::universes().include?(universe)
        KeyValueStore::set("/Users/pascal/Galaxy/DataBank/Catalyst/Multiverse/kv-store", uuid, universe)
    end

    # ObjectUniverseMapping::interactivelySetObjectUniverseMapping(uuid)
    def self.interactivelySetObjectUniverseMapping(uuid)
        universe = Multiverse::interactivelySelectUniverseOrNull()
        if universe then
            ObjectUniverseMapping::setObjectUniverseMapping(uuid, universe)
        else
            KeyValueStore::destroy("/Users/pascal/Galaxy/DataBank/Catalyst/Multiverse/kv-store", uuid)
        end
    end
end

class StoredUniverse

    # StoredUniverse::setUniverse(universe)
    def self.setUniverse(universe)
        KeyValueStore::set(nil, "5117D42F-8542-4D74-A219-47AF3C58F22B", universe)
    end

    # StoredUniverse::getUniverseOrNull()
    def self.getUniverseOrNull()
        KeyValueStore::getOrNull(nil, "5117D42F-8542-4D74-A219-47AF3C58F22B")
    end

    # StoredUniverse::interactivelySetUniverseOrUnsetUniverse()
    def self.interactivelySetUniverseOrUnsetUniverse()
        universe = LucilleCore::selectEntityFromListOfEntitiesOrNull("universe", Multiverse::universes())
        if universe.nil? then
            KeyValueStore::destroy(nil, "5117D42F-8542-4D74-A219-47AF3C58F22B")
            return nil
        end
        StoredUniverse::setUniverse(universe)
    end
end

class UniverseAccounting

    # UniverseAccounting::universeToAccountNumberOrNull(universe)
    def self.universeToAccountNumberOrNull(universe)
        return nil if universe.nil?
        map = {
            "beach"   => "12f07bbd-2831-4e7f-9e77-e7153e48805e",
            "backlog" => "0ee588ae-386f-40ab-a900-c3fe52b5ad59",
            "work"    => "acde7d70-2450-4d9d-a15b-13a427ac4023"
        }
        map[universe]
    end

    # UniverseAccounting::addTimeToUniverse(universe, timespan)
    def self.addTimeToUniverse(universe, timespan)
        Bank::put(UniverseAccounting::universeToAccountNumberOrNull(universe), timespan)
    end

    # UniverseAccounting::universeRT(universe)
    def self.universeRT(universe)
        BankExtended::stdRecoveredDailyTimeInHours(UniverseAccounting::universeToAccountNumberOrNull(universe))
    end

    # UniverseAccounting::universeExpectationOrNull(universe)
    def self.universeExpectationOrNull(universe)
        map = {
            "backlog" => 4,
            "work"    => 6,
        }
        map[universe]
    end

    # UniverseAccounting::universeRatioOrNull(universe)
    def self.universeRatioOrNull(universe)
        expectation = UniverseAccounting::universeExpectationOrNull(universe)
        return nil if expectation.nil?
        UniverseAccounting::universeRT(universe).to_f/expectation
    end

    # UniverseAccounting::getExpectationUniversesInRatioOrder()
    def self.getExpectationUniversesInRatioOrder()
        Multiverse::universes()
            .select{|universe| UniverseAccounting::universeExpectationOrNull(universe) }
            .sort{|u1, u2| UniverseAccounting::universeRatioOrNull(u1) <=> UniverseAccounting::universeRatioOrNull(u2) }
    end

    # UniverseAccounting::getExpectationUniversesInRatioOrder2(universes)
    def self.getExpectationUniversesInRatioOrder2(universes)
        universes
            .select{|universe| UniverseAccounting::universeExpectationOrNull(universe) }
            .sort{|u1, u2| UniverseAccounting::universeRatioOrNull(u1) <=> UniverseAccounting::universeRatioOrNull(u2) }
    end
end
