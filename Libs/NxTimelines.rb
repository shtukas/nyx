
# encoding: UTF-8

class NxTimelines

    # ----------------------------------------------------------------------
    # IO

    # NxTimelines::objectuuidToItemOrNull(objectuuid)
    def self.objectuuidToItemOrNull(objectuuid)
        return nil if Fx18Attributes::getOrNull(objectuuid, "mikuType") != "NxTimeline"
        {
            "uuid"        => objectuuid,
            "mikuType"    => Fx18Attributes::getOrNull(objectuuid, "mikuType"),
            "unixtime"    => Fx18Attributes::getOrNull(objectuuid, "unixtime"),
            "datetime"    => Fx18Attributes::getOrNull(objectuuid, "datetime"),
            "description" => Fx18Attributes::getOrNull(objectuuid, "description"),
        }
    end

    # NxTimelines::items()
    def self.items()
        Fx18Index2PrimaryLookup::mikuTypeToItems("NxTimeline")
    end

    # NxTimelines::destroy(uuid)
    def self.destroy(uuid)
        Fx18::destroyObject(uuid)
    end

    # ----------------------------------------------------------------------
    # Objects Makers

    # NxTimelines::interactivelyIssueNewItemOrNull()
    def self.interactivelyIssueNewItemOrNull()
        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return nil if description == ""
        unixtime   = Time.new.to_i
        datetime   = Time.new.utc.iso8601
        Fx18Attributes::setAttribute2(uuid, "uuid",        uuid)
        Fx18Attributes::setAttribute2(uuid, "mikuType",    "NxTimeline")
        Fx18Attributes::setAttribute2(uuid, "unixtime",    unixtime)
        Fx18Attributes::setAttribute2(uuid, "datetime",    datetime)
        Fx18Attributes::setAttribute2(uuid, "description", description)
        FileSystemCheck::fsckObject(uuid)
        uuid
    end

    # ----------------------------------------------------------------------
    # Data

    # NxTimelines::toString(item)
    def self.toString(item)
        "(timeline) #{item["description"]}"
    end
end
