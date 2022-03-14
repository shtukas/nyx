
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

    # sqlite> create table _mapping_ (_objectuuid_ text primary key, universe _text_);

    # ObjectUniverseMapping::databaseFilepath()
    def self.databaseFilepath()
        "/Users/pascal/Galaxy/DataBank/Catalyst/universemapping.sqlite3"
    end

    # ObjectUniverseMapping::getObjectUniverseMappingOrNull(uuid)
    def self.getObjectUniverseMappingOrNull(uuid)

        db = SQLite3::Database.new(ObjectUniverseMapping::databaseFilepath())
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        answer = nil
        db.execute("select * from _mapping_ where _objectuuid_=?", [uuid]) do |row|
            answer = row["universe"]
        end
        db.close
        answer
    end

    # ObjectUniverseMapping::setObjectUniverseMapping(uuid, universe)
    def self.setObjectUniverseMapping(uuid, universe)
        raise "(error: incorrect universe: #{universe})" if !Multiverse::universes().include?(universe)
        db = SQLite3::Database.new(ObjectUniverseMapping::databaseFilepath())
        db.execute "delete from _mapping_ where _objectuuid_=?", [uuid]
        db.execute "insert into _mapping_ (_objectuuid_, universe) values (?,?)", [uuid, universe]
        db.close
    end

    # ObjectUniverseMapping::unset(uuid)
    def self.unset(uuid)
        db = SQLite3::Database.new(ObjectUniverseMapping::databaseFilepath())
        db.execute "delete from _mapping_ where _objectuuid_=?", [uuid]
        db.close
    end

    # ObjectUniverseMapping::interactivelySetObjectUniverseMapping(uuid)
    def self.interactivelySetObjectUniverseMapping(uuid)
        universe = Multiverse::interactivelySelectUniverseOrNull()
        if universe then
            ObjectUniverseMapping::setObjectUniverseMapping(uuid, universe)
        else
            ObjectUniverseMapping::unset(uuid)
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

class UniverseDrivingModes

    # UniverseDrivingModes::modes()
    def self.modes()
        [
            "stored universe",
            "assisted switching"
        ]
    end

    # UniverseDrivingModes::interactivelySetMode()
    def self.interactivelySetMode()
        mode = LucilleCore::selectEntityFromListOfEntitiesOrNull("mode", UniverseDrivingModes::modes())
        return if mode.nil? 
        KeyValueStore::set(nil, "d8c104ea-f64c-4280-99b4-c8d636856ed9", mode)
    end

    # UniverseDrivingModes::getStoredMode()
    def self.getStoredMode()
        default = "stored universe"
        mode = KeyValueStore::getOrDefaultValue(nil, "d8c104ea-f64c-4280-99b4-c8d636856ed9", default)
        if !UniverseDrivingModes::modes().include?(mode) then
            mode = default
        end
        mode
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
            "backlog" => 5,
            "work"    => 5,
        }
        map[universe]
    end

    # UniverseAccounting::universeRatioOrNull(universe)
    def self.universeRatioOrNull(universe)
        expectation = UniverseAccounting::universeExpectationOrNull(universe)
        return nil if expectation.nil?
        UniverseAccounting::universeRT(universe).to_f/expectation
    end

    # UniverseAccounting::getUniversesInRatioOrder()
    def self.getUniversesInRatioOrder()
        Multiverse::universes()
            .select{|universe| UniverseAccounting::universeExpectationOrNull(universe) }
            .sort{|u1, u2| UniverseAccounting::universeRatioOrNull(u1) <=> UniverseAccounting::universeRatioOrNull(u2) }
    end
end
