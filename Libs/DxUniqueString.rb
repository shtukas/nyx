
# encoding: UTF-8

class DxUniqueString

    # ----------------------------------------------------------------------
    # Objects Management

    # DxUniqueString::items()
    def self.items()
        TheIndex::mikuTypeToItems("DxUniqueString")
    end

    # DxUniqueString::interactivelyIssueNew()
    def self.interactivelyIssueNew()
        uuid = SecureRandom.uuid
        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return nil if description == ""
        uniquestring = LucilleCore::askQuestionAnswerAsString("unique string (empty to abort): ")
        return nil if uniquestring == ""
        unixtime = Time.new.to_i
        datetime = Time.new.utc.iso8601
        DxF1::setAttribute2(uuid, "uuid", uuid)
        DxF1::setAttribute2(uuid, "mikuType", "DxUniqueString")
        DxF1::setAttribute2(uuid, "unixtime", unixtime)
        DxF1::setAttribute2(uuid, "datetime", datetime)
        DxF1::setAttribute2(uuid, "description", description)
        DxF1::setAttribute2(uuid, "uniquestring", uniquestring)
        FileSystemCheck::fsckObjectuuidErrorAtFirstFailure(uuid, SecureRandom.hex)
        item = TheIndex::getItemOrNull(uuid)
        if item.nil? then
            raise "(error: 0f512f44-6d46-4f15-9015-ca4c7bfe6d9c) How did that happen ? 🤨"
        end
        item
    end

    # ----------------------------------------------------------------------
    # Data

    # DxUniqueString::toString(item)
    def self.toString(item)
        "#{Stargate::formatTypeForToString("DxUniqueString")} #{item["uniquestring"]}"
    end

    # ----------------------------------------------------------------------
    # Operations

    # DxUniqueString::access(item)
    def self.access(item)
        puts "DxUniqueString::access has not been implemented yet"
        LucilleCore::pressEnterToContinue()
    end
end
