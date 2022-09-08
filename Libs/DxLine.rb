
# encoding: UTF-8

class DxLine

    # DxLine::items()
    def self.items()
        TheIndex::mikuTypeToItems("DxLine")
    end

    # DxLine::interactivelyIssueNewOrNull()
    def self.interactivelyIssueNewOrNull()
        uuid = SecureRandom.uuid
        line = LucilleCore::askQuestionAnswerAsString("line (empty to abort): ")
        unixtime = Time.new.to_i
        datetime = Time.new.utc.iso8601
        DxF1::setAttribute2(uuid, "uuid", uuid)
        DxF1::setAttribute2(uuid, "mikuType", "DxLine")
        DxF1::setAttribute2(uuid, "unixtime", unixtime)
        DxF1::setAttribute2(uuid, "datetime", datetime)
        DxF1::setAttribute2(uuid, "line", line)
        FileSystemCheck::fsckObjectuuidErrorAtFirstFailure(uuid, SecureRandom.hex, true)
        item = TheIndex::getItemOrNull(uuid)
        if item.nil? then
            raise "(error: 0f512f44-6d46-4f15-9015-ca4c7bfe6d9c) How did that happen ? 🤨"
        end
        item
    end

    # ----------------------------------------------------------------------
    # Data

    # DxLine::toString(item)
    def self.toString(item)
        "#{Stargate::formatTypeForToString("DxLine")} #{item["line"]}"
    end

    # ----------------------------------------------------------------------
    # Operations

    # DxLine::access(item)
    def self.access(item)
        puts "DxLine: #{item["line"]}"
        LucilleCore::pressEnterToContinue()
    end
end
