# encoding: UTF-8

class NxFrames

    # NxFrames::objectuuidToItemOrNull(objectuuid)
    def self.objectuuidToItemOrNull(objectuuid)
        return nil if !Fx18Utils::fileExists?(objectuuid)
        return nil if Fx18File::getAttributeOrNull(objectuuid, "mikuType") != "NxFrame"
        {
            "uuid"        => objectuuid,
            "mikuType"    => Fx18File::getAttributeOrNull(objectuuid, "mikuType"),
            "unixtime"    => Fx18File::getAttributeOrNull(objectuuid, "unixtime"),
            "datetime"    => Fx18File::getAttributeOrNull(objectuuid, "datetime"),
            "description" => Fx18File::getAttributeOrNull(objectuuid, "description"),
            "nx111"       => JSON.parse(Fx18File::getAttributeOrNull(objectuuid, "nx111")),
        }
    end

    # NxFrames::items()
    def self.items()
        Librarian::mikuTypeUUIDs("NxFrame")
            .map{|objectuuid| NxFrames::objectuuidToItemOrNull(objectuuid)}
            .compact
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
        Fx18Utils::makeNewFile(uuid)
        nx111 = Nx111::interactivelyCreateNewNx111OrNull(uuid)
        unixtime = Time.new.to_i
        datetime = Time.new.utc.iso8601
        Fx18File::setAttribute2(uuid, "uuid",        uuid)
        Fx18File::setAttribute2(uuid, "mikuType",    "NxFrame")
        Fx18File::setAttribute2(uuid, "unixtime",    unixtime)
        Fx18File::setAttribute2(uuid, "datetime",    datetime)
        Fx18File::setAttribute2(uuid, "description", description)
        Fx18File::setAttribute2(uuid, "nx111",       JSON.generate(nx111))
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
