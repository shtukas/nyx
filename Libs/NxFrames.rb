# encoding: UTF-8

class NxFrames

    # NxFrames::objectuuidToItemOrNull(objectuuid)
    def self.objectuuidToItemOrNull(objectuuid)
        return nil if Fx18Attributes::getJsonDecodeOrNull(objectuuid, "mikuType") != "NxFrame"
        {
            "uuid"        => objectuuid,
            "mikuType"    => Fx18Attributes::getJsonDecodeOrNull(objectuuid, "mikuType"),
            "unixtime"    => Fx18Attributes::getJsonDecodeOrNull(objectuuid, "unixtime"),
            "datetime"    => Fx18Attributes::getJsonDecodeOrNull(objectuuid, "datetime"),
            "description" => Fx18Attributes::getJsonDecodeOrNull(objectuuid, "description"),
            "nx111"       => Fx18Attributes::getJsonDecodeOrNull(objectuuid, "nx111"),
        }
    end

    # NxFrames::items()
    def self.items()
        Lookup1::mikuTypeToItems("NxFrame")
    end

    # NxFrames::destroy(uuid)
    def self.destroy(uuid)
        Fx18s::deleteObjectLogically(uuid)
    end

    # --------------------------------------------------
    # Makers

    # NxFrames::interactivelyCreateNewOrNull()
    def self.interactivelyCreateNewOrNull()
        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return nil if description == ""
        uuid = SecureRandom.uuid
        nx111 = Nx111::interactivelyCreateNewNx111OrNull(uuid)
        unixtime = Time.new.to_i
        datetime = Time.new.utc.iso8601
        Fx18Attributes::setJsonEncodeObjectMaking(uuid, "uuid",        uuid)
        Fx18Attributes::setJsonEncodeObjectMaking(uuid, "mikuType",    "NxFrame")
        Fx18Attributes::setJsonEncodeObjectMaking(uuid, "unixtime",    unixtime)
        Fx18Attributes::setJsonEncodeObjectMaking(uuid, "datetime",    datetime)
        Fx18Attributes::setJsonEncodeObjectMaking(uuid, "description", description)
        Fx18Attributes::setJsonEncodeObjectMaking(uuid, "nx111",       nx111)
        FileSystemCheck::fsckObject(uuid)
        Lookup1::reconstructEntry(uuid)
        Fx18s::broadcastObjectEvents(uuid)
        item = NxFrames::objectuuidToItemOrNull(uuid)
        if item.nil? then
            raise "(error: b63ae301-b0a1-47da-a445-8c53a457d0fe) How did that happen ? 🤨"
        end
        item
    end

    # --------------------------------------------------
    # Data

    # NxFrames::toString(item)
    def self.toString(item)
        nx111String = item["nx111"] ? " (#{Nx111::toStringShort(item["nx111"])})" : ""
        "(frame) #{item["description"]}#{nx111String}"
    end

    # NxFrames::toStringForSearch(item)
    def self.toStringForSearch(item)
        "(frame) #{item["description"]}"
    end
end
