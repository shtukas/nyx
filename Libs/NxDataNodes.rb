
# encoding: UTF-8

class NxDataNodes

    # ----------------------------------------------------------------------
    # IO

    # NxDataNodes::objectuuidToItemOrNull(objectuuid)
    def self.objectuuidToItemOrNull(objectuuid)
        return nil if Fx18Attributes::getOrNull(objectuuid, "mikuType") != "NxDataNode"
        {
            "uuid"        => objectuuid,
            "mikuType"    => Fx18Attributes::getOrNull(objectuuid, "mikuType"),
            "unixtime"    => Fx18Attributes::getOrNull(objectuuid, "unixtime"),
            "datetime"    => Fx18Attributes::getOrNull(objectuuid, "datetime"),
            "description" => Fx18Attributes::getOrNull(objectuuid, "description"),
            "nx111"       => Fx18::jsonParseIfNotNull(Fx18Attributes::getOrNull(objectuuid, "nx111")),
        }
    end

    # NxDataNodes::items()
    def self.items()
        Lookup1::mikuTypeToItems("NxDataNode")
    end

    # NxDataNodes::destroy(uuid)
    def self.destroy(uuid)
        Fx18::deleteObject(uuid)
    end

    # ----------------------------------------------------------------------
    # Objects Makers

    # NxDataNodes::interactivelyIssueNewItemOrNull()
    def self.interactivelyIssueNewItemOrNull()
        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return nil if description == ""
        uuid = SecureRandom.uuid
        nx111 = Nx111::interactivelyCreateNewNx111OrNull(uuid)
        unixtime   = Time.new.to_i
        datetime   = Time.new.utc.iso8601
        Fx18Attributes::set2(uuid, "uuid",        uuid)
        Fx18Attributes::set2(uuid, "mikuType",    "NxDataNode")
        Fx18Attributes::set2(uuid, "unixtime",    Time.new.to_i)
        Fx18Attributes::set2(uuid, "datetime",    datetime)
        Fx18Attributes::set2(uuid, "description", description)
        Fx18Attributes::set2(uuid, "nx111",       JSON.generate(nx111))
        FileSystemCheck::fsckObject(uuid)
        uuid
    end

    # NxDataNodes::issueNewItemAionPointFromLocation(location)
    def self.issueNewItemAionPointFromLocation(location)
        description = File.basename(location)
        uuid = SecureRandom.uuid
        nx111 = Nx111::locationToAionPointNx111OrNull(uuid, location)
        unixtime   = Time.new.to_i
        datetime   = Time.new.utc.iso8601
        Fx18Attributes::set2(uuid, "uuid",        uuid)
        Fx18Attributes::set2(uuid, "mikuType",    "NxDataNode")
        Fx18Attributes::set2(uuid, "unixtime",    Time.new.to_i)
        Fx18Attributes::set2(uuid, "datetime",    datetime)
        Fx18Attributes::set2(uuid, "description", description)
        Fx18Attributes::set2(uuid, "nx111",       JSON.generate(nx111))
        FileSystemCheck::fsckObject(uuid)
        uuid
    end

    # NxDataNodes::issuePrimitiveFileFromLocationOrNull(location)
    def self.issuePrimitiveFileFromLocationOrNull(location)
        description = nil
        uuid = SecureRandom.uuid
        nx111 = PrimitiveFiles::locationToPrimitiveFileNx111OrNull(uuid, location)
        unixtime   = Time.new.to_i
        datetime   = Time.new.utc.iso8601
        Fx18Attributes::set2(uuid, "uuid",        uuid)
        Fx18Attributes::set2(uuid, "mikuType",    "NxDataNode")
        Fx18Attributes::set2(uuid, "unixtime",    Time.new.to_i)
        Fx18Attributes::set2(uuid, "datetime",    datetime)
        Fx18Attributes::set2(uuid, "description", description)
        Fx18Attributes::set2(uuid, "nx111",       JSON.generate(nx111))
        FileSystemCheck::fsckObject(uuid)
        uuid
    end

    # ----------------------------------------------------------------------
    # Data

    # NxDataNodes::toString(item)
    def self.toString(item)
        "(data) #{item["description"]}"
    end
end
