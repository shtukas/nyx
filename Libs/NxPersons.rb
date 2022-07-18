
# encoding: UTF-8

class NxPersons

    # NxPersons::objectuuidToItemOrNull(objectuuid)
    def self.objectuuidToItemOrNull(objectuuid)
        return nil if !Fx18Utils::fileExists?(objectuuid)
        return nil if Fx18File::getAttributeOrNull(objectuuid, "mikuType") != "NxPerson"
        {
            "uuid"        => objectuuid,
            "mikuType"    => Fx18File::getAttributeOrNull(objectuuid, "mikuType"),
            "unixtime"    => Fx18File::getAttributeOrNull(objectuuid, "unixtime"),
            "datetime"    => Fx18File::getAttributeOrNull(objectuuid, "datetime"),
            "name"        => Fx18File::getAttributeOrNull(objectuuid, "name")
        }
    end

    # NxPersons::items()
    def self.items()
        Fx18Index1::mikuType2objectuuids("NxPerson")
            .map{|objectuuid| NxPersons::objectuuidToItemOrNull(objectuuid)}
            .compact
    end

    # NxPersons::issue(name1)
    def self.issue(name1)
        uuid = SecureRandom.uuid
        Fx18Utils::makeNewFile(uuid)
        Fx18File::setAttribute2(uuid, "uuid",        uuid)
        Fx18File::setAttribute2(uuid, "mikuType",    "NxPerson")
        Fx18File::setAttribute2(uuid, "unixtime",    Time.new.to_i)
        Fx18File::setAttribute2(uuid, "datetime",    Time.new.utc.iso8601)
        Fx18File::setAttribute2(uuid, "name",        name1)
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
