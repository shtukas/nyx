
# encoding: UTF-8

class TxIncomings

    # ----------------------------------------------------------------------
    # IO

    # TxIncomings::items()
    def self.items()
        TheIndex::mikuTypeToItems("TxIncoming")
    end

    # ----------------------------------------------------------------------
    # Makers

    # TxIncomings::issue(line)
    def self.issue(line)
        uuid = SecureRandom.uuid
        DxF1::setJsonEncoded(uuid, "uuid",        uuid)
        DxF1::setJsonEncoded(uuid, "mikuType",    "TxIncoming")
        DxF1::setJsonEncoded(uuid, "unixtime",    Time.new.to_i)
        DxF1::setJsonEncoded(uuid, "datetime",    Time.new.utc.iso8601)
        DxF1::setJsonEncoded(uuid, "line",        line)
        FileSystemCheck::fsckObjectuuidErrorAtFirstFailure(uuid)
        DxF1::broadcastObjectFile(uuid)
        item = DxF1::getProtoItemOrNull(uuid)
        raise "(error: 23934808-2c52-439b-abc0-6c34cf5c854a) How did that happen?" if item.nil?
        item
    end

    # TxIncomings::interactivelyIssueNewLineOrNull()
    def self.interactivelyIssueNewLineOrNull()
        line = LucilleCore::askQuestionAnswerAsString("line (empty to abort): ")
        return nil if line == ""
        TxIncomings::issue(line)
    end

    # ----------------------------------------------------------------------
    # Data

    # TxIncomings::toString(item)
    def self.toString(item)
        "(incoming) #{item["line"]}"
    end

    # TxIncomings::listingItems()
    def self.listingItems()
        TxIncomings::items()
            .sort{|i1, i2| i1["unixtime"] <=> i2["unixtime"] }
    end
end
