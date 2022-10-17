# encoding: UTF-8

class NxLines

    # NxLines::issueNew(line)
    def self.issueNew(line)
        uuid = SecureRandom.uuid
        unixtime = Time.new.to_i
        datetime = Time.new.utc.iso8601
        item = {
            "uuid"        => uuid,
            "phage_uuid"  => SecureRandom.uuid,
            "phage_time"  => Time.new.to_f,
            "phage_alive" => true,
            "mikuType"    => "NxLine",
            "unixtime"    => unixtime,
            "datetime"    => datetime,
            "line"        => line
        }
        PhagePublic::commit(item)
        item
    end

end
