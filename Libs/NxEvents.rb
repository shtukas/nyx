
# encoding: UTF-8

class NxEvents

    # ----------------------------------------------------------------------
    # IO

    # NxEvents::objectuuidToItemOrNull(objectuuid)
    def self.objectuuidToItemOrNull(objectuuid)
        return nil if Fx18Attributes::getOrNull(objectuuid, "mikuType") != "NxEvent"
        {
            "uuid"        => objectuuid,
            "mikuType"    => Fx18Attributes::getOrNull(objectuuid, "mikuType"),
            "unixtime"    => Fx18Attributes::getOrNull(objectuuid, "unixtime"),
            "datetime"    => Fx18Attributes::getOrNull(objectuuid, "datetime"),
            "description" => Fx18Attributes::getOrNull(objectuuid, "description"),
            "nx111"       => Fx18::jsonParseIfNotNull(Fx18Attributes::getOrNull(objectuuid, "nx111")),
        }
    end

    # NxEvents::items()
    def self.items()
        Lookup1::mikuTypeToItems("NxEvent")
    end

    # NxEvents::destroy(uuid)
    def self.destroy(uuid)
        Fx18::deleteObject(uuid)
    end

    # ----------------------------------------------------------------------
    # Objects Makers

    # NxEvents::interactivelyIssueNewItemOrNull()
    def self.interactivelyIssueNewItemOrNull()
        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return nil if description == ""
        uuid = SecureRandom.uuid
        nx111 = Nx111::interactivelyCreateNewNx111OrNull(uuid)
        unixtime   = Time.new.to_i
        datetime   = CommonUtils::interactiveDateTimeBuilder()
        Fx18Attributes::set_objectMaking(uuid, "uuid",        uuid)
        Fx18Attributes::set_objectMaking(uuid, "mikuType",    "NxEvent")
        Fx18Attributes::set_objectMaking(uuid, "unixtime",    Time.new.to_i)
        Fx18Attributes::set_objectMaking(uuid, "datetime",    datetime)
        Fx18Attributes::set_objectMaking(uuid, "description", description)
        Fx18Attributes::set_objectMaking(uuid, "nx111",       JSON.generate(nx111))
        FileSystemCheck::fsckObject(uuid)
        Lookup1::reconstructEntry(uuid)
        item = NxEvents::objectuuidToItemOrNull(uuid)
        if item.nil? then
            raise "(error: c4d9e89d-d4f2-4a44-8c66-311431977b4c) How did that happen ? 🤨"
        end
        item
    end

    # ----------------------------------------------------------------------
    # Data

    # NxEvents::toString(item)
    def self.toString(item)
        "(event) #{item["description"]}"
    end
end
