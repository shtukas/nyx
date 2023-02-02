
class DoNotShowUntil

    # DoNotShowUntil::setUnixtime(uuid, unixtime)
    def self.setUnixtime(uuid, unixtime)
        ObjectStore1::set(uuid, "doNotShowUntil", unixtime)
    end

    # DoNotShowUntil::getUnixtimeOrNull(uuid)
    def self.getUnixtimeOrNull(uuid)
        ObjectStore1::getOrNull(uuid, "doNotShowUntil")
    end

    # DoNotShowUntil::isVisible(item)
    def self.isVisible(item)
        Time.new.to_i >= (item["doNotShowUntil"] || 0)
    end
end
