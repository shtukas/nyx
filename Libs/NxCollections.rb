
# encoding: UTF-8

class NxCollections

    # ----------------------------------------------------------------------
    # IO

    # NxCollections::items()
    def self.items()
        Fx256WithCache::mikuTypeToItems("NxCollection")
    end

    # NxCollections::destroy(uuid)
    def self.destroy(uuid)
        Fx256::deleteObjectLogically(uuid)
    end

    # ----------------------------------------------------------------------
    # Objects Makers

    # NxCollections::interactivelyIssueNewItemOrNull()
    def self.interactivelyIssueNewItemOrNull()
        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return nil if description == ""
        unixtime   = Time.new.to_i
        datetime   = Time.new.utc.iso8601
        uuid = SecureRandom.uuid
        Fx18Attributes::setJsonEncoded(uuid, "uuid",        uuid)
        Fx18Attributes::setJsonEncoded(uuid, "mikuType",    "NxCollection")
        Fx18Attributes::setJsonEncoded(uuid, "unixtime",    Time.new.to_i)
        Fx18Attributes::setJsonEncoded(uuid, "datetime",    datetime)
        Fx18Attributes::setJsonEncoded(uuid, "description", description)
        FileSystemCheck::fsckObjectuuidErrorAtFirstFailure(uuid)
        Fx256::broadcastObjectEvents(uuid)
        item = Fx256::getProtoItemOrNull(uuid)
        if item.nil? then
            raise "(error: 01666ee3-d5b4-4fd1-9615-981ac7949ae9) How did that happen ? 🤨"
        end
        item
    end

    # ----------------------------------------------------------------------
    # Data

    # NxCollections::toString(item)
    def self.toString(item)
        "(collection) #{item["description"]}"
    end
end
