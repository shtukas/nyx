
# encoding: UTF-8

class NxEntities

    # ----------------------------------------------------------------------
    # IO

    # NxEntities::objectuuidToItemOrNull(objectuuid)
    def self.objectuuidToItemOrNull(objectuuid)
        return nil if Fx18Attributes::getOrNull(objectuuid, "mikuType") != "NxEntity"
        {
            "uuid"        => objectuuid,
            "mikuType"    => Fx18Attributes::getOrNull(objectuuid, "mikuType"),
            "unixtime"    => Fx18Attributes::getOrNull(objectuuid, "unixtime"),
            "datetime"    => Fx18Attributes::getOrNull(objectuuid, "datetime"),
            "description" => Fx18Attributes::getOrNull(objectuuid, "description")
        }
    end

    # NxEntities::items()
    def self.items()
        Lookup1::mikuTypeToItems("NxEntity")
    end

    # NxEntities::destroy(uuid)
    def self.destroy(uuid)
        Fx18::deleteObject(uuid)
    end

    # ----------------------------------------------------------------------
    # Objects Makers

    # NxEntities::interactivelyIssueNewItemOrNull()
    def self.interactivelyIssueNewItemOrNull()
        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return nil if description == ""
        uuid = SecureRandom.uuid
        Fx18Attributes::set_objectMaking(uuid, "uuid",        uuid)
        Fx18Attributes::set_objectMaking(uuid, "mikuType",    "NxEntity")
        Fx18Attributes::set_objectMaking(uuid, "unixtime",    Time.new.to_i)
        Fx18Attributes::set_objectMaking(uuid, "datetime",    Time.new.utc.iso8601)
        Fx18Attributes::set_objectMaking(uuid, "description", description)
        FileSystemCheck::fsckObject(uuid)
        Lookup1::reconstructEntry(uuid)
        item = NxEntities::objectuuidToItemOrNull(uuid)
        if item.nil? then
            raise "(error: 291521ea-221b-4a81-9b6e-9ef0925d2ca5) How did that happen ? 🤨"
        end
        item
    end

    # ----------------------------------------------------------------------
    # Data

    # NxEntities::toString(item)
    def self.toString(item)
        "(entity) #{item["description"]}"
    end
end
