
# encoding: UTF-8

class CxText

    # ----------------------------------------------------------------------
    # Objects Management

    # CxText::items()
    def self.items()
        TheIndex::mikuTypeToItems("CxText")
    end

    # CxText::interactivelyIssueNewForOwner(owneruuid)
    def self.interactivelyIssueNewForOwner(owneruuid)
        uuid = SecureRandom.uuid
        text = CommonUtils::editTextSynchronously("")
        unixtime = Time.new.to_i
        datetime = Time.new.utc.iso8601
        DxF1::setAttribute2(uuid, "uuid", uuid)
        DxF1::setAttribute2(uuid, "mikuType", "CxText")
        DxF1::setAttribute2(uuid, "unixtime", unixtime)
        DxF1::setAttribute2(uuid, "datetime", datetime)
        DxF1::setAttribute2(uuid, "owneruuid", owneruuid)
        DxF1::setAttribute2(uuid, "text", text)
        FileSystemCheck::fsckObjectuuidErrorAtFirstFailure(uuid, SecureRandom.hex)
        item = TheIndex::getItemOrNull(uuid)
        if item.nil? then
            raise "(error: 0f512f44-6d46-4f15-9015-ca4c7bfe6d9c) How did that happen ? 🤨"
        end
        item
    end

    # CxText::issueNewForOwner(owneruuid, text)
    def self.issueNewForOwner(owneruuid, text)
        uuid = SecureRandom.uuid
        unixtime = Time.new.to_i
        datetime = Time.new.utc.iso8601
        DxF1::setAttribute2(uuid, "uuid", uuid)
        DxF1::setAttribute2(uuid, "mikuType", "CxText")
        DxF1::setAttribute2(uuid, "unixtime", unixtime)
        DxF1::setAttribute2(uuid, "datetime", datetime)
        DxF1::setAttribute2(uuid, "owneruuid", owneruuid)
        DxF1::setAttribute2(uuid, "text", text)
        FileSystemCheck::fsckObjectuuidErrorAtFirstFailure(uuid, SecureRandom.hex)
        item = TheIndex::getItemOrNull(uuid)
        if item.nil? then
            raise "(error: 515b9a51-809e-4bac-bf3c-9d4e6410289e) How did that happen ? 🤨"
        end
        item
    end

    # ----------------------------------------------------------------------
    # Data

    # CxText::getFirstLineOrNull(item)
    def self.getFirstLineOrNull(item)
        text = item["text"]
        return nil if text.nil?
        return nil if text == ""
        text.lines.first.strip
    end

    # CxText::toString(item)
    def self.toString(item)
        firstline = CxText::getFirstLineOrNull(item)
        "(CxText) #{firstline ? firstline : "(no text)"}"
    end

    # ----------------------------------------------------------------------
    # Operations

    # CxText::access(item)
    def self.access(item)
        CommonUtils::accessText(item["text"])
    end

    # CxText::edit(item)
    def self.edit(item)
        newtext = CommonUtils::editTextSynchronously(item["text"])
        DxF1::setAttribute2(item["uuid"], "text", newtext)
    end
end
