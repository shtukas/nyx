# encoding: UTF-8

class Skips

    # Skips::skip(uuid, unixtime)
    def self.skip(uuid, unixtime)
        TodoDatabase2::set(uuid, "field7", unixtime)
    end

    # Skips::isSkipped(uuid)
    def self.isSkipped(uuid)
        unixtime = TodoDatabase2::getOrNull(uuid, "field7")
        return false if unixtime.nil?
        Time.new.to_i < unixtime
    end
end
