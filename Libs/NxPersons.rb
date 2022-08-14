
# encoding: UTF-8

class NxPersons

    # NxPersons::objectuuidToItemOrNull(objectuuid)
    def self.objectuuidToItemOrNull(objectuuid)
        return nil if Fx18Attributes::getJsonDecodeOrNull(objectuuid, "mikuType") != "NxPerson"
        {
            "uuid"        => objectuuid,
            "mikuType"    => Fx18Attributes::getJsonDecodeOrNull(objectuuid, "mikuType"),
            "unixtime"    => Fx18Attributes::getJsonDecodeOrNull(objectuuid, "unixtime"),
            "datetime"    => Fx18Attributes::getJsonDecodeOrNull(objectuuid, "datetime"),
            "name"        => Fx18Attributes::getJsonDecodeOrNull(objectuuid, "name")
        }
    end

    # NxPersons::items()
    def self.items()
        Fx256WithCache::mikuTypeToItems("NxPerson")
    end

    # NxPersons::issue(name1)
    def self.issue(name1)
        uuid = SecureRandom.uuidw
        Fx18Attributes::setJsonEncoded(uuid, "uuid",        uuid)
        Fx18Attributes::setJsonEncoded(uuid, "mikuType",    "NxPerson")
        Fx18Attributes::setJsonEncoded(uuid, "unixtime",    Time.new.to_i)
        Fx18Attributes::setJsonEncoded(uuid, "datetime",    Time.new.utc.iso8601)
        Fx18Attributes::setJsonEncoded(uuid, "name",        name1)
        FileSystemCheck::fsckObjectErrorAtFirstFailure(uuid)
        Fx256::broadcastObjectEvents(uuid)
        item = NxPersons::objectuuidToItemOrNull(uuid)
        if item.nil? then
            raise "(error: d7e99869-7566-40af-9349-558198695ddb) How did that happen ? 🤨"
        end
        item
    end

    # NxPersons::interactivelyIssueNewOrNull()
    def self.interactivelyIssueNewOrNull()
        name1 = LucilleCore::askQuestionAnswerAsString("(person) name (empty to abort): ")
        return nil if name1 == ""
        NxPersons::issue(name1)
    end

    # NxPersons::toString(item)
    def self.toString(item)
        "(person) #{item["name"]}"
    end
end
