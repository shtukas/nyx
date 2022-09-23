# encoding: UTF-8

class NxLines

    # NyxNodes::issueNew(line)
    def self.issueNew(line)
        uuid = SecureRandom.uuid
        unixtime = Time.new.to_i
        datetime = Time.new.utc.iso8601
        ItemsEventsLog::setAttribute2(uuid, "uuid", uuid)
        ItemsEventsLog::setAttribute2(uuid, "mikuType", "NxLine")
        ItemsEventsLog::setAttribute2(uuid, "unixtime", unixtime)
        ItemsEventsLog::setAttribute2(uuid, "datetime", datetime)
        ItemsEventsLog::setAttribute2(uuid, "line", line)
        FileSystemCheck::fsckObjectuuidErrorAtFirstFailure(uuid, SecureRandom.hex)
        item = Items::getItemOrNull(uuid)
        if item.nil? then
            raise "(error: 57a5d974-3622-4d90-a68c-e2f3491b59df) How did that happen ? 🤨"
        end
        item
    end

end
