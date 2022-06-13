
# encoding: UTF-8

=begin
    XCacheSets::values(setuuid: String): Array[Value]
    XCacheSets::set(setuuid: String, valueuuid: String, value)
    XCacheSets::getOrNull(setuuid: String, valueuuid: String): nil | Value
    XCacheSets::destroy(setuuid: String, valueuuid: String)
=end

class Zone

    # Stack::items()
    def self.items()
        XCacheSets::values("cf791da8-8620-40f2-8848-d70a22336f31")
    end

    # Stack::injectInteractively()
    def self.injectInteractively()
        line = LucilleCore::askQuestionAnswerAsString("line (empty to abort): ")
        return if line == ""
        Stack::zoneAdd(line)
    end

    # Stack::zoneRemoveInteractively()
    def self.zoneRemoveInteractively()
        zone = Stack::items()
        line = LucilleCore::selectEntityFromListOfEntitiesOrNull("line", zone.sort)
        return if line.nil?
        zone.delete(line)
        Stack::setZone(zero)
    end

    # Stack::zoneEdit()
    def self.zoneEdit()
        action = LucilleCore::selectEntityFromListOfEntitiesOrNull("action", ["add", "remove"])
        return if action.nil?
        if action == "add" then
            Stack::zoneAddInteractively()
        end
        if action == "remove" then
            Stack::zoneRemoveInteractively()
        end
    end
end
