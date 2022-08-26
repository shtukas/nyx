
# encoding: UTF-8

class NxLines

    # ----------------------------------------------------------------------
    # IO

    # NxLines::items()
    def self.items()
        TheIndex::mikuTypeToItems("NxLine")
    end

    # ----------------------------------------------------------------------
    # Makers

    # NxLines::issue(line)
    def self.issue(line)
        uuid = SecureRandom.uuid
        DxF1::setJsonEncoded(uuid, "uuid",        uuid)
        DxF1::setJsonEncoded(uuid, "mikuType",    "NxLine")
        DxF1::setJsonEncoded(uuid, "unixtime",    Time.new.to_i)
        DxF1::setJsonEncoded(uuid, "datetime",    Time.new.utc.iso8601)
        DxF1::setJsonEncoded(uuid, "line",        line)
        FileSystemCheck::fsckObjectuuidErrorAtFirstFailure(uuid)
        item = TheIndex::getItemOrNull(uuid)
        raise "(error: 1853d31a-bb37-46d6-b4c2-7afcf88e0c56) How did that happen?" if item.nil?
        item
    end

    # NxLines::interactivelyIssueNewLineOrNull()
    def self.interactivelyIssueNewLineOrNull()
        line = LucilleCore::askQuestionAnswerAsString("line (empty to abort): ")
        return nil if line == ""
        NxLines::issue(line)
    end

    # ----------------------------------------------------------------------
    # Data

    # NxLines::toString(item)
    def self.toString(item)
        "(line) #{item["line"]}"
    end

    # NxLines::listingItems()
    def self.listingItems()
        NxLines::items()
            .select{|item| OwnerMapping::elementuuidToOwnersuuidsCached(item["uuid"]).empty? }
            .sort{|l1, l2| l1["unixtime"] <=> l2["unixtime"] }
    end
end
