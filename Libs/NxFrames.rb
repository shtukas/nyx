# encoding: UTF-8

class NxFrames

    # NxFrames::objectuuidToItem(objectuuid)
    def self.objectuuidToItem(objectuuid)
        item = {
            "uuid"        => objectuuid,
            "mikuType"    => Fx18s::getAttributeOrNull(objectuuid, "mikuType"),
            "unixtime"    => Fx18s::getAttributeOrNull(objectuuid, "unixtime"),
            "datetime"    => Fx18s::getAttributeOrNull(objectuuid, "datetime"),
            "description" => Fx18s::getAttributeOrNull(objectuuid, "description"),
            "nx111"       => JSON.parse(Fx18s::getAttributeOrNull(objectuuid, "nx111")),
        }
        raise "(error: 8f6167a3-219c-48ae-8e60-47e59e4a0f03) item: #{item}" if item["mikuType"] != "NxFrame"
        item
    end

    # NxFrames::items()
    def self.items()
        Librarian::mikuTypeUUIDs("NxFrame").map{|objectuuid|
            NxFrames::objectuuidToItem(objectuuid)
        }
    end

    # NxFrames::destroy(uuid)
    def self.destroy(uuid)
        Librarian::destroyFx18Logically(uuid)
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

        Fx18s::makeNewFile(uuid)
        Fx18s::setAttribute2(uuid, "uuid",        uuid)
        Fx18s::setAttribute2(uuid, "mikuType",    "NxFrame")
        Fx18s::setAttribute2(uuid, "unixtime",    unixtime)
        Fx18s::setAttribute2(uuid, "datetime",    datetime)
        Fx18s::setAttribute2(uuid, "description", description)
        Fx18s::setAttribute2(uuid, "nx111",       JSON.generate(nx111))

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

    # NxFrames::nx20s()
    def self.nx20s()
        NxFrames::items().map{|item|
            {
                "announce" => NxFrames::toStringForSearch(item),
                "unixtime" => item["unixtime"],
                "payload"  => item
            }
        }
    end
end
