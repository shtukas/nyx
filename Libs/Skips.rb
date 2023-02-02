# encoding: UTF-8

class Skips

    # Skips::skip(uuid, unixtime)
    def self.skip(uuid, unixtime)
        ObjectStore1::set(uuid, "field7", unixtime)
    end

    # Skips::isSkipped(item)
    def self.isSkipped(item)
        item["field7"] and Time.new.to_i < item["field7"].to_i
    end
end
