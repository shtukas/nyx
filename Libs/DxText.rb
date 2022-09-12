
# encoding: UTF-8

class DxText

    # ----------------------------------------------------------------------
    # Objects Management

    # DxText::items()
    def self.items()
        TheIndex::mikuTypeToItems("DxText")
    end

    # DxText::interactivelyIssueNewOrNull()
    def self.interactivelyIssueNewOrNull()
        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return nil if description == ""
        uuid = SecureRandom.uuid
        text = CommonUtils::editTextSynchronously("")
        unixtime = Time.new.to_i
        datetime = Time.new.utc.iso8601
        DxF1::setAttribute2(uuid, "uuid", uuid)
        DxF1::setAttribute2(uuid, "mikuType", "DxText")
        DxF1::setAttribute2(uuid, "unixtime", unixtime)
        DxF1::setAttribute2(uuid, "datetime", datetime)
        DxF1::setAttribute2(uuid, "description", description)
        DxF1::setAttribute2(uuid, "text", text)
        FileSystemCheck::fsckObjectuuidErrorAtFirstFailure(uuid, SecureRandom.hex)
        item = TheIndex::getItemOrNull(uuid)
        if item.nil? then
            raise "(error: 0f512f44-6d46-4f15-9015-ca4c7bfe6d9c) How did that happen ? 🤨"
        end
        item
    end

    # ----------------------------------------------------------------------
    # Data

    # DxText::toString(item)
    def self.toString(item)
        "#{Stargate::formatTypeForToString("DxText")} #{item["description"]}"
    end

    # ----------------------------------------------------------------------
    # Operations

    # DxText::access(item)
    def self.access(item)
        CommonUtils::accessText(item["text"])
    end
end
