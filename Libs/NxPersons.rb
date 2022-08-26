
# encoding: UTF-8

class NxPersons

    # NxPersons::items()
    def self.items()
        Fx256WithCache::mikuTypeToItems("NxPerson")
    end

    # NxPersons::issue(name1)
    def self.issue(name1)
        uuid = SecureRandom.uuid
        DxF1s::setJsonEncoded(uuid, "uuid",        uuid)
        DxF1s::setJsonEncoded(uuid, "mikuType",    "NxPerson")
        DxF1s::setJsonEncoded(uuid, "unixtime",    Time.new.to_i)
        DxF1s::setJsonEncoded(uuid, "datetime",    Time.new.utc.iso8601)
        DxF1s::setJsonEncoded(uuid, "name",        name1)
        FileSystemCheck::fsckObjectuuidErrorAtFirstFailure(uuid)
        Fx256::broadcastObject(uuid)
        item = Fx256::getProtoItemOrNull(uuid)
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
