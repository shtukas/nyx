
# encoding: UTF-8

class DxUrl

    # DxUrl::items()
    def self.items()
        TheIndex::mikuTypeToItems("DxUrl")
    end

    # DxUrl::interactivelyIssueNewOrNull()
    def self.interactivelyIssueNewOrNull()
        uuid = SecureRandom.uuid
        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return nil if description == ""
        url = LucilleCore::askQuestionAnswerAsString("url (empty to abort): ")
        return nil if url == ""
        unixtime = Time.new.to_i
        datetime = Time.new.utc.iso8601
        DxF1::setAttribute2(uuid, "uuid", uuid)
        DxF1::setAttribute2(uuid, "mikuType", "DxUrl")
        DxF1::setAttribute2(uuid, "unixtime", unixtime)
        DxF1::setAttribute2(uuid, "datetime", datetime)
        DxF1::setAttribute2(uuid, "description", description)
        DxF1::setAttribute2(uuid, "url", url)
        FileSystemCheck::fsckObjectuuidErrorAtFirstFailure(uuid, SecureRandom.hex, true)
        item = TheIndex::getItemOrNull(uuid)
        if item.nil? then
            raise "(error: 0f512f44-6d46-4f15-9015-ca4c7bfe6d9c) How did that happen ? 🤨"
        end
        item
    end

    # ----------------------------------------------------------------------
    # Data

    # DxUrl::toString(item)
    def self.toString(item)
        "#{Stargate::formatTypeForToString("DxUrl")} #{item["url"]}"
    end

    # ----------------------------------------------------------------------
    # Operations

    # DxUrl::access(item)
    def self.access(item)
        puts "DxUrl: #{item["url"]}"
        LucilleCore::pressEnterToContinue()
    end
end
