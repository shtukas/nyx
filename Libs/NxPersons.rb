
# encoding: UTF-8

class NxPersons

    # NxPersons::items()
    def self.items()
        TheIndex::mikuTypeToItems("NxPerson")
    end

    # NxPersons::issue(name1)
    def self.issue(name1)
        uuid = SecureRandom.uuid
        DxF1::setAttribute2(uuid, "uuid",        uuid)
        DxF1::setAttribute2(uuid, "mikuType",    "NxPerson")
        DxF1::setAttribute2(uuid, "unixtime",    Time.new.to_i)
        DxF1::setAttribute2(uuid, "datetime",    Time.new.utc.iso8601)
        DxF1::setAttribute2(uuid, "name",        name1)
        FileSystemCheck::fsckObjectuuidErrorAtFirstFailure(uuid, SecureRandom.hex, true)
        item = TheIndex::getItemOrNull(uuid)
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
