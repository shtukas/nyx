
# encoding: UTF-8

class DxText

    # ----------------------------------------------------------------------
    # Objects Management

    # DxText::items()
    def self.items()
        TheIndex::mikuTypeToItems("DxText")
    end

    # DxText::interactivelyIssueNew()
    def self.interactivelyIssueNew()
        uuid = SecureRandom.uuid
        text = CommonUtils::editTextSynchronously("")
        unixtime = Time.new.to_i
        datetime = Time.new.utc.iso8601
        DxF1::setAttribute2(uuid, "uuid", uuid)
        DxF1::setAttribute2(uuid, "mikuType", "DxText")
        DxF1::setAttribute2(uuid, "unixtime", unixtime)
        DxF1::setAttribute2(uuid, "datetime", datetime)
        DxF1::setAttribute2(uuid, "text", text)
        FileSystemCheck::fsckObjectuuidErrorAtFirstFailure(uuid, SecureRandom.hex, true)
        item = TheIndex::getItemOrNull(uuid)
        if item.nil? then
            raise "(error: 0f512f44-6d46-4f15-9015-ca4c7bfe6d9c) How did that happen ? 🤨"
        end
        item
    end

    # ----------------------------------------------------------------------
    # Data

    # DxText::getFirstLineOrNull(item)
    def self.getFirstLineOrNull(item)
        text = item["text"]
        return nil if text.nil?
        return nil if text == ""
        text.lines.first.strip
    end

    # DxText::toString(item)
    def self.toString(item)
        firstline = DxText::getFirstLineOrNull(item)
        "(DxText) #{firstline ? firstline : "(no text)"}"
    end

    # ----------------------------------------------------------------------
    # Operations

    # DxText::access(item)
    def self.access(item)
        CommonUtils::accessText(item["text"])
    end
end
