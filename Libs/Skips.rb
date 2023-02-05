# encoding: UTF-8

class Skips

    # Skips::skip(uuid, unixtime)
    def self.skip(uuid, unixtime)
        Lookups::commit("Skips", uuid, unixtime)
    end

    # Skips::getUnixtimeOrNull(uuid)
    def self.getUnixtimeOrNull(uuid)
        Lookups::getValueOrNull("Skips", uuid)
    end

    # Skips::isSkipped(uuid)
    def self.isSkipped(uuid)
        Time.new.to_i < (Skips::getUnixtimeOrNull(uuid) || 0)
    end
end
