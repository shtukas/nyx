
# encoding: UTF-8

class NxTimelines

    # ----------------------------------------------------------------------
    # IO

    # NxTimelines::objectuuidToItemOrNull(objectuuid)
    def self.objectuuidToItemOrNull(objectuuid)
        return nil if Fx18Attributes::getJsonDecodeOrNull(objectuuid, "mikuType") != "NxTimeline"
        {
            "uuid"        => objectuuid,
            "mikuType"    => Fx18Attributes::getJsonDecodeOrNull(objectuuid, "mikuType"),
            "unixtime"    => Fx18Attributes::getJsonDecodeOrNull(objectuuid, "unixtime"),
            "datetime"    => Fx18Attributes::getJsonDecodeOrNull(objectuuid, "datetime"),
            "description" => Fx18Attributes::getJsonDecodeOrNull(objectuuid, "description"),
        }
    end

    # NxTimelines::items()
    def self.items()
        Fx256WithCache::mikuTypeToItems("NxTimeline")
    end

    # NxTimelines::destroy(uuid)
    def self.destroy(uuid)
        Fx256::deleteObjectLogically(uuid)
    end

    # ----------------------------------------------------------------------
    # Objects Makers

    # NxTimelines::interactivelyIssueNewItemOrNull()
    def self.interactivelyIssueNewItemOrNull()
        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return nil if description == ""
        uuid = SecureRandom.uuid
        unixtime   = Time.new.to_i
        datetime   = Time.new.utc.iso8601
        Fx18Attributes::setJsonEncoded(uuid, "uuid",        uuid)
        Fx18Attributes::setJsonEncoded(uuid, "mikuType",    "NxTimeline")
        Fx18Attributes::setJsonEncoded(uuid, "unixtime",    unixtime)
        Fx18Attributes::setJsonEncoded(uuid, "datetime",    datetime)
        Fx18Attributes::setJsonEncoded(uuid, "description", description)
        FileSystemCheck::fsckObjectErrorAtFirstFailure(uuid)
        Fx256::broadcastObjectEvents(uuid)
        item = NxTimelines::objectuuidToItemOrNull(uuid)
        if item.nil? then
            raise "(error: a6cc9094-7100-4aa3-8ebc-1fec0669733e) How did that happen ? 🤨"
        end
        item
    end

    # ----------------------------------------------------------------------
    # Data

    # NxTimelines::toString(item)
    def self.toString(item)
        "(timeline) #{item["description"]}"
    end
end
