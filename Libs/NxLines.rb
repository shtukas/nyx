# encoding: UTF-8

class NxLines

    # NxLines::issueNew(line)
    def self.issueNew(line)
        uuid = SecureRandom.uuid
        unixtime = Time.new.to_i
        datetime = Time.new.utc.iso8601
        item = {
            "uuid"     => uuid,
            "mikuType" => "NxLine",
            "unixtime" => unixtime,
            "datetime" => datetime,
            "line"     => line
        }
        Items::putItem(item)
        item
    end

end
