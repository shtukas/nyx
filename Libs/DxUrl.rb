
# encoding: UTF-8

class DxUrl

    # DxUrl::items()
    def self.items()
        TheIndex::mikuTypeToItems("DxUrl")
    end

    # DxUrl::interactivelyIssueNewOrNull()
    def self.interactivelyIssueNewOrNull()
        uuid = SecureRandom.uuid
        url = LucilleCore::askQuestionAnswerAsString("url (empty to abort): ")
        unixtime = Time.new.to_i
        datetime = Time.new.utc.iso8601
        DxF1::setJsonEncoded(uuid, "uuid", uuid)
        DxF1::setJsonEncoded(uuid, "mikuType", "DxUrl")
        DxF1::setJsonEncoded(uuid, "unixtime", unixtime)
        DxF1::setJsonEncoded(uuid, "datetime", datetime)
        DxF1::setJsonEncoded(uuid, "url", url)
        FileSystemCheck::fsckObjectuuidErrorAtFirstFailure(uuid)
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
        "(DxUrl) #{item["url"]}"
    end

    # ----------------------------------------------------------------------
    # Operations

    # DxUrl::access(item)
    def self.access(item)
        puts "DxUrl: #{item["url"]}"
        LucilleCore::pressEnterToContinue()
    end
end
