
# encoding: UTF-8

class NxCollections

    # ----------------------------------------------------------------------
    # IO

    # NxCollections::objectuuidToItemOrNull(objectuuid)
    def self.objectuuidToItemOrNull(objectuuid)
        return nil if Fx18Attributes::getJsonDecodeOrNull(objectuuid, "mikuType") != "NxCollection"
        {
            "uuid"        => objectuuid,
            "mikuType"    => Fx18Attributes::getJsonDecodeOrNull(objectuuid, "mikuType"),
            "unixtime"    => Fx18Attributes::getJsonDecodeOrNull(objectuuid, "unixtime"),
            "datetime"    => Fx18Attributes::getJsonDecodeOrNull(objectuuid, "datetime"),
            "description" => Fx18Attributes::getJsonDecodeOrNull(objectuuid, "description")
        }
    end

    # NxCollections::items()
    def self.items()
        AlphaStructure::mikuTypeToItems("NxCollection")
    end

    # NxCollections::destroy(uuid)
    def self.destroy(uuid)
        Fx18s::deleteObjectLogically(uuid)
    end

    # ----------------------------------------------------------------------
    # Objects Makers

    # NxCollections::interactivelyIssueNewItemOrNull()
    def self.interactivelyIssueNewItemOrNull()
        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return nil if description == ""
        unixtime   = Time.new.to_i
        datetime   = Time.new.utc.iso8601
        uuid = SecureRandom.uuid
        Fx18Attributes::setJsonEncode(uuid, "uuid",        uuid)
        Fx18Attributes::setJsonEncode(uuid, "mikuType",    "NxCollection")
        Fx18Attributes::setJsonEncode(uuid, "unixtime",    Time.new.to_i)
        Fx18Attributes::setJsonEncode(uuid, "datetime",    datetime)
        Fx18Attributes::setJsonEncode(uuid, "description", description)
        FileSystemCheck::fsckObjectErrorAtFirstFailure(uuid)
        Fx18s::broadcastObjectEvents(uuid)
        item = NxCollections::objectuuidToItemOrNull(uuid)
        if item.nil? then
            raise "(error: 01666ee3-d5b4-4fd1-9615-981ac7949ae9) How did that happen ? 🤨"
        end
        item
    end

    # ----------------------------------------------------------------------
    # Data

    # NxCollections::toString(item)
    def self.toString(item)
        "(collection) #{item["description"]}"
    end
end
