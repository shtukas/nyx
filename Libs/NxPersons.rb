
# encoding: UTF-8

class NxPersons

    # NxPersons::objectuuidToItemOrNull(objectuuid)
    def self.objectuuidToItemOrNull(objectuuid)
        return nil if Fx18Attributes::getOrNull(objectuuid, "mikuType") != "NxPerson"
        {
            "uuid"        => objectuuid,
            "mikuType"    => Fx18Attributes::getOrNull(objectuuid, "mikuType"),
            "unixtime"    => Fx18Attributes::getOrNull(objectuuid, "unixtime"),
            "datetime"    => Fx18Attributes::getOrNull(objectuuid, "datetime"),
            "name"        => Fx18Attributes::getOrNull(objectuuid, "name")
        }
    end

    # NxPersons::items()
    def self.items()
        Fx18Index2PrimaryLookup::mikuType2objectuuids("NxPerson")
            .map{|objectuuid| Fx18Index2PrimaryLookup::itemOrNull(objectuuid)}
            .compact
    end

    # NxPersons::issue(name1)
    def self.issue(name1)
        uuid = SecureRandom.uuid
        Fx18Attributes::setAttribute2(uuid, "uuid",        uuid)
        Fx18Attributes::setAttribute2(uuid, "mikuType",    "NxPerson")
        Fx18Attributes::setAttribute2(uuid, "unixtime",    Time.new.to_i)
        Fx18Attributes::setAttribute2(uuid, "datetime",    Time.new.utc.iso8601)
        Fx18Attributes::setAttribute2(uuid, "name",        name1)
        FileSystemCheck::fsckObject(uuid)
        uuid
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
