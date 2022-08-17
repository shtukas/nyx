
# encoding: UTF-8

class NxLines

    # ----------------------------------------------------------------------
    # IO

    # NxLines::objectuuidToItemOrNull(objectuuid)
    def self.objectuuidToItemOrNull(objectuuid)
        return nil if Fx18Attributes::getJsonDecodeOrNull(objectuuid, "mikuType") != "NxLine"
        {
            "uuid"        => objectuuid,
            "mikuType"    => Fx18Attributes::getJsonDecodeOrNull(objectuuid, "mikuType"),
            "unixtime"    => Fx18Attributes::getJsonDecodeOrNull(objectuuid, "unixtime"),
            "datetime"    => Fx18Attributes::getJsonDecodeOrNull(objectuuid, "datetime"),
            "line"        => Fx18Attributes::getJsonDecodeOrNull(objectuuid, "line"),
        }
    end

    # NxLines::items()
    def self.items()
        Fx256WithCache::mikuTypeToItems("NxLine")
    end

    # ----------------------------------------------------------------------
    # Makers

    # NxLines::issue(line)
    def self.issue(line)
        uuid = SecureRandom.uuid
        Fx18Attributes::setJsonEncoded(uuid, "uuid",        uuid)
        Fx18Attributes::setJsonEncoded(uuid, "mikuType",    "NxLine")
        Fx18Attributes::setJsonEncoded(uuid, "unixtime",    Time.new.to_i)
        Fx18Attributes::setJsonEncoded(uuid, "datetime",    Time.new.utc.iso8601)
        Fx18Attributes::setJsonEncoded(uuid, "line",        line)
        FileSystemCheck::fsckObjectErrorAtFirstFailure(uuid)
        Fx256::broadcastObjectEvents(uuid)
        item = NxLines::objectuuidToItemOrNull(uuid)
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

    # NxLines::section2()
    def self.section2()
        NxLines::items()
            .select{|item| OwnerMapping::elementuuidToOwnersuuidsCached(item["uuid"]).empty? }
            .sort{|l1, l2| l1["unixtime"] <=> l2["unixtime"] }
    end
end
