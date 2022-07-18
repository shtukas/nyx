
# encoding: UTF-8

class NxDataNodes

    # ----------------------------------------------------------------------
    # IO

    # NxDataNodes::objectuuidToItemOrNull(objectuuid)
    def self.objectuuidToItemOrNull(objectuuid)
        return nil if !Fx18Utils::fileExists?(objectuuid)
        return nil if Fx18File::getAttributeOrNull(objectuuid, "mikuType") != "NxDataNode"
        {
            "uuid"        => objectuuid,
            "mikuType"    => Fx18File::getAttributeOrNull(objectuuid, "mikuType"),
            "unixtime"    => Fx18File::getAttributeOrNull(objectuuid, "unixtime"),
            "datetime"    => Fx18File::getAttributeOrNull(objectuuid, "datetime"),
            "description" => Fx18File::getAttributeOrNull(objectuuid, "description"),
            "nx111"       => Fx18Utils::jsonParseIfNotNull(Fx18File::getAttributeOrNull(objectuuid, "nx111")),
        }
    end

    # NxDataNodes::items()
    def self.items()
        Fx18Index1::mikuType2objectuuids("NxDataNode")
            .map{|objectuuid| NxDataNodes::objectuuidToItemOrNull(objectuuid)}
            .compact
    end

    # NxDataNodes::destroy(uuid)
    def self.destroy(uuid)
        Fx18Utils::destroyFx18(uuid)
    end

    # ----------------------------------------------------------------------
    # Objects Makers

    # NxDataNodes::interactivelyIssueNewItemOrNull()
    def self.interactivelyIssueNewItemOrNull()
        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return nil if description == ""
        uuid = SecureRandom.uuid
        Fx18Utils::makeNewFile(uuid)
        nx111 = Nx111::interactivelyCreateNewNx111OrNull(uuid)
        unixtime   = Time.new.to_i
        datetime   = Time.new.utc.iso8601
        Fx18Utils::makeNewFile(uuid)
        Fx18File::setAttribute2(uuid, "uuid",        uuid)
        Fx18File::setAttribute2(uuid, "mikuType",    "NxDataNode")
        Fx18File::setAttribute2(uuid, "unixtime",    Time.new.to_i)
        Fx18File::setAttribute2(uuid, "datetime",    datetime)
        Fx18File::setAttribute2(uuid, "description", description)
        Fx18File::setAttribute2(uuid, "nx111",       JSON.generate(nx111))
        uuid
    end

    # NxDataNodes::issueNewItemAionPointFromLocation(location)
    def self.issueNewItemAionPointFromLocation(location)
        description = File.basename(location)
        uuid = SecureRandom.uuid
        Fx18Utils::makeNewFile(uuid)
        nx111 = Nx111::locationToAionPointNx111OrNull(uuid, location)
        unixtime   = Time.new.to_i
        datetime   = Time.new.utc.iso8601
        Fx18Utils::makeNewFile(uuid)
        Fx18File::setAttribute2(uuid, "uuid",        uuid)
        Fx18File::setAttribute2(uuid, "mikuType",    "NxDataNode")
        Fx18File::setAttribute2(uuid, "unixtime",    Time.new.to_i)
        Fx18File::setAttribute2(uuid, "datetime",    datetime)
        Fx18File::setAttribute2(uuid, "description", description)
        Fx18File::setAttribute2(uuid, "nx111",       JSON.generate(nx111))
        uuid
    end

    # NxDataNodes::issuePrimitiveFileFromLocationOrNull(location)
    def self.issuePrimitiveFileFromLocationOrNull(location)
        description = nil
        uuid = SecureRandom.uuid
        nx111 = PrimitiveFiles::locationToPrimitiveFileNx111OrNull(uuid, location)
        unixtime   = Time.new.to_i
        datetime   = Time.new.utc.iso8601
        Fx18Utils::makeNewFile(uuid)
        Fx18File::setAttribute2(uuid, "uuid",        uuid)
        Fx18File::setAttribute2(uuid, "mikuType",    "NxDataNode")
        Fx18File::setAttribute2(uuid, "unixtime",    Time.new.to_i)
        Fx18File::setAttribute2(uuid, "datetime",    datetime)
        Fx18File::setAttribute2(uuid, "description", description)
        Fx18File::setAttribute2(uuid, "nx111",       JSON.generate(nx111))
        uuid
    end

    # ----------------------------------------------------------------------
    # Data

    # NxDataNodes::toString(item)
    def self.toString(item)
        "(data) #{item["description"]}"
    end
end
