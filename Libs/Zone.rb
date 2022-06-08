
# encoding: UTF-8

class Zone

    # Zone::getZone()
    def self.getZone()
        JSON.parse(XCache::getOrDefaultValue("5cd02e58-fcc5-482a-9549-9bc801f9d59b", "[]"))
    end

    # Zone::setZone(zone)
    def self.setZone(zone)
        XCache::set("5cd02e58-fcc5-482a-9549-9bc801f9d59b", JSON.generate(zone))
    end

    # Zone::zoneAdd(line)
    def self.zoneAdd(line)
        zone = Zone::getZone()
        zone << line
        Zone::setZone(zone)
    end

    # Zone::zoneAddInteractively()
    def self.zoneAddInteractively()
        line = LucilleCore::askQuestionAnswerAsString("line (empty to abort): ")
        return if line == ""
        Zone::zoneAdd(line)
    end

    # Zone::zoneRemoveInteractively()
    def self.zoneRemoveInteractively()
        zone = Zone::getZone()
        line = LucilleCore::selectEntityFromListOfEntitiesOrNull("line", zone.sort)
        return if line.nil?
        zone.delete(line)
        Zone::setZone(zone)
    end

    # Zone::zoneEdit()
    def self.zoneEdit()
        action = LucilleCore::selectEntityFromListOfEntitiesOrNull("action", ["add", "remove"])
        return if action.nil?
        if action == "add" then
            Zone::zoneAddInteractively()
        end
        if action == "remove" then
            Zone::zoneRemoveInteractively()
        end
    end
end
