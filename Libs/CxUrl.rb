
# encoding: UTF-8

class CxUrl

    # CxUrl::items()
    def self.items()
        TheIndex::mikuTypeToItems("CxUrl")
    end

    # CxUrl::interactivelyIssueNewOrNullForOwner(owneruuid)
    def self.interactivelyIssueNewOrNullForOwner(owneruuid)
        uuid = SecureRandom.uuid
        url = LucilleCore::askQuestionAnswerAsString("url (empty to abort): ")
        return nil if url == ""
        unixtime = Time.new.to_i
        datetime = Time.new.utc.iso8601
        DxF1::setAttribute2(uuid, "uuid", uuid)
        DxF1::setAttribute2(uuid, "mikuType", "CxUrl")
        DxF1::setAttribute2(uuid, "unixtime", unixtime)
        DxF1::setAttribute2(uuid, "datetime", datetime)
        DxF1::setAttribute2(uuid, "owneruuid", owneruuid)
        DxF1::setAttribute2(uuid, "url", url)
        FileSystemCheck::fsckObjectuuidErrorAtFirstFailure(uuid, SecureRandom.hex)
        item = TheIndex::getItemOrNull(uuid)
        if item.nil? then
            raise "(error: 0f512f44-6d46-4f15-9015-ca4c7bfe6d9c) How did that happen ? 🤨"
        end
        item
    end

    # CxUrl::issueNewForOwner(owneruuid, url)
    def self.issueNewForOwner(owneruuid, url)
        uuid = SecureRandom.uuid
        unixtime = Time.new.to_i
        datetime = Time.new.utc.iso8601
        DxF1::setAttribute2(uuid, "uuid", uuid)
        DxF1::setAttribute2(uuid, "mikuType", "CxUrl")
        DxF1::setAttribute2(uuid, "unixtime", unixtime)
        DxF1::setAttribute2(uuid, "datetime", datetime)
        DxF1::setAttribute2(uuid, "owneruuid", owneruuid)
        DxF1::setAttribute2(uuid, "url", url)
        FileSystemCheck::fsckObjectuuidErrorAtFirstFailure(uuid, SecureRandom.hex)
        item = TheIndex::getItemOrNull(uuid)
        if item.nil? then
            raise "(error: 0f512f44-6d46-4f15-9015-ca4c7bfe6d9c) How did that happen ? 🤨"
        end
        item
    end

    # ----------------------------------------------------------------------
    # Data

    # CxUrl::toString(item)
    def self.toString(item)
        "(CxUrl) #{item["url"]}"
    end

    # ----------------------------------------------------------------------
    # Operations

    # CxUrl::access(item)
    def self.access(item)
        url = item["url"]
        puts "url: #{url}"
        CommonUtils::openUrlUsingSafari(url)
    end
end
