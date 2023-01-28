
class DoNotShowUntil

    # DoNotShowUntil::setUnixtime(uuid, unixtime)
    def self.setUnixtime(uuid, unixtime)
        TodoDatabase2::set(uuid, "doNotShowUntil", unixtime)
    end

    # DoNotShowUntil::getUnixtimeOrNull(uuid)
    def self.getUnixtimeOrNull(uuid)
        TodoDatabase2::getOrNull(uuid, "doNotShowUntil")
    end

    # DoNotShowUntil::isVisible(item)
    def self.isVisible(item)
        Time.new.to_i >= (item["doNotShowUntil"] || 0)
    end
end
