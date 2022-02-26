
# encoding: UTF-8

class Multiverse

    # Multiverse::getObjectUniverseOrNull(uuid)
    def self.getObjectUniverseOrNull(uuid)
        universe = KeyValueStore::getOrNull("/Users/pascal/Galaxy/DataBank/Catalyst/Multiverse/kv-store", uuid)
        if universe == "eva" then
            universe = "xstream"
        end
        universe
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
        ["lucille", "beach", "xstream", "work", "jedi"]
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
end

class StoredUniverse

    # StoredUniverse::setStoredFocusUniverse(universe)
    def self.setStoredFocusUniverse(universe)
        KeyValueStore::set(nil, "5117D42F-8542-4D74-A219-47AF3C58F22B", universe)
    end

    # StoredUniverse::getStoredFocusUniverse()
    def self.getStoredFocusUniverse()
        universe = KeyValueStore::getOrNull(nil, "5117D42F-8542-4D74-A219-47AF3C58F22B")
        return universe if universe
        "lucille"
    end

    # StoredUniverse::interactivelySetStoredFocus()
    def self.interactivelySetStoredFocus()
        universe = Multiverse::interactivelySelectUniverse()
        StoredUniverse::setStoredFocusUniverse(universe)
    end

end

class UniverseAccounting

    # UniverseAccounting::universeToAccountNumber(universe)
    def self.universeToAccountNumber(universe)
        map = {
            "lucille" => "3b1a6d37-2c9c-4b75-bfca-be1fab1520d4",
            "beach"   => "12f07bbd-2831-4e7f-9e77-e7153e48805e",
            "xstream" => "0ee588ae-386f-40ab-a900-c3fe52b5ad59",
            "work"    => "acde7d70-2450-4d9d-a15b-13a427ac4023",
            "jedi"    => "ab282514-739b-4180-8064-8b800227fa5c"
        }
        map[universe]
    end

    # UniverseAccounting::addTimeToUniverse(universe, timespan)
    def self.addTimeToUniverse(universe, timespan)
        Bank::put(UniverseAccounting::universeToAccountNumber(universe), timespan)
    end

    # UniverseAccounting::universeRT(universe)
    def self.universeRT(universe)
        BankExtended::stdRecoveredDailyTimeInHours(UniverseAccounting::universeToAccountNumber(universe))
    end

    # UniverseAccounting::universeExpectationOrNull(universe)
    def self.universeExpectationOrNull(universe)
        map = {
            "lucille" => nil,
            "beach"   => 0.75,
            "xstream" => 1.5,
            "work"    => 6,
            "jedi"    => 2
        }
        map[universe]
    end

    # UniverseAccounting::universeRatioOrNull(universe)
    def self.universeRatioOrNull(universe)
        expectation = UniverseAccounting::universeExpectationOrNull(universe)
        return nil if expectation.nil?
        UniverseAccounting::universeRT(universe).to_f/expectation
    end

    # UniverseAccounting::getLowestRTUniverse()
    def self.getLowestRTUniverse()
        Multiverse::universes()
            .select{|universe|
                UniverseAccounting::universeExpectationOrNull(universe)
            }
            .sort{|u1, u2| UniverseAccounting::universeRatioOrNull(u1) <=> UniverseAccounting::universeRatioOrNull(u2) }
            .first
    end
end

class UniverseOperator

    # UniverseOperator::getUniverseTransitionMode()
    # USE-STORED
    def self.getUniverseTransitionMode()
        mode = KeyValueStore::getOrNull(nil, "f0fb2b0b-8478-4885-8acf-45b715c44c9b")
        return mode if mode
        "USE-STORED"
    end

    # UniverseOperator::getUniverseForDisplay()
    def self.getUniverseForDisplay()
        mode = UniverseOperator::getUniverseTransitionMode()
        if mode == "USE-STORED" then
            return StoredUniverse::getStoredFocusUniverse()
        end
        raise "1cd5718e-5bc5-4a18-8358-5f6bebc3d4cb"
    end

    # UniverseOperator::switchUniverseTransitionMode()
    def self.switchUniverseTransitionMode()

    end
end
