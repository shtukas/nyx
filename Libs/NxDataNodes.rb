
# encoding: UTF-8

class NxDataNodes

    # ----------------------------------------------------------------------
    # IO

    # NxDataNodes::items()
    def self.items()
        TheIndex::mikuTypeToItems("NxDataNode")
    end

    # NxDataNodes::destroy(uuid)
    def self.destroy(uuid)
        DxF1::deleteObjectLogically(uuid)
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
        DxF1::setJsonEncoded(uuid, "uuid",        uuid)
        DxF1::setJsonEncoded(uuid, "mikuType",    "NxDataNode")
        DxF1::setJsonEncoded(uuid, "unixtime",    Time.new.to_i)
        DxF1::setJsonEncoded(uuid, "datetime",    datetime)
        DxF1::setJsonEncoded(uuid, "description", description)
        DxF1::setJsonEncoded(uuid, "nx111",       nx111)
        FileSystemCheck::fsckObjectuuidErrorAtFirstFailure(uuid)
        DxF1::broadcastObjectFile(uuid)
        item = DxF1::getProtoItemOrNull(uuid)
        if item.nil? then
            raise "(error: 1121ff68-dccb-4ee2-92ca-f8c17be9559c) How did that happen ? 🤨"
        end
        item
    end

    # NxDataNodes::issueNewItemAionPointFromLocation(location)
    def self.issueNewItemAionPointFromLocation(location)
        description = File.basename(location)
        uuid = SecureRandom.uuid
        nx111 = Nx111::locationToNx111DxPureAionPoint(uuid, location)
        unixtime   = Time.new.to_i
        datetime   = Time.new.utc.iso8601
        DxF1::setJsonEncoded(uuid, "uuid",        uuid)
        DxF1::setJsonEncoded(uuid, "mikuType",    "NxDataNode")
        DxF1::setJsonEncoded(uuid, "unixtime",    Time.new.to_i)
        DxF1::setJsonEncoded(uuid, "datetime",    datetime)
        DxF1::setJsonEncoded(uuid, "description", description)
        DxF1::setJsonEncoded(uuid, "nx111",       nx111)
        FileSystemCheck::fsckObjectuuidErrorAtFirstFailure(uuid)
        DxF1::broadcastObjectFile(uuid)
        item = DxF1::getProtoItemOrNull(uuid)
        if item.nil? then
            raise "(error: b75d5950-4d8f-4fc4-bf5a-1b0e0ddd436c) How did that happen ? 🤨"
        end
        item
    end

    # NxDataNodes::issueNewNxDataNodeWithNx111DxPureFileFromLocationOrNull(location)
    def self.issueNewNxDataNodeWithNx111DxPureFileFromLocationOrNull(location)
        description = nil
        uuid = SecureRandom.uuid
        nx111 = Nx111::locationToNx111DxPureFileOrNull(uuid, location)
        unixtime   = Time.new.to_i
        datetime   = Time.new.utc.iso8601
        DxF1::setJsonEncoded(uuid, "uuid",        uuid)
        DxF1::setJsonEncoded(uuid, "mikuType",    "NxDataNode")
        DxF1::setJsonEncoded(uuid, "unixtime",    Time.new.to_i)
        DxF1::setJsonEncoded(uuid, "datetime",    datetime)
        DxF1::setJsonEncoded(uuid, "description", description)
        DxF1::setJsonEncoded(uuid, "nx111",       nx111)
        FileSystemCheck::fsckObjectuuidErrorAtFirstFailure(uuid)
        DxF1::broadcastObjectFile(uuid)
        item = DxF1::getProtoItemOrNull(uuid)
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
