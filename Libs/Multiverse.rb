
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
        XCache::set("5117D42F-8542-4D74-A219-47AF3C58F22B", universe)
    end

    # StoredUniverse::getUniverseOrNull()
    def self.getUniverseOrNull()
        XCache::getOrNull("5117D42F-8542-4D74-A219-47AF3C58F22B")
    end

    # StoredUniverse::interactivelySetUniverse()
    def self.interactivelySetUniverse()
        universe = LucilleCore::selectEntityFromListOfEntitiesOrNull("universe", Multiverse::universes())
        if universe.nil? then
            universe = "backlog"
        end
        StoredUniverse::setUniverse(universe)
    end
end

class UniverseManagement

    # Nx24 specifies the current mode for universe management
    # {
    #     "mode" => "standard"
    # }
    # {
    #     "mode"     => "hourOverride"
    #     "start"    => Unixtime
    #     "universe" => String
    # }
    # {
    #     "mode"     => "dayOverride"
    #     "date"     => Date
    #     "universe" => String
    # }

    # UniverseManagement::setNx24(nx24)
    def self.setNx24(nx24)
        XCache::set("e0dbc3dc-0454-41ba-a15d-e29df540ad80", JSON.generate(nx24))
    end

    # UniverseManagement::getNx24()
    def self.getNx24()
        nx24 = XCache::getOrNull("e0dbc3dc-0454-41ba-a15d-e29df540ad80")
        if nx24 then
            JSON.parse(nx24)
        else
            {
                "mode" => "standard"
            }
        end
    end

    # UniverseManagement::interactivelySetNx24()
    def self.interactivelySetNx24()
        modes = ["standard", "hourOverride", "dayOverride"]
        mode = LucilleCore::selectEntityFromListOfEntitiesOrNull("mode", modes)
        return if mode.nil?
        if mode == "standard" then
            UniverseManagement::setNx24({
                "mode" => "standard"
            })
        end
        if mode == "hourOverride" then
            start = Time.new.to_i
            universe = Multiverse::interactivelySelectUniverse()
            UniverseManagement::setNx24({
                "mode"     => "hourOverride",
                "start"    => start,
                "universe" => universe
            })
        end
        if mode == "dayOverride" then
            date = Utils::today()
            universe = Multiverse::interactivelySelectUniverse()
            UniverseManagement::setNx24({
                "mode"     => "dayOverride",
                "date"     => date,
                "universe" => universe
            })
        end
    end

    # UniverseManagement::nx24AsStringForListing()
    def self.nx24AsStringForListing()
        nx24 = UniverseManagement::getNx24()
        if nx24["mode"] == "standard" then
            return StoredUniverse::getUniverseOrNull()
        end
        if nx24["mode"] == "hourOverride" then
            return "#{StoredUniverse::getUniverseOrNull()} until #{Time.at(nx24["start"]+3600).to_s}"
        end
        if nx24["mode"] == "dayOverride" then
            return "#{StoredUniverse::getUniverseOrNull()} today"
        end
    end

    # --------------------------------------------------------------

    # UniverseManagement::naturalUniverseForThisTime()
     def self.naturalUniverseForThisTime()
        if [1, 2, 4].include?(Time.new.wday) and Time.new.hour >= 9 and Time.new.hour < 16 then
            return "work"
        end
        if [3, 5].include?(Time.new.wday) and Time.new.hour >= 9 and Time.new.hour < 14 then
            return "work"
        end
        "backlog"
     end

    # UniverseManagement::nx24UniverseForThisTime()
     def self.nx24UniverseForThisTime()
        nx24 = UniverseManagement::getNx24()
        if nx24["mode"] == "standard" then
            return UniverseManagement::naturalUniverseForThisTime()
        end
        if nx24["mode"] == "hourOverride" then
            if  (Time.new.to_i-nx24["start"]) < 3600 then
                return nx24["universe"]
            else
                UniverseManagement::setNx24({
                    "mode" => "standard"
                })
                return UniverseManagement::naturalUniverseForThisTime()
            end
        end
        if nx24["mode"] == "dayOverride" then
            if nx24["date"] == Utils::today() then
                return nx24["universe"]
            else
                UniverseManagement::setNx24({
                    "mode" => "standard"
                })
                return UniverseManagement::naturalUniverseForThisTime()
            end
        end
        raise "(error: 0eb2b610-53f7-45fb-83ae-77ba4cb4d89d)"
     end

    # UniverseManagement::performTransitionIfRelevantAndIfPossible()
     def self.performTransitionIfRelevantAndIfPossible()
        return if NxBallsService::somethingIsRunning()

        currentUniverse = StoredUniverse::getUniverseOrNull()
        nx24Universe = UniverseManagement::nx24UniverseForThisTime()

        if currentUniverse != nx24Universe then
            puts "Transitioning to #{nx24Universe}"
            sleep 1
            StoredUniverse::setUniverse(nx24Universe)
        end
     end
end
