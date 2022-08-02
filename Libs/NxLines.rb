
# encoding: UTF-8

class NxLines

    # ----------------------------------------------------------------------
    # IO

    # NxLines::objectuuidToItemOrNull(objectuuid)
    def self.objectuuidToItemOrNull(objectuuid)
        return nil if Fx18Attributes::getOrNull(objectuuid, "mikuType") != "NxLine"
        {
            "uuid"        => objectuuid,
            "mikuType"    => Fx18Attributes::getOrNull(objectuuid, "mikuType"),
            "unixtime"    => Fx18Attributes::getOrNull(objectuuid, "unixtime"),
            "datetime"    => Fx18Attributes::getOrNull(objectuuid, "datetime"),
            "line"        => Fx18Attributes::getOrNull(objectuuid, "line"),
        }
    end

    # NxLines::items()
    def self.items()
        Lookup1::mikuTypeToItems("NxLine")
    end

    # ----------------------------------------------------------------------
    # Makers

    # NxLines::issue(line)
    def self.issue(line)
        uuid = SecureRandom.uuid
        Fx18Attributes::set_objectMaking(uuid, "uuid",        uuid)
        Fx18Attributes::set_objectMaking(uuid, "mikuType",    "NxLine")
        Fx18Attributes::set_objectMaking(uuid, "unixtime",    Time.new.to_i)
        Fx18Attributes::set_objectMaking(uuid, "datetime",    Time.new.utc.iso8601)
        Fx18Attributes::set_objectMaking(uuid, "line",        line)
        FileSystemCheck::fsckObject(uuid)
        Lookup1::reconstructEntry(uuid)
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
            .select{|item| !TxThreads::uuidIsProjectElement(item["uuid"]) }
            .map{|item|
                {
                    "item" => item,
                    "toString" => NxLines::toString(item),
                    "metric"   => 0.8 + Catalyst::idToSmallShift(item["uuid"])
                }
            }
    end
end
