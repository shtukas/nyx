
# encoding: UTF-8

class CxUniqueString

    # ----------------------------------------------------------------------
    # Objects Management

    # CxUniqueString::items()
    def self.items()
        TheIndex::mikuTypeToItems("CxUniqueString")
    end

    # CxUniqueString::interactivelyIssueNewForOwner(owneruuid)
    def self.interactivelyIssueNewForOwner(owneruuid)
        uuid = SecureRandom.uuid
        uniquestring = LucilleCore::askQuestionAnswerAsString("unique string (empty to abort): ")
        unixtime = Time.new.to_i
        datetime = Time.new.utc.iso8601
        DxF1::setAttribute2(uuid, "uuid", uuid)
        DxF1::setAttribute2(uuid, "mikuType", "CxUniqueString")
        DxF1::setAttribute2(uuid, "unixtime", unixtime)
        DxF1::setAttribute2(uuid, "datetime", datetime)
        DxF1::setAttribute2(uuid, "owneruuid", owneruuid)
        DxF1::setAttribute2(uuid, "uniquestring", uniquestring)
        FileSystemCheck::fsckObjectuuidErrorAtFirstFailure(uuid, SecureRandom.hex)
        item = TheIndex::getItemOrNull(uuid)
        if item.nil? then
            raise "(error: 0f512f44-6d46-4f15-9015-ca4c7bfe6d9c) How did that happen ? 🤨"
        end
        item
    end

    # CxUniqueString::issueNewForOwner(owneruuid, uniquestring)
    def self.issueNewForOwner(owneruuid, uniquestring)
        uuid = SecureRandom.uuid
        unixtime = Time.new.to_i
        datetime = Time.new.utc.iso8601
        DxF1::setAttribute2(uuid, "uuid", uuid)
        DxF1::setAttribute2(uuid, "mikuType", "CxUniqueString")
        DxF1::setAttribute2(uuid, "unixtime", unixtime)
        DxF1::setAttribute2(uuid, "datetime", datetime)
        DxF1::setAttribute2(uuid, "owneruuid", owneruuid)
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

    # CxUniqueString::toString(item)
    def self.toString(item)
        "(CxUniqueString) #{item["uniquestring"]}"
    end

    # ----------------------------------------------------------------------
    # Operations

    # CxUniqueString::access(item)
    def self.access(item)
        uniquestring = item["uniquestring"]
        UniqueStringsFunctions::findAndAccessUniqueString(uniquestring)
    end
end
