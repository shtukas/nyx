
# encoding: UTF-8

class NxDataNodes

    # ----------------------------------------------------------------------
    # IO

    # NxDataNodes::objectuuidToItemOrNull(objectuuid)
    def self.objectuuidToItemOrNull(objectuuid)
        return nil if Fx18Attributes::getJsonDecodeOrNull(objectuuid, "mikuType") != "NxDataNode"
        {
            "uuid"        => objectuuid,
            "mikuType"    => Fx18Attributes::getJsonDecodeOrNull(objectuuid, "mikuType"),
            "unixtime"    => Fx18Attributes::getJsonDecodeOrNull(objectuuid, "unixtime"),
            "datetime"    => Fx18Attributes::getJsonDecodeOrNull(objectuuid, "datetime"),
            "description" => Fx18Attributes::getJsonDecodeOrNull(objectuuid, "description"),
            "nx111"       => Fx18Attributes::getJsonDecodeOrNull(objectuuid, "nx111"),
        }
    end

    # NxDataNodes::items()
    def self.items()
        Lookup1::mikuTypeToItems("NxDataNode")
    end

    # NxDataNodes::destroy(uuid)
    def self.destroy(uuid)
        Fx18s::deleteObjectLogically(uuid)
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
        Fx18s::makeNewLocalFx18FileForObjectuuid(uuid)
        Fx18Attributes::setJsonEncodeObjectMaking(uuid, "uuid",        uuid)
        Fx18Attributes::setJsonEncodeObjectMaking(uuid, "mikuType",    "NxDataNode")
        Fx18Attributes::setJsonEncodeObjectMaking(uuid, "unixtime",    Time.new.to_i)
        Fx18Attributes::setJsonEncodeObjectMaking(uuid, "datetime",    datetime)
        Fx18Attributes::setJsonEncodeObjectMaking(uuid, "description", description)
        Fx18Attributes::setJsonEncodeObjectMaking(uuid, "nx111",       nx111)
        FileSystemCheck::fsckObjectErrorAtFirstFailure(uuid)
        Lookup1::reconstructEntry(uuid)
        Fx18s::broadcastObjectEvents(uuid)
        item = NxDataNodes::objectuuidToItemOrNull(uuid)
        if item.nil? then
            raise "(error: 1121ff68-dccb-4ee2-92ca-f8c17be9559c) How did that happen ? 🤨"
        end
        item
    end

    # NxDataNodes::issueNewItemAionPointFromLocation(location)
    def self.issueNewItemAionPointFromLocation(location)
        description = File.basename(location)
        uuid = SecureRandom.uuid
        nx111 = Nx111::locationToAionPointNx111OrNull(uuid, location)
        unixtime   = Time.new.to_i
        datetime   = Time.new.utc.iso8601
        Fx18s::makeNewLocalFx18FileForObjectuuid(uuid)
        Fx18Attributes::setJsonEncodeObjectMaking(uuid, "uuid",        uuid)
        Fx18Attributes::setJsonEncodeObjectMaking(uuid, "mikuType",    "NxDataNode")
        Fx18Attributes::setJsonEncodeObjectMaking(uuid, "unixtime",    Time.new.to_i)
        Fx18Attributes::setJsonEncodeObjectMaking(uuid, "datetime",    datetime)
        Fx18Attributes::setJsonEncodeObjectMaking(uuid, "description", description)
        Fx18Attributes::setJsonEncodeObjectMaking(uuid, "nx111",       nx111)
        FileSystemCheck::fsckObjectErrorAtFirstFailure(uuid)
        Lookup1::reconstructEntry(uuid)
        Fx18s::broadcastObjectEvents(uuid)
        item = NxDataNodes::objectuuidToItemOrNull(uuid)
        if item.nil? then
            raise "(error: b75d5950-4d8f-4fc4-bf5a-1b0e0ddd436c) How did that happen ? 🤨"
        end
        item
    end

    # NxDataNodes::issuePrimitiveFileFromLocationOrNull(location)
    def self.issuePrimitiveFileFromLocationOrNull(location)
        description = nil
        uuid = SecureRandom.uuid
        nx111 = PrimitiveFiles::locationToPrimitiveFileNx111OrNull(uuid, location)
        unixtime   = Time.new.to_i
        datetime   = Time.new.utc.iso8601
        Fx18s::makeNewLocalFx18FileForObjectuuid(uuid)
        Fx18Attributes::setJsonEncodeObjectMaking(uuid, "uuid",        uuid)
        Fx18Attributes::setJsonEncodeObjectMaking(uuid, "mikuType",    "NxDataNode")
        Fx18Attributes::setJsonEncodeObjectMaking(uuid, "unixtime",    Time.new.to_i)
        Fx18Attributes::setJsonEncodeObjectMaking(uuid, "datetime",    datetime)
        Fx18Attributes::setJsonEncodeObjectMaking(uuid, "description", description)
        Fx18Attributes::setJsonEncodeObjectMaking(uuid, "nx111",       nx111)
        FileSystemCheck::fsckObjectErrorAtFirstFailure(uuid)
        Lookup1::reconstructEntry(uuid)
        Fx18s::broadcastObjectEvents(uuid)
        item = NxDataNodes::objectuuidToItemOrNull(uuid)
        if item.nil? then
            raise "(error: ac3d8924-352d-48bb-8ee0-3383fa8242a5) How did that happen ? 🤨"
        end
        item
    end

    # ----------------------------------------------------------------------
    # Data

    # NxDataNodes::toString(item)
    def self.toString(item)
        "(data) #{item["description"]}"
    end
end
