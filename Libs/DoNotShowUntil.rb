
class DoNotShowUntil

    # DoNotShowUntil::setUnixtime(uuid, unixtime)
    def self.setUnixtime(uuid, unixtime)
        Lookups::commit("DoNotShowUntil", uuid, unixtime)
    end

    # DoNotShowUntil::getUnixtimeOrNull(uuid)
    def self.getUnixtimeOrNull(uuid)
        Lookups::getValueOrNull("DoNotShowUntil", uuid)
    end

    # DoNotShowUntil::isVisible(uuid)
    def self.isVisible(uuid)
        Time.new.to_i >= (DoNotShowUntil::getUnixtimeOrNull(uuid) || 0)
    end
end
