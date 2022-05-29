
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

class ActiveUniverse

    # ActiveUniverse::setUniverse(universe or null)
    def self.setUniverse(universe)
        if universe.nil? then
            XCache::destroy("5117D42F-8542-4D74-A219-47AF3C58F22B")
            return
        end
        XCache::set("5117D42F-8542-4D74-A219-47AF3C58F22B", universe)
    end

    # ActiveUniverse::getUniverseOrNull()
    def self.getUniverseOrNull()
        XCache::getOrNull("5117D42F-8542-4D74-A219-47AF3C58F22B")
    end

    # ActiveUniverse::interactivelySetUniverse()
    def self.interactivelySetUniverse()
        universe = Multiverse::interactivelySelectUniverse()
        ActiveUniverse::setUniverse(universe)
    end
end

class UniverseMonitor

    # UniverseMonitor::naturalUniverseForThisTime()
    def self.naturalUniverseForThisTime()
        return "backlog" if [6, 0].include?(Time.new.wday) # week end
        return "backlog" if Time.new.hour < 9
        return "backlog" if Time.new.hour >= 16
        "work"
    end

    # UniverseMonitor::switchInvitationNS16OrNull()
    def self.switchInvitationNS16OrNull()
        natural = UniverseMonitor::naturalUniverseForThisTime()
        return nil if ActiveUniverse::getUniverseOrNull() == natural
        {
            "uuid"     => "66a9b7b7-073f-49c3-81a1-395b00ed55e6:#{DidactUtils::today()}",
            "mikuType" => "Tx0938", # Common type to NS16s with a lambda
            "announce" => "(multiverse) switch to #{natural}",
            "lambda"   => lambda { ActiveUniverse::setUniverse(natural) }
        }
    end
end
