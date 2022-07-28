# encoding: UTF-8

class NxFrames

    # NxFrames::objectuuidToItemOrNull(objectuuid)
    def self.objectuuidToItemOrNull(objectuuid)
        return nil if Fx18Attributes::getOrNull(objectuuid, "mikuType") != "NxFrame"
        {
            "uuid"        => objectuuid,
            "mikuType"    => Fx18Attributes::getOrNull(objectuuid, "mikuType"),
            "unixtime"    => Fx18Attributes::getOrNull(objectuuid, "unixtime"),
            "datetime"    => Fx18Attributes::getOrNull(objectuuid, "datetime"),
            "description" => Fx18Attributes::getOrNull(objectuuid, "description"),
            "nx111"       => Fx18::jsonParseIfNotNull(Fx18Attributes::getOrNull(objectuuid, "nx111")),
        }
    end

    # NxFrames::items()
    def self.items()
        Lookup1::mikuTypeToItems("NxFrame")
    end

    # NxFrames::destroy(uuid)
    def self.destroy(uuid)
        Fx18::destroyObject(uuid)
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
        Fx18Attributes::setAttribute2(uuid, "uuid",        uuid)
        Fx18Attributes::setAttribute2(uuid, "mikuType",    "NxFrame")
        Fx18Attributes::setAttribute2(uuid, "unixtime",    unixtime)
        Fx18Attributes::setAttribute2(uuid, "datetime",    datetime)
        Fx18Attributes::setAttribute2(uuid, "description", description)
        Fx18Attributes::setAttribute2(uuid, "nx111",       JSON.generate(nx111))
        FileSystemCheck::fsckObject(uuid)
        uuid
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
